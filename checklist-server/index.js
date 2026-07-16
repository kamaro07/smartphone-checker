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

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

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

function monitorUSB() {
  exec('adb devices', (err, stdout, stderr) => {
    if (err) return; // Ignora erros se adb não estiver instalado

    const lines = stdout.split('\n');
    lines.shift(); // Remove a primeira linha 'List of devices attached'

    lines.forEach(line => {
      const parts = line.trim().split('\t');
      if (parts.length === 2 && parts[1] === 'device') {
        const deviceId = parts[0];
        
        // Se já conhecemos, pula
        if (connectedDevices[deviceId]) return;

        // Adiciona dispositivo
        connectedDevices[deviceId] = {
          id: deviceId,
          model: 'Obtendo...',
          os: 'Android',
          connectionType: 'USB',
          status: 'Detectado'
        };

        // Obter modelo
        exec(`adb -s ${deviceId} shell getprop ro.product.model`, (errMod, stdoutMod) => {
          if (!errMod && connectedDevices[deviceId]) {
            connectedDevices[deviceId].model = stdoutMod.trim();
          }
        });

        // Verificar se App está instalado
        const packageName = 'com.outlet.checklist'; // Substitua pelo package.json do Expo
        exec(`adb -s ${deviceId} shell pm list packages | findstr ${packageName}`, (errPkg, stdoutPkg) => {
          if (stdoutPkg.includes(packageName)) {
            if(connectedDevices[deviceId]) connectedDevices[deviceId].status = 'App Instalado';
            // Abre o app
            exec(`adb -s ${deviceId} shell monkey -p ${packageName} -c android.intent.category.LAUNCHER 1`);
          } else {
            // Instala o app
            if(connectedDevices[deviceId]) connectedDevices[deviceId].status = 'Instalando...';
            const apkPath = path.join(__dirname, 'public', 'app-release.apk');
            exec(`adb -s ${deviceId} install -r "${apkPath}"`, (errInst) => {
              if (!errInst && connectedDevices[deviceId]) {
                connectedDevices[deviceId].status = 'App Instalado';
                exec(`adb -s ${deviceId} shell monkey -p ${packageName} -c android.intent.category.LAUNCHER 1`);
              }
            });
          }
        });
      }
    });
  });
}

// Roda o monitor a cada 5 segundos
setInterval(monitorUSB, 5000);


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

app.listen(PORT, '0.0.0.0', () => {
  console.log('========================================');
  console.log(`DESKTOP CONTROLLER INICIADO`);
  console.log(`Abra no navegador do seu PC: http://localhost:${PORT}/dashboard.html`);
  console.log(`IP Local da Rede para o App: ${ipAddress}`);
  console.log('========================================');
});
