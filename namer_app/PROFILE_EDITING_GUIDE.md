# 📝 Funcionalidad de Edición de Perfil

## 🎯 Descripción

Sistema completo de edición de perfil para usuarios con cuenta. Permite actualizar nombre, apellido y foto de perfil.

## ✨ Características

### Frontend (Flutter)

1. **ProfilePage** (`lib/pages/profile_page.dart`)
   - Muestra información del usuario
   - Muestra foto de perfil (si existe)
   - Botón de editar perfil (solo para usuarios con cuenta)
   - Botón de cerrar sesión
   - Diferencia entre usuario con cuenta y usuario invitado

2. **EditProfilePage** (`lib/pages/edit_profile_page.dart`)
   - Formulario de edición de perfil
   - Selector de foto de perfil (galería o cámara)
   - Vista previa de la imagen seleccionada
   - Validación de campos
   - Conversión de imagen a Base64 para envío al servidor
   - Actualización en tiempo real del perfil

### Backend (Node.js)

1. **Modelo User actualizado** (`models/User.js`)
   - Nuevo campo `profilePhoto` para almacenar la foto en Base64
   - Timestamps automáticos (createdAt, updatedAt)

2. **Middleware de Autenticación** (`middleware/auth.js`)
   - Verifica el token JWT en las peticiones
   - Protege rutas que requieren autenticación

3. **Nuevas Rutas de API** (`routes/auth.js`)
   - `GET /api/auth/profile` - Obtener perfil del usuario autenticado
   - `PUT /api/auth/profile` - Actualizar perfil del usuario

## 🔐 Seguridad

- ✅ Rutas de perfil protegidas con autenticación JWT
- ✅ Solo el usuario autenticado puede ver/editar su perfil
- ✅ Token enviado en header `Authorization: Bearer <token>`
- ✅ Validación de campos en frontend y backend

## 📸 Manejo de Imágenes

### Selección de Imagen
- **Desde Galería**: Usa `ImagePicker.pickImage(source: ImageSource.gallery)`
- **Desde Cámara**: Usa `ImagePicker.pickImage(source: ImageSource.camera)`

### Optimización
- Redimensiona imágenes a máximo 800x800px
- Calidad de compresión al 85%
- Convierte a Base64 para almacenamiento en MongoDB

### Almacenamiento
- Formato: `data:image/jpeg;base64,<datos_base64>`
- Almacenado en el campo `profilePhoto` del usuario en MongoDB

## 🔄 Flujo de Uso

### 1. Usuario Inicia Sesión
```
LoginFormPage 
  └─> POST /api/auth/login
      └─> Recibe: { token, user: { id, name, lastName, email, profilePhoto } }
      └─> Navega a MainPage con user y token
```

### 2. Usuario Ve su Perfil
```
MainPage > ProfilePage
  └─> Muestra información del usuario
  └─> Muestra foto de perfil (si existe)
  └─> Botón "Editar Perfil" disponible
```

### 3. Usuario Edita su Perfil
```
ProfilePage > EditProfilePage
  └─> Muestra formulario con datos actuales
  └─> Usuario puede:
      ├─> Cambiar nombre
      ├─> Cambiar apellido
      └─> Cambiar foto (galería o cámara)
  └─> Al guardar:
      └─> PUT /api/auth/profile con token en header
      └─> Actualiza base de datos
      └─> Regresa a ProfilePage con datos actualizados
```

## 🛠️ Uso Técnico

### Enviar Petición Autenticada (Flutter)

```dart
final response = await http.put(
  Uri.parse('${ApiConfig.baseUrl}/api/auth/profile'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // Token JWT
  },
  body: json.encode({
    'name': 'Nuevo Nombre',
    'lastName': 'Nuevo Apellido',
    'profilePhoto': 'data:image/jpeg;base64,...',
  }),
);
```

### Probar con cURL

