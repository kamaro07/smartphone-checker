const express = require('express');
const cors = require('cors');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Helper function to get local IP address
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip internal and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

// Rota para receber os resultados do aplicativo
app.post('/api/report', (req, res) => {
  const { device, tests, date } = req.body;
  
  if (!device || !tests) {
    return res.status(400).json({ error: 'Dados incompletos recebidos.' });
  }

  // Create the reports directory if it doesn't exist
  const reportsDir = path.join(__dirname, 'reports');
  if (!fs.existsSync(reportsDir)){
      fs.mkdirSync(reportsDir);
  }

  // Generate filename based on IMEI or model + timestamp
  const safeImei = device.imei ? device.imei.replace(/[^a-z0-9]/gi, '_') : 'UNKNOWN_IMEI';
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `Report_${safeImei}_${timestamp}.pdf`;
  const filePath = path.join(reportsDir, filename);

  try {
    const doc = new PDFDocument({ margin: 50 });
    const writeStream = fs.createWriteStream(filePath);
    doc.pipe(writeStream);

    // Cabecalho
    doc.fontSize(20).text('Checklist de Smartphone - Relatório', { align: 'center' });
    doc.moveDown();
    
    // Data
    doc.fontSize(12).text(`Data: ${new Date(date).toLocaleString('pt-BR')}`);
    doc.moveDown();

    // Device Info
    doc.fontSize(16).text('Informações do Aparelho', { underline: true });
    doc.fontSize(12)
       .text(`IMEI: ${device.imei || 'Não informado'}`)
       .text(`Marca: ${device.brand || 'Desconhecida'}`)
       .text(`Modelo: ${device.model || 'Desconhecido'}`);
    doc.moveDown();

    // Test Results
    doc.fontSize(16).text('Resultados dos Testes', { underline: true });
    doc.moveDown();

    // Tests List
    const testNames = {
      tela: 'Tela e Touch',
      vibracao: 'Vibração',
      sensorProximidade: 'Sensor de Proximidade',
      som: 'Som / Campainha (Speaker)',
      brilho: 'Brilho da Tela',
      cameraFrontal: 'Câmera Frontal',
      cameraTraseira: 'Câmera Traseira',
      wifi: 'Wi-Fi / Conectividade',
      chip: 'Leitura de Chip (SIM)',
      usb: 'Conector USB / Bateria',
      estetica: 'Estética / Carcaça'
    };

    let passedCount = 0;
    let failedCount = 0;

    Object.keys(testNames).forEach(testKey => {
      const result = tests[testKey];
      let resultText = 'Não Testado';
      let color = 'gray';

      if (result === true) {
        resultText = 'APROVADO';
        color = 'green';
        passedCount++;
      } else if (result === false) {
        resultText = 'REPROVADO';
        color = 'red';
        failedCount++;
      }

      doc.fontSize(12).fillColor('black').text(`${testNames[testKey]}: `, { continued: true })
         .fillColor(color).text(resultText);
    });

    doc.moveDown();
    
    // Resumo
    doc.fillColor('black').fontSize(14).text(`Resumo: ${passedCount} Aprovados, ${failedCount} Reprovados`);

    // Finalize PDF
    doc.end();

    writeStream.on('finish', () => {
      console.log(`Relatório salvo em: ${filePath}`);
      res.status(200).json({ success: true, message: 'Relatório salvo com sucesso!', path: filePath });
    });

  } catch (error) {
    console.error('Erro ao gerar PDF:', error);
    res.status(500).json({ error: 'Falha ao gerar o PDF' });
  }
});

const ipAddress = getLocalIp();

app.listen(PORT, '0.0.0.0', () => {
  console.log('========================================');
  console.log(`Servidor de Checklist iniciado na porta ${PORT}`);
  console.log(`Acesse no App usando o IP: http://${ipAddress}:${PORT}`);
  console.log('========================================');
});
