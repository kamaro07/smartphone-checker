import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, TextInput, Alert, ActivityIndicator } from 'react-native';
import axios from 'axios';

export default function ResultScreen({ route, navigation }) {
  const { deviceInfo, tests } = route.params;
  const [serverIp, setServerIp] = useState('');
  const [loading, setLoading] = useState(false);

  const keys = Object.keys(tests);
  const aprovados = keys.filter(k => tests[k] === true).length;
  const reprovados = keys.filter(k => tests[k] === false).length;
  const pendentes = 11 - (aprovados + reprovados);

  const sendReport = async () => {
    if (!serverIp.trim()) {
      Alert.alert('Erro', 'Por favor, digite o IP do servidor (PC).');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        device: deviceInfo,
        tests: tests,
        date: new Date().toISOString()
      };

      const response = await axios.post(`http://${serverIp}:3000/api/report`, payload, {
        timeout: 10000
      });

      if (response.data.success) {
        Alert.alert('Sucesso!', 'Relatório PDF gerado e salvo no PC com sucesso!');
        navigation.navigate('Home');
      }
    } catch (error) {
      console.error(error);
      Alert.alert('Erro de Conexão', 'Não foi possível conectar ao servidor. Verifique o IP e se o servidor Node.js está rodando no PC.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Resumo do Aparelho</Text>
      
      <View style={styles.card}>
        <Text style={styles.cardText}>IMEI: <Text style={styles.highlight}>{deviceInfo.imei}</Text></Text>
        <Text style={styles.cardText}>Modelo: <Text style={styles.highlight}>{deviceInfo.brand} {deviceInfo.model}</Text></Text>
      </View>

      <Text style={styles.title}>Resultados</Text>
      <View style={styles.resultsContainer}>
        <View style={[styles.resultBox, { borderColor: '#00c853', backgroundColor: '#e8f5e9' }]}>
          <Text style={[styles.resultNumber, { color: '#00c853' }]}>{aprovados}</Text>
          <Text style={[styles.resultLabel, { color: '#00c853' }]}>Aprovados</Text>
        </View>
        <View style={[styles.resultBox, { borderColor: '#ff5252', backgroundColor: '#ffebee' }]}>
          <Text style={[styles.resultNumber, { color: '#ff5252' }]}>{reprovados}</Text>
          <Text style={[styles.resultLabel, { color: '#ff5252' }]}>Reprovados</Text>
        </View>
        <View style={[styles.resultBox, { borderColor: '#9e9e9e', backgroundColor: '#f5f5f5' }]}>
          <Text style={[styles.resultNumber, { color: '#9e9e9e' }]}>{pendentes}</Text>
          <Text style={[styles.resultLabel, { color: '#9e9e9e' }]}>Não Testados</Text>
        </View>
      </View>

      <View style={styles.serverSection}>
        <Text style={styles.label}>IP do Servidor no PC:</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ex: 192.168.1.100"
          placeholderTextColor="#999"
          value={serverIp}
          onChangeText={setServerIp}
          keyboardType="numeric"
        />
        <Text style={styles.hint}>O celular e o PC devem estar no mesmo Wi-Fi.</Text>
      </View>

      <TouchableOpacity 
        style={[styles.sendButton, loading && { opacity: 0.7 }]} 
        onPress={sendReport}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.sendButtonText}>GERAR RELATÓRIO PDF</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
    padding: 20,
  },
  title: {
    color: '#d32f2f',
    fontSize: 20,
    fontWeight: '900',
    marginBottom: 15,
    marginTop: 10,
    textTransform: 'uppercase',
  },
  card: {
    backgroundColor: '#ffffff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  cardText: {
    color: '#555',
    fontSize: 16,
    marginBottom: 8,
  },
  highlight: {
    color: '#333',
    fontWeight: 'bold',
  },
  resultsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 30,
  },
  resultBox: {
    flex: 1,
    padding: 15,
    borderRadius: 12,
    alignItems: 'center',
    marginHorizontal: 4,
    borderWidth: 1.5,
  },
  resultNumber: {
    fontSize: 28,
    fontWeight: '900',
    marginBottom: 5,
  },
  resultLabel: {
    fontSize: 12,
    fontWeight: 'bold',
    textTransform: 'uppercase',
  },
  serverSection: {
    marginTop: 10,
    backgroundColor: '#ffffff',
    padding: 20,
    borderRadius: 12,
    elevation: 2,
    marginBottom: 30,
  },
  label: {
    color: '#333',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f8f9fa',
    color: '#333',
    padding: 15,
    borderRadius: 8,
    fontSize: 16,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  hint: {
    color: '#777',
    fontSize: 12,
    fontStyle: 'italic',
  },
  sendButton: {
    backgroundColor: '#d32f2f',
    padding: 18,
    borderRadius: 10,
    alignItems: 'center',
    elevation: 3,
  },
  sendButtonText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: 'bold',
    letterSpacing: 1,
  }
});