```bash
# Obtener perfil
curl -X GET http://localhost:5000/api/auth/profile \
  -H "Authorization: Bearer TU_TOKEN_AQUI"

# Actualizar perfil
curl -X PUT http://localhost:5000/api/auth/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{
    "name": "Nuevo Nombre",
    "lastName": "Nuevo Apellido",
    "profilePhoto": ""
  }'
```

## 📋 Estados del Usuario

### Usuario con Cuenta
- ✅ Puede ver su perfil completo
- ✅ Puede editar nombre, apellido y foto
- ✅ Tiene token de autenticación
- ✅ Botón "Editar Perfil" visible
- ✅ Botón "Cerrar Sesión"

### Usuario Invitado (Guest)
- ❌ No puede editar perfil
- ❌ No tiene token
- ⚠️ Botón "Editar Perfil" no visible
- ℹ️ Muestra indicador "Modo invitado"
- ℹ️ Botón "Ir a Iniciar Sesión"

## 🐛 Manejo de Errores

### Frontend
- Timeout de 10 segundos
- Mensajes de error descriptivos en SnackBar
- Loading indicators durante operaciones
- Validación de formularios

### Backend
- Verifica autenticación
- Valida que el usuario exista
- Maneja errores de base de datos
- Retorna códigos de estado apropiados

## 📱 Consideraciones de Plataforma

### Web (Chrome/Edge)
- ⚠️ Selector de archivos estándar del navegador
- ⚠️ No puede usar cámara directamente
- ✅ Puede seleccionar archivos de galería

### Android
- ✅ Selector de imagen funcional
- ✅ Puede usar cámara
- ✅ Permisos de almacenamiento manejados por image_picker

### iOS
- ✅ Selector de imagen nativo
- ✅ Puede usar cámara
- ℹ️ Requiere permisos en Info.plist

## 🔄 Próximas Mejoras Sugeridas

1. **Validación de tamaño de imagen**: Limitar tamaño máximo del archivo
2. **Crop de imagen**: Permitir recortar imagen antes de subir
3. **Almacenamiento en Cloud**: Usar AWS S3, Firebase Storage, etc. en lugar de Base64
4. **Caché de imágenes**: Cachear imágenes para mejor rendimiento
5. **Cambio de contraseña**: Agregar funcionalidad para cambiar contraseña
6. **Eliminar foto**: Opción para remover foto de perfil
7. **Validación de RUT**: Agregar edición de RUT con validación chilena

## 📦 Dependencias Usadas

### Flutter
- `image_picker`: ^1.0.7 - Selección de imágenes
- `http`: ^1.2.1 - Peticiones HTTP

### Node.js
- `express`: ^5.1.0 - Framework web
- `jsonwebtoken`: ^9.0.2 - Autenticación JWT
- `mongoose`: ^8.19.2 - ODM para MongoDB
- `bcryptjs`: ^3.0.2 - Hash de contraseñas

## ✅ Checklist de Implementación

- [x] Modelo User actualizado con profilePhoto
- [x] Middleware de autenticación creado
- [x] Ruta GET /api/auth/profile
- [x] Ruta PUT /api/auth/profile
- [x] EditProfilePage creada
- [x] ProfilePage actualizada
- [x] MainPage actualizada para pasar token
- [x] LoginFormPage actualizada para recibir token
- [x] Selector de imagen implementado
- [x] Conversión a Base64 implementada
- [x] Validación de formularios
- [x] Manejo de errores
- [x] Loading states
- [x] Actualización en tiempo real de UI

## 🎓 Aprendizajes Clave

1. **Autenticación JWT**: Cómo proteger rutas con tokens
2. **Manejo de imágenes en Flutter**: Uso de ImagePicker
3. **Base64 encoding**: Conversión y almacenamiento de imágenes
4. **Estado en Flutter**: Actualización de estado entre páginas
5. **REST API**: Diseño de endpoints RESTful
6. **Middleware en Express**: Protección de rutas
