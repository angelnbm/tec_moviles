# Guía de Solución de Problemas - Conexión Backend

## Problema: No se puede conectar a `http://10.0.2.2:5000/api/auth/login`

### ✅ Soluciones Implementadas

1. **Servidor Backend Actualizado**
   - El servidor ahora escucha en `0.0.0.0:5000` en lugar de solo `localhost`
   - Esto permite conexiones desde el emulador de Android

2. **Permiso de Internet Agregado**
   - Se agregó `<uses-permission android:name="android.permission.INTERNET"/>` en `AndroidManifest.xml`

3. **Mejor Manejo de Errores**
   - Se agregaron mensajes de error más descriptivos
   - Se agregó timeout de 10 segundos
   - Se agregaron logs en consola para debugging

4. **Configuración Centralizada**
   - Se creó `lib/config/api_config.dart` para manejar URLs del API

---

## 🚀 Pasos para Ejecutar

### 1. Iniciar el Backend

```powershell
cd c:\Users\felip\Desktop\tec_moviles\loss_utal_backend
npm start
```

**Verifica que veas:**
```
Servidor corriendo en 0.0.0.0:5000
MongoDB conectado
```

### 2. Ejecutar la App Flutter

```powershell
cd c:\Users\felip\Desktop\tec_moviles\namer_app
flutter run
```

---

## 🔧 Configuración según el Dispositivo

### ✅ Auto-detectado (Ya Configurado)

El código ahora detecta automáticamente la plataforma y usa la URL correcta:

- **Chrome/Edge/Firefox (Web)**: `http://localhost:5000` 
- **Emulador Android**: `http://10.0.2.2:5000`
- **iOS Simulator**: `http://localhost:5000`

Ver `PLATFORM_URLS.md` para más detalles sobre URLs por plataforma.

### Para Dispositivo Físico Android/iOS
1. Encuentra la IP local de tu computadora:
   ```powershell
   ipconfig
   ```
   Busca la línea "IPv4 Address" (ej: `192.168.1.100`)

2. Actualiza `lib/config/api_config.dart`:
   ```dart
   static String get baseUrl {
     // Cambia el return para forzar tu IP
     return 'http://TU_IP_LOCAL:5000';
   }
   ```

3. Asegúrate de que tu dispositivo y computadora estén en la misma red WiFi

---

## 🐛 Debugging

### Ver logs de la app:
Los logs aparecerán en la consola cuando ejecutes la app con `flutter run`. Busca mensajes como:
- `Intentando conectar a: http://10.0.2.2:5000/api/auth/login`
- `Respuesta recibida: 200`

### Probar el backend manualmente:

```powershell
# Probar registro
curl -X POST http://localhost:5000/api/auth/register -H "Content-Type: application/json" -d '{\"name\":\"Test\",\"lastName\":\"User\",\"rut\":\"12345678-9\",\"email\":\"test@test.com\",\"password\":\"123456\"}'

# Probar login
curl -X POST http://localhost:5000/api/auth/login -H "Content-Type: application/json" -d '{\"email\":\"test@test.com\",\"password\":\"123456\"}'
```

---

## ⚠️ Errores Comunes

### Error: "Connection refused"
- **Causa**: El servidor backend no está corriendo
- **Solución**: Inicia el servidor con `npm start`

### Error: "Timeout"
- **Causa**: El servidor no es accesible desde el emulador
- **Solución**: 
  1. Verifica que el servidor esté escuchando en `0.0.0.0:5000`
  2. Verifica que no haya firewall bloqueando el puerto 5000

### Error: "Credenciales inválidas"
- **Causa**: Usuario no existe o contraseña incorrecta
- **Solución**: Primero registra un usuario en la página de registro

### Error: "MongoDB no conectado"
- **Causa**: La URI de MongoDB en `.env` no es válida o hay problemas de conexión
- **Solución**: Verifica el archivo `.env` en `loss_utal_backend`

---

## 📝 Verificación Rápida

✅ Backend corriendo en puerto 5000  
✅ MongoDB conectado  
✅ Permiso de INTERNET en AndroidManifest.xml  
✅ URL correcta según dispositivo en `api_config.dart`  
✅ Emulador/Dispositivo iniciado  

---

## 🆘 Última Opción

Si nada funciona, reinicia todo:

```powershell
# 1. Detén el backend (Ctrl+C)
# 2. Reinicia el backend
cd c:\Users\felip\Desktop\tec_moviles\loss_utal_backend
npm start

# 3. En otra terminal, reinicia la app
cd c:\Users\felip\Desktop\tec_moviles\namer_app
flutter clean
flutter pub get
flutter run
```
