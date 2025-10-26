# 🌐 URLs del Backend según la Plataforma

El archivo `lib/config/api_config.dart` ahora detecta **automáticamente** la plataforma y usa la URL correcta.

## URLs por Plataforma

| Plataforma | URL del Backend | Nota |
|------------|----------------|------|
| **Chrome/Edge/Firefox (Web)** | `http://localhost:5000` | ✅ Auto-detectado |
| **Emulador Android** | `http://10.0.2.2:5000` | ✅ Auto-detectado |
| **iOS Simulator** | `http://localhost:5000` | ✅ Auto-detectado |
| **Dispositivo Físico** | `http://TU_IP_LOCAL:5000` | ⚠️ Requiere configuración manual |

## 🔍 ¿Por qué URLs diferentes?

### Web (Chrome, Edge, Firefox)
- Los navegadores web corren en tu máquina local
- Pueden acceder directamente a `localhost:5000`

### Emulador Android
- El emulador Android tiene su propio stack de red
- `10.0.2.2` es una dirección especial que redirecciona a `localhost` de la máquina host
- `localhost` en el emulador Android **NO** apunta a tu PC, sino al emulador mismo

### iOS Simulator
- El simulador de iOS comparte el stack de red con macOS
- Puede acceder directamente a `localhost:5000`

### Dispositivo Físico
- Tu teléfono está en una red diferente (WiFi)
- Necesita la IP local de tu computadora en la red

## 📱 Para Usar con Dispositivo Físico

1. **Encuentra tu IP local:**
   ```powershell
   ipconfig
   ```
   Busca "IPv4 Address" bajo tu adaptador WiFi (ej: `192.168.1.100`)

2. **Edita `lib/config/api_config.dart`:**
   ```dart
   static String get baseUrl {
     if (kIsWeb) {
       return 'http://localhost:5000';
     } else {
       // CAMBIA AQUÍ TU IP LOCAL PARA DISPOSITIVOS FÍSICOS
       return 'http://192.168.1.100:5000';  // <-- Tu IP aquí
     }
   }
   ```

3. **Asegúrate de que:**
   - Tu PC y teléfono estén en la misma red WiFi
   - El firewall de Windows permita conexiones en el puerto 5000

## 🧪 Probar la Conexión

El código ahora imprime en consola qué URL está usando:

```
🌐 API Base URL: http://localhost:5000
📱 Platform: Web
```

o

```
🌐 API Base URL: http://10.0.2.2:5000
📱 Platform: Mobile/Desktop
```

## ✅ Estado Actual

- ✅ **Web (Chrome)**: Configurado para usar `http://localhost:5000`
- ✅ **Android Emulador**: Configurado para usar `http://10.0.2.2:5000`
- ✅ **iOS Simulator**: Configurado para usar `http://localhost:5000`
- ⏳ **Dispositivo Físico**: Requiere configuración manual (ver arriba)

## 🔧 Cambiar la URL Manualmente (si es necesario)

Si la auto-detección no funciona, puedes forzar una URL específica en `lib/config/api_config.dart`:

```dart
static String get baseUrl {
  return 'http://TU_URL_AQUI:5000';  // Forzar una URL específica
}
```
