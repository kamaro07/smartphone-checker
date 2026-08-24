const express = require('express');
const cors = require('cors');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const os = require('os');
const QRCode = require('qrcode');
const { exec } = require('child_process');

const app = express();
const PORT = 3000;

// Path to the downloaded ADB binary
const adbPath = path.join(__dirname, 'platform-tools', 'adb.exe');

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const multer = require('multer');
const uploadDir = path.join(__dirname, 'reports');
if (!fs.existsSync(uploadDir)){
    fs.mkdirSync(uploadDir);
}
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir)
  },
  filename: function (req, file, cb) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    cb(null, timestamp + '_' + file.originalname)
  }
});
const upload = multer({ storage: storage });

app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).send('No file uploaded.');
  }
  console.log(`[Upload] PDF Recebido e salvo em: ${req.file.path}`);
  res.status(200).json({ success: true, message: 'PDF recebido e salvo!', path: req.file.path });
});

// Estado global dos dispositivos detectados
let connectedDevices = {};

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

const ipAddress = getLocalIp();

// ==========================================
// 1. ROTAS DE ONBOARDING E QR CODE
// ==========================================

app.get('/api/qrcode', async (req, res) => {
  try {
    const downloadUrl = `http://${ipAddress}:${PORT}/download`;
    const qrCodeDataUrl = await QRCode.toDataURL(downloadUrl, { width: 300, color: { dark: '#d32f2f', light: '#ffffff' } });
    res.json({ qrCodeUrl: qrCodeDataUrl });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao gerar QR Code' });
  }
});

app.get('/download', (req, res) => {
  const userAgent = req.headers['user-agent'] || '';
  
  if (/iPad|iPhone|iPod/.test(userAgent)) {
    // Para iOS: Redireciona para o TestFlight
    res.redirect('https://testflight.apple.com/join/SEU_LINK_AQUI');
  } else if (/Android/.test(userAgent)) {
    // Para Android: Envia o APK localmente
    const apkPath = path.join(__dirname, 'public', 'app-release.apk');
    if (fs.existsSync(apkPath)) {
      res.download(apkPath, 'ChecklistApp.apk');
    } else {
      res.status(404).send('APK não encontrado no servidor. Compile o App e coloque em public/app-release.apk');
    }
  } else {
    res.send('Acesse este link pelo celular para baixar o App.');
  }
});

// ==========================================
// 2. AUTO-DISCOVERY (WIFI PING)
// ==========================================

app.post('/api/ping', (req, res) => {
  const { deviceId, brand, model, os, osVersion } = req.body;
  
  if (deviceId) {
    connectedDevices[deviceId] = {
      id: deviceId,
      model: `${brand} ${model}`,
      os: os,
      osVersion: osVersion,
      connectionType: 'Wi-Fi',
      status: 'Pronto (Ping Wi-Fi)',
      lastPing: Date.now()
    };
  }
  res.json({ success: true });
});

app.get('/api/devices', (req, res) => {
  // Limpar devices inativos (ping muito antigo)
  const now = Date.now();
  for (const id in connectedDevices) {
    if (connectedDevices[id].connectionType === 'Wi-Fi' && now - connectedDevices[id].lastPing > 15000) {
      delete connectedDevices[id]; // Remove se não pingar em 15s
    }
  }
  res.json({ devices: connectedDevices });
});

// ==========================================
// 3. MONITORAMENTO USB (ADB)
// ==========================================

setInterval(() => {
  exec(`"${adbPath}" devices`, (err, stdout, stderr) => {
    if (err) {
      console.log('Erro ao rodar ADB:', err.message);
      return; 
    }
    
    const lines = stdout.split('\n');
    lines.forEach(line => {
      if (line.includes('device') && !line.includes('List')) {
        const deviceId = line.split('\t')[0].trim();
        
        if (!connectedDevices[deviceId]) {
          console.log(`[USB] Novo dispositivo conectado: ${deviceId}`);
          connectedDevices[deviceId] = { status: 'installing' };
          
          exec(`"${adbPath}" -s ${deviceId} shell getprop ro.product.model`, (errMod, stdoutMod) => {
            const model = stdoutMod ? stdoutMod.trim() : 'Desconhecido';
            console.log(`[USB] Modelo detectado: ${model}`);
            
            const packageName = 'com.out014.checklistapp';
            exec(`"${adbPath}" -s ${deviceId} shell pm list packages | findstr ${packageName}`, (errPkg, stdoutPkg) => {
              if (stdoutPkg && stdoutPkg.includes(packageName)) {
                console.log(`[USB] App já instalado. Abrindo app...`);
                exec(`"${adbPath}" -s ${deviceId} shell monkey -p ${packageName} -c android.intent.category.LAUNCHER 1`);
                connectedDevices[deviceId].status = 'ready';
              } else {
                console.log(`[USB] Instalando App no dispositivo ${model}...`);
                const apkPath = path.join(__dirname, 'public', 'app-release.apk');
                
                if (fs.existsSync(apkPath)) {
                  exec(`"${adbPath}" -s ${deviceId} install -r "${apkPath}"`, (errInst) => {
                    if (!errInst) {
                      console.log(`[USB] Instalação concluída! Abrindo app...`);
                      exec(`"${adbPath}" -s ${deviceId} shell monkey -p ${packageName} -c android.intent.category.LAUNCHER 1`);
                      connectedDevices[deviceId].status = 'ready';
                    } else {
                      console.log(`[USB] Erro na instalação: ${errInst.message}`);
                    }
                  });
                } else {
                  console.log('[USB] Erro: APK não encontrado em public/app-release.apk');
                }
              }
            });
          });
        }
      }
    });
  });
}, 5000);

