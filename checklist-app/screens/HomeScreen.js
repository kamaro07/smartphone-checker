import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Button, Alert, Image } from 'react-native';
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
      {/* Espaço para a Logo no App */}
      <View style={styles.logoContainer}>
        <Text style={styles.logoTitle}>OUTLET<Text style={styles.logoSubtitle}> DO CELULAR</Text></Text>
        <Text style={styles.appSubtitle}>Checklist Triage App</Text>
      </View>
      
      <View style={styles.infoCard}>
        <Text style={styles.infoTitle}>Aparelho Detectado</Text>
        <Text style={styles.infoText}>Marca: {Device.brand || 'N/A'}</Text>
        <Text style={styles.infoText}>Modelo: {Device.modelName || 'N/A'}</Text>
      </View>

      <Text style={styles.label}>IMEI / Serial Number:</Text>
      <TextInput
        style={styles.input}
        placeholder="Digite ou escaneie o IMEI"
        placeholderTextColor="#999"
        value={imei}
        onChangeText={setImei}
        keyboardType="default"
      />

      {!showCamera ? (
        <TouchableOpacity style={styles.scanButton} onPress={() => { setScanned(false); setShowCamera(true); }}>
          <Text style={styles.scanButtonText}>📷 Escanear Código de Barras</Text>
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
          <Button title="Cancelar Escaneamento" onPress={() => setShowCamera(false)} color="#d32f2f" />
        </View>
      )}

      {!showCamera && (
        <TouchableOpacity style={styles.startButton} onPress={startTests}>
          <Text style={styles.startButtonText}>INICIAR TESTES</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
    padding: 20,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 30,
    marginTop: 10,
  },
  logoTitle: {
    fontSize: 32,
    fontWeight: '900',
    color: '#d32f2f', // Vermelho Outlet
    letterSpacing: -1,
  },
  logoSubtitle: {
    fontSize: 22,
    fontWeight: '600',
    color: '#d32f2f',
  },
  appSubtitle: {
    fontSize: 14,
    color: '#666',
    marginTop: 5,
    textTransform: 'uppercase',
    letterSpacing: 2,
  },
  infoCard: {
    backgroundColor: '#ffffff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 25,
    borderLeftWidth: 5,
    borderLeftColor: '#d32f2f',
    elevation: 3, // sombra no android
    shadowColor: '#000', // sombra no ios
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  infoTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 10,
  },
  infoText: {
    color: '#555',
    fontSize: 16,
    marginBottom: 5,
  },
  label: {
    color: '#333',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#ffffff',
    color: '#333',
    padding: 15,
    borderRadius: 10,
    fontSize: 18,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  scanButton: {
    backgroundColor: '#ffffff',
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 30,
    borderWidth: 1,
    borderColor: '#d32f2f',
  },
  scanButtonText: {
    color: '#d32f2f',
    fontSize: 16,
    fontWeight: 'bold',
  },
  startButton: {
    backgroundColor: '#d32f2f', // Vermelho Outlet
    padding: 18,
    borderRadius: 10,
    alignItems: 'center',
    elevation: 3,
  },
  startButtonText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  cameraContainer: {
    height: 300,
    width: '100%',
    overflow: 'hidden',
    borderRadius: 10,
    marginBottom: 20,
  }
});
