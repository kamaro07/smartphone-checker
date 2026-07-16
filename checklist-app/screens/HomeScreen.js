import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Button, Alert } from 'react-native';
import { Camera, CameraView } from 'expo-camera';
import * as Device from 'expo-device';

export default function HomeScreen({ navigation }) {
  const [hasPermission, setHasPermission] = useState(null);
  const [scanned, setScanned] = useState(false);
  const [imei, setImei] = useState('');
  const [showCamera, setShowCamera] = useState(false);

  useEffect(() => {
    const getBarCodeScannerPermissions = async () => {
      const { status } = await Camera.requestCameraPermissionsAsync();
      setHasPermission(status === 'granted');
    };

    getBarCodeScannerPermissions();
  }, []);

  const handleBarCodeScanned = ({ type, data }) => {
    setScanned(true);
    setImei(data);
    setShowCamera(false);
    Alert.alert('Código Escaneado!', `IMEI/Serial: ${data}`);
  };

  const startTests = () => {
    if (!imei.trim()) {
      Alert.alert('Atenção', 'Por favor, escaneie ou digite o IMEI/Serial antes de continuar.');
      return;
    }
    const deviceInfo = {
      imei: imei,
      brand: Device.brand || 'Desconhecida',
      model: Device.modelName || 'Desconhecido',
      os: Device.osName || 'Android',
      osVersion: Device.osVersion || ''
    };
    navigation.navigate('Test', { deviceInfo });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Identificação do Aparelho</Text>
      
      <View style={styles.infoCard}>
        <Text style={styles.infoText}>Marca detectada: {Device.brand || 'N/A'}</Text>
        <Text style={styles.infoText}>Modelo detectado: {Device.modelName || 'N/A'}</Text>
      </View>

      <Text style={styles.label}>IMEI / Serial Number:</Text>
      <TextInput
        style={styles.input}
        placeholder="Digite ou escaneie o IMEI"
        value={imei}
        onChangeText={setImei}
        keyboardType="default"
      />

      {!showCamera ? (
        <TouchableOpacity style={styles.scanButton} onPress={() => { setScanned(false); setShowCamera(true); }}>
          <Text style={styles.buttonText}>📷 Escanear Código de Barras (IMEI)</Text>
        </TouchableOpacity>
      ) : (
        <View style={styles.cameraContainer}>
          {hasPermission === null ? (
            <Text>Solicitando permissão de câmera...</Text>
          ) : hasPermission === false ? (
            <Text>Sem acesso à câmera</Text>
          ) : (
            <CameraView
              onBarcodeScanned={scanned ? undefined : handleBarCodeScanned}
              style={StyleSheet.absoluteFillObject}
            />
          )}
          <Button title="Cancelar Escaneamento" onPress={() => setShowCamera(false)} color="red" />
        </View>
      )}

      {!showCamera && (
        <TouchableOpacity style={styles.startButton} onPress={startTests}>
          <Text style={styles.startButtonText}>Iniciar Testes ➔</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 20,
    textAlign: 'center',
  },
  infoCard: {
    backgroundColor: '#1e1e1e',
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#00e676',
  },
  infoText: {
    color: '#aaaaaa',
    fontSize: 16,
    marginBottom: 5,
  },
  label: {
    color: '#ffffff',
    fontSize: 16,
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#2c2c2c',
    color: '#ffffff',
    padding: 15,
    borderRadius: 8,
    fontSize: 18,
    marginBottom: 15,
  },
  scanButton: {
    backgroundColor: '#333333',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 30,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  startButton: {
    backgroundColor: '#2979ff',
    padding: 18,
    borderRadius: 8,
    alignItems: 'center',
  },
  startButtonText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: 'bold',
  },
  cameraContainer: {
    height: 300,
    width: '100%',
    overflow: 'hidden',
    borderRadius: 8,
    marginBottom: 20,
  }
});
