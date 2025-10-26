// Script de prueba para el sistema de edición de perfil
const testToken = 'REEMPLAZA_CON_TU_TOKEN'; // Obtén esto del login

const testGetProfile = async () => {
  console.log('=== Probando GET Profile ===');
  try {
    const response = await fetch('http://localhost:5000/api/auth/profile', {
      method: 'GET',
      headers: { 
        'Authorization': `Bearer ${testToken}`,
      },
    });
    const data = await response.json();
    console.log('Respuesta:', response.status, data);
  } catch (error) {
    console.error('Error:', error.message);
  }
};

const testUpdateProfile = async () => {
  console.log('\n=== Probando PUT Profile ===');
  try {
    const response = await fetch('http://localhost:5000/api/auth/profile', {
      method: 'PUT',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${testToken}`,
      },
      body: JSON.stringify({
        name: 'Nombre Actualizado',
        lastName: 'Apellido Actualizado',
        profilePhoto: '' // Vacío por ahora, puedes agregar Base64 aquí
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
  if (testToken === 'REEMPLAZA_CON_TU_TOKEN') {
    console.log('⚠️  Por favor, actualiza testToken con un token válido del login');
    console.log('   Puedes obtenerlo iniciando sesión en la app y copiando el token de la consola');
    return;
  }
  
  await testGetProfile();
  await new Promise(resolve => setTimeout(resolve, 1000));
  await testUpdateProfile();
  await new Promise(resolve => setTimeout(resolve, 1000));
  await testGetProfile(); // Ver cambios
})();
