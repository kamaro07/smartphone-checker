import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, ScrollView, TouchableOpacity, Alert } from 'react-native';
import * as Haptics from 'expo-haptics';
import { LightSensor } from 'expo-sensors';
import { Audio } from 'expo-av';

// Helper component for Yes/No Tests
const TestItem = ({ title, status, onApprove, onReject, onRunTest, isInteractive }) => (
  <View style={styles.testCard}>
    <Text style={styles.testTitle}>{title}</Text>
    
    {isInteractive && (
      <TouchableOpacity style={styles.runButton} onPress={onRunTest}>
        <Text style={styles.runButtonText}>Executar Teste</Text>
      </TouchableOpacity>
    )}

    <View style={styles.actionRow}>
      <TouchableOpacity 
        style={[styles.btnAction, styles.btnReject, status === false && styles.btnRejectActive]} 
        onPress={onReject}
      >
        <Text style={[styles.btnActionText, status === false && styles.btnActiveText]}>Reprovar</Text>
      </TouchableOpacity>
      <TouchableOpacity 
        style={[styles.btnAction, styles.btnApprove, status === true && styles.btnApproveActive]} 
        onPress={onApprove}
      >
        <Text style={[styles.btnActionText, status === true && styles.btnActiveText]}>Aprovar</Text>
      </TouchableOpacity>
    </View>
  </View>
);

export default function TestScreen({ route, navigation }) {
  const { deviceInfo } = route.params;
  const [results, setResults] = useState({});
  const [sound, setSound] = useState();

  const testVibration = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    Alert.alert('Teste de Vibração', 'O aparelho vibrou?');
  };

  const testSound = async () => {
    try {
      const { sound } = await Audio.Sound.createAsync(
        require('../assets/favicon.png'), 
      );
      setSound(sound);
      await sound.playAsync();
    } catch (error) {
      Alert.alert('Teste de Som', 'Reproduzindo som de teste... O som saiu alto e claro?');
    }
  };

  const testBrightness = () => {
    Alert.alert('Teste de Brilho', 'Aumente e diminua o brilho do aparelho na barra de notificações para verificar o funcionamento.');
  };

  const updateResult = (key, value) => {
    setResults(prev => ({ ...prev, [key]: value }));
  };

  const allTests = [
    { key: 'tela', title: 'Tela e Touch (Visual/Toque)' },
    { key: 'vibracao', title: 'Vibração', interactive: testVibration },
    { key: 'sensorProximidade', title: 'Sensor de Proximidade / Luz' },
    { key: 'som', title: 'Som / Campainha / Earpiece', interactive: testSound },
    { key: 'brilho', title: 'Controle de Brilho', interactive: testBrightness },
    { key: 'cameraFrontal', title: 'Câmera Frontal' },
    { key: 'cameraTraseira', title: 'Câmera Traseira' },
    { key: 'wifi', title: 'Conectividade Wi-Fi' },
    { key: 'chip', title: 'Leitura de Chip (SIM)' },
    { key: 'usb', title: 'Conector USB / Carregamento' },
    { key: 'estetica', title: 'Estética / Carcaça' },
  ];

  const finishTests = () => {
    navigation.navigate('Result', { deviceInfo, tests: results });
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Execução de Testes</Text>
        <Text style={styles.subTitle}>{deviceInfo.brand} {deviceInfo.model}</Text>
      </View>

      {allTests.map(test => (
        <TestItem 
          key={test.key}
          title={test.title}
          status={results[test.key]}
          onApprove={() => updateResult(test.key, true)}
          onReject={() => updateResult(test.key, false)}
          onRunTest={test.interactive}
          isInteractive={!!test.interactive}
        />
      ))}

      <TouchableOpacity style={styles.finishButton} onPress={finishTests}>
        <Text style={styles.finishButtonText}>Finalizar e Ver Resultados</Text>
      </TouchableOpacity>
      <View style={{height: 50}} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
    padding: 15,
  },
  header: {
    backgroundColor: '#ffffff',
    padding: 15,
    borderRadius: 12,
    marginBottom: 20,
    borderBottomWidth: 4,
    borderBottomColor: '#d32f2f',
    elevation: 2,
  },
  headerTitle: {
    color: '#d32f2f',
    fontSize: 22,
    fontWeight: '900',
    textAlign: 'center',
    textTransform: 'uppercase',
  },
  subTitle: {
    color: '#333',
    fontSize: 16,
    textAlign: 'center',
    fontWeight: '600',
    marginTop: 5,
  },
  testCard: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 15,
    marginBottom: 15,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  testTitle: {
    color: '#333',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  runButton: {
    backgroundColor: '#f0f0f0',
    padding: 10,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  runButtonText: {
    color: '#d32f2f',
    fontWeight: 'bold',
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  btnAction: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 5,
    backgroundColor: '#ffffff',
  },
  btnReject: {
    borderWidth: 2,
    borderColor: '#ff5252',
  },
  btnRejectActive: {
    backgroundColor: '#ff5252',
  },
  btnApprove: {
    borderWidth: 2,
    borderColor: '#00c853',
  },
  btnApproveActive: {
    backgroundColor: '#00c853',
  },
  btnActionText: {
    color: '#666',
    fontWeight: 'bold',
  },
  btnActiveText: {
    color: '#ffffff',
  },
  finishButton: {
    backgroundColor: '#d32f2f',
    padding: 18,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 40,
    elevation: 3,
  },
  finishButtonText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: 'bold',
    letterSpacing: 1,
  }
});
