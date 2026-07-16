import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, TextInput, Alert, ActivityIndicator } from 'react-native';
import axios from 'axios';

export default function ResultScreen({ route, navigation }) {
  const { deviceInfo, tests } = route.params;
  const [serverIp, setServerIp] = useState('');
  const [loading, setLoading] = useState(false);

  // Calcula Aprovados / Reprovados / Não Testados
  const keys = Object.keys(tests);
  const aprovados = keys.filter(k => tests[k] === true).length;
  const reprovados = keys.filter(k => tests[k] === false).length;
  const pendentes = 11 - (aprovados + reprovados); // 11 testes totais

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
        navigation.navigate('Home'); // Volta ao início para um novo aparelho
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
        <View style={[styles.resultBox, { borderColor: '#00e676' }]}>
          <Text style={[styles.resultNumber, { color: '#00e676' }]}>{aprovados}</Text>
          <Text style={styles.resultLabel}>Aprovados</Text>
        </View>
        <View style={[styles.resultBox, { borderColor: '#ff5252' }]}>
          <Text style={[styles.resultNumber, { color: '#ff5252' }]}>{reprovados}</Text>
          <Text style={styles.resultLabel}>Reprovados</Text>
        </View>
        <View style={[styles.resultBox, { borderColor: '#aaaaaa' }]}>
          <Text style={[styles.resultNumber, { color: '#aaaaaa' }]}>{pendentes}</Text>
          <Text style={styles.resultLabel}>Não Testados</Text>
        </View>
      </View>

      <View style={styles.serverSection}>
        <Text style={styles.label}>IP do Servidor no PC:</Text>
        <TextInput 
          style={styles.input}
          placeholder="Ex: 192.168.1.100"
          placeholderTextColor="#777"
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
          <Text style={styles.sendButtonText}>Gerar Relatório PDF</Text>
        )}
      </TouchableOpacity>
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
    color: '#fff',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 15,
    marginTop: 10,
  },
  card: {
    backgroundColor: '#1e1e1e',
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
  },
  cardText: {
    color: '#ccc',
    fontSize: 16,
    marginBottom: 5,
  },
  highlight: {
    color: '#fff',
    fontWeight: 'bold',
  },
  resultsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 30,
  },
  resultBox: {
    flex: 1,
    backgroundColor: '#1e1e1e',
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 5,
    borderWidth: 1,
  },
  resultNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  resultLabel: {
    color: '#ccc',
    fontSize: 12,
  },
  serverSection: {
    marginTop: 10,
  },
  label: {
    color: '#fff',
    fontSize: 16,
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#2c2c2c',
    color: '#fff',
    padding: 15,
    borderRadius: 8,
    fontSize: 16,
    marginBottom: 5,
  },
  hint: {
    color: '#888',
    fontSize: 12,
    marginBottom: 20,
  },
  sendButton: {
    backgroundColor: '#00e676',
    padding: 18,
    borderRadius: 8,
    alignItems: 'center',
  },
  sendButtonText: {
    color: '#000',
    fontSize: 18,
    fontWeight: 'bold',
  }
});
