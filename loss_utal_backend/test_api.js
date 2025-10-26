// Script de prueba para los endpoints del backend
const testRegister = async () => {
  console.log('=== Probando Registro ===');
  try {
    const response = await fetch('http://localhost:5000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Usuario',
        lastName: 'Prueba',
        rut: '12345678-9',
        email: 'test@utalca.cl',
        password: 'password123'
      })
    });
    const data = await response.json();
    console.log('Respuesta:', response.status, data);
  } catch (error) {
    console.error('Error:', error.message);
  }
};

const testLogin = async () => {
  console.log('\n=== Probando Login ===');
  try {
    const response = await fetch('http://localhost:5000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@utalca.cl',
        password: 'password123'
      })
    });
    const data = await response.json();
    console.log('Respuesta:', response.status, data);
  } catch (error) {
    console.error('Error:', error.message);
  }
};

// Ejecutar pruebas
(async () => {
  await testRegister();
  // Espera 1 segundo antes de probar login
  await new Promise(resolve => setTimeout(resolve, 1000));
  await testLogin();
})();