// ==========================================
// 4. ROTA DE RELATÓRIO PDF (MANTEVE-SE IGUAL)
// ==========================================
app.post('/api/report', (req, res) => {
  const { device, tests, date } = req.body;
  
  if (!device || !tests) {
    return res.status(400).json({ error: 'Dados incompletos recebidos.' });
  }

  const reportsDir = path.join(__dirname, 'reports');
  if (!fs.existsSync(reportsDir)){
      fs.mkdirSync(reportsDir);
  }

  const safeImei = device.imei ? device.imei.replace(/[^a-z0-9]/gi, '_') : 'UNKNOWN_IMEI';
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `Report_${safeImei}_${timestamp}.pdf`;
  const filePath = path.join(reportsDir, filename);

  try {
    const doc = new PDFDocument({ margin: 50 });
    const writeStream = fs.createWriteStream(filePath);
    doc.pipe(writeStream);

    doc.fontSize(20).fillColor('#d32f2f').text('OUTLET DO CELULAR', { align: 'center' });
    doc.fontSize(14).fillColor('#333').text('Relatório de Triagem', { align: 'center' });
    doc.moveDown();
    
    doc.fontSize(12).text(`Data: ${new Date(date).toLocaleString('pt-BR')}`);
    doc.moveDown();

    doc.fontSize(16).text('Informações do Aparelho', { underline: true });
    doc.fontSize(12)
       .text(`IMEI: ${device.imei || 'Não informado'}`)
       .text(`Marca: ${device.brand || 'Desconhecida'}`)
       .text(`Modelo: ${device.model || 'Desconhecido'}`);
    doc.moveDown();

    doc.fontSize(16).text('Resultados dos Testes', { underline: true });
    doc.moveDown();

    const testNames = {
      tela: 'Tela e Touch', vibracao: 'Vibração', sensorProximidade: 'Sensor de Proximidade',
      som: 'Som / Campainha (Speaker)', brilho: 'Brilho da Tela', cameraFrontal: 'Câmera Frontal',
      cameraTraseira: 'Câmera Traseira', wifi: 'Wi-Fi / Conectividade', chip: 'Leitura de Chip (SIM)',
      usb: 'Conector USB / Bateria', estetica: 'Estética / Carcaça'
    };

    let passedCount = 0; let failedCount = 0;

    Object.keys(testNames).forEach(testKey => {
      const result = tests[testKey];
      let resultText = 'Não Testado'; let color = 'gray';

      if (result === true) {
        resultText = 'APROVADO'; color = 'green'; passedCount++;
      } else if (result === false) {
        resultText = 'REPROVADO'; color = 'red'; failedCount++;
      }
      doc.fontSize(12).fillColor('black').text(`${testNames[testKey]}: `, { continued: true })
         .fillColor(color).text(resultText);
    });

    doc.moveDown();
    doc.fillColor('black').fontSize(14).text(`Resumo: ${passedCount} Aprovados, ${failedCount} Reprovados`);
    doc.end();

    writeStream.on('finish', () => {
      res.status(200).json({ success: true, message: 'Relatório salvo com sucesso!', path: filePath });
    });

  } catch (error) {
    res.status(500).json({ error: 'Falha ao gerar o PDF' });
  }
});

app.get('/api/adb_info', (req, res) => {
  const target = req.query.deviceId ? `-s ${req.query.deviceId}` : '';

  exec(`"${adbPath}" ${target} shell df -h /data`, (err, stdout) => {
    let capacity = 'Desconhecida';
    if (!err && stdout) {
      const lines = stdout.split('\n');
      if (lines.length > 1) {
        const parts = lines[1].trim().split(/\s+/);
        if (parts.length >= 2) capacity = parts[1];
      }
    }
    
    exec(`"${adbPath}" ${target} shell dumpsys iphonesubinfo`, (errDump, stdoutDump) => {
      let imei1 = '', imei2 = '';
      if (!errDump && stdoutDump) {
        const lines = stdoutDump.split('\n');
        let currentImei = '';
        for (let line of lines) {
          if (line.toLowerCase().includes('device id') || line.toLowerCase().includes('imei')) {
            const val = line.split('=')[1] || line.split(':')[1];
            if (val) {
               const digits = val.replace(/[^0-9]/g, '');
               if (digits.length >= 14) {
                 if (!imei1) imei1 = digits;
                 else if (imei1 !== digits && !imei2) imei2 = digits;
               }
            }
          }
        }
      }
      
      // Fallback para service call se dumpsys falhar
      if (!imei1) {
         exec(`"${adbPath}" ${target} shell service call iphonesubinfo 1`, (errCall1, stdoutCall1) => {
            if (stdoutCall1) {
               const digits = stdoutCall1.replace(/[^0-9]/g, '');
               if (digits.length >= 14) imei1 = digits.substring(0, 15);
            }
            exec(`"${adbPath}" ${target} shell service call iphonesubinfo 3`, (errCall2, stdoutCall2) => {
               if (stdoutCall2) {
                  const digits2 = stdoutCall2.replace(/[^0-9]/g, '');
                  if (digits2.length >= 14 && digits2.substring(0, 15) !== imei1) imei2 = digits2.substring(0, 15);
               }
               res.json({ success: true, capacity, imei1, imei2 });
            });
         });
      } else {
         res.json({ success: true, capacity, imei1, imei2 });
      }
    });
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('========================================');
  console.log(`DESKTOP CONTROLLER INICIADO`);
  console.log(`Abra no navegador do seu PC: http://localhost:${PORT}/dashboard.html`);
  console.log(`IP Local da Rede para o App: ${ipAddress}`);
  console.log('========================================');
});
