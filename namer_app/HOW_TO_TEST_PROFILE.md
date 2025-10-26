# 🧪 Cómo Probar la Funcionalidad de Edición de Perfil

## ✅ Pre-requisitos

1. **Backend corriendo**: 
   ```powershell
   cd c:\Users\felip\Desktop\tec_moviles\loss_utal_backend
   npm start
   ```
   ✅ Debe mostrar: "Servidor corriendo en 0.0.0.0:5000" y "MongoDB conectado"

2. **App Flutter corriendo**: 
   ```powershell
   cd c:\Users\felip\Desktop\tec_moviles\namer_app
   flutter run -d chrome
   ```

## 🎯 Pasos para Probar

### 1. Registrar un Nuevo Usuario (Recomendado)

Para probar con todos los campos nuevos:

1. Abre la app en Chrome
2. En la pantalla de login, haz clic en "¿No tienes cuenta? Regístrate"
3. Completa el formulario:
   - **Nombre**: Tu nombre
   - **Apellido**: Tu apellido
   - **RUT**: Cualquier número (ej: 12345678-9)
   - **Email**: Un email único (ej: prueba@test.com)
   - **Contraseña**: Una contraseña
   - **Repetir Contraseña**: La misma contraseña
4. Haz clic en "Registrarse"
5. Deberías ver el mensaje "Registro exitoso"

### 2. Iniciar Sesión

1. Vuelve a la pantalla de login
2. Ingresa el email y contraseña que usaste para registrarte
3. Haz clic en "Ingresar"
4. Deberías ver el mensaje "¡Inicio de sesión exitoso!"
5. Serás redirigido a la pantalla principal

### 3. Ver tu Perfil

1. En la barra de navegación inferior, haz clic en el ícono de "Perfil" (persona)
2. Deberías ver:
   - Tu foto de perfil (por defecto, un ícono de persona)
   - Tu nombre completo
   - Tu correo electrónico
   - Botón "Editar Perfil"
   - Botón "Cerrar Sesión"

### 4. Editar tu Perfil

1. Haz clic en el botón "Editar Perfil"
2. Verás el formulario de edición con:
   - Foto de perfil actual
   - Campo de nombre (con tu nombre actual)
   - Campo de apellido (con tu apellido actual)
   - Campo de email (deshabilitado, no se puede cambiar)

### 5. Cambiar Foto de Perfil

**Opción A: Desde Galería (Web)**
1. Haz clic en la foto de perfil o en el botón de cámara
2. Selecciona "Galería"
3. Selecciona una imagen de tu computadora
4. Verás una vista previa de la imagen seleccionada

**Opción B: Desde Cámara (Android/iOS)**
1. Haz clic en la foto de perfil o en el botón de cámara
2. Selecciona "Cámara"
3. Toma una foto
4. Verás una vista previa de la foto tomada

### 6. Cambiar Nombre y Apellido

1. Modifica el campo "Nombre"
2. Modifica el campo "Apellido"
3. Los cambios se reflejarán al guardar

### 7. Guardar Cambios

1. Haz clic en el botón "Guardar Cambios"
2. Verás un indicador de carga
3. Deberías ver el mensaje "Perfil actualizado exitosamente"
4. Serás redirigido automáticamente a la pantalla de perfil
5. Los cambios deberían reflejarse inmediatamente

### 8. Verificar Cambios

1. En la pantalla de perfil, verifica que:
   - La foto de perfil se muestra correctamente
   - El nombre y apellido se actualizaron
2. Opcional: Cierra sesión y vuelve a iniciar sesión
3. Los cambios deberían persistir

## 🐛 Qué Buscar (Testing)

### ✅ Funcionalidades que Deben Funcionar

- [x] Registro de usuario con nombre y apellido
- [x] Login retorna todos los campos del usuario
- [x] Botón "Editar Perfil" solo visible para usuarios con cuenta
- [x] Selector de imagen funciona (galería en web)
- [x] Vista previa de imagen seleccionada
- [x] Formulario de edición se pre-llena con datos actuales
- [x] Validación de campos (nombre y apellido requeridos)
- [x] Loading state durante guardado
- [x] Actualización exitosa con mensaje de confirmación
- [x] UI se actualiza inmediatamente después de guardar
- [x] Foto de perfil se muestra en formato circular
- [x] Foto de perfil persiste después de cerrar sesión y volver a iniciar

### ⚠️ Casos de Error a Probar

1. **Sin conexión al servidor**:
   - Detén el backend
   - Intenta editar perfil
   - Deberías ver: "Error de conexión"

2. **Token inválido o expirado**:
   - Edita manualmente el token en el código
   - Intenta editar perfil
   - Deberías ver error de autenticación

3. **Campos vacíos**:
   - Borra el nombre o apellido
   - Intenta guardar
   - Deberías ver: "El nombre es requerido" o "El apellido es requerido"

4. **Imagen muy grande** (opcional):
   - Selecciona una imagen muy pesada
   - Debería funcionar porque se redimensiona automáticamente

### 📱 Probar en Diferentes Plataformas

#### Web (Chrome) ✅
- Selector de archivos estándar
- No puede usar cámara
- Puede seleccionar archivos del sistema

#### Android Emulador (si tienes uno)
```powershell
flutter run -d emulator
```
- Cambiar en `api_config.dart`: URL debe ser `http://10.0.2.2:5000`
- Puede usar galería
- Puede usar cámara

#### Windows Desktop (opcional)
```powershell
flutter run -d windows
```
- Selector de archivos de Windows
- Funciona similar a web

## 📊 Verificar en Base de Datos

Si quieres verificar que los datos se guardaron correctamente en MongoDB:

1. Ve a [MongoDB Atlas](https://cloud.mongodb.com/)
2. Inicia sesión
3. Ve a tu cluster
4. Haz clic en "Browse Collections"
5. Busca tu base de datos y colección "users"
6. Deberías ver el documento del usuario con:
   - `name`: Nombre actualizado
   - `lastName`: Apellido actualizado
   - `profilePhoto`: String largo de Base64 (si agregaste foto)
   - `updatedAt`: Timestamp de la última actualización

## 🎯 Flujo Completo Recomendado

```
1. Registrar nuevo usuario
   ✓ Llena todos los campos
   ✓ Verifica mensaje de éxito

2. Iniciar sesión
   ✓ Usa las credenciales del registro
   ✓ Verifica redirección a MainPage

3. Ir a Perfil
   ✓ Verifica que se muestra tu nombre completo
   ✓ Verifica que se muestra tu email

4. Editar Perfil
   ✓ Cambia nombre a "NuevoNombre"
   ✓ Cambia apellido a "NuevoApellido"
   ✓ Agrega una foto

5. Guardar
   ✓ Verifica loading
   ✓ Verifica mensaje de éxito
   ✓ Verifica que vuelve a pantalla de perfil

6. Verificar cambios
   ✓ Verifica nombre actualizado
   ✓ Verifica foto visible

7. Cerrar sesión y volver a iniciar
   ✓ Los cambios deben persistir
```

## 🎉 Resultado Esperado

Al completar todos los pasos, deberías tener:
- ✅ Usuario registrado con todos los campos
- ✅ Perfil completamente funcional
- ✅ Foto de perfil personalizada
- ✅ Nombre y apellido actualizados
- ✅ Cambios persistentes en la base de datos

## 📝 Notas Importantes

1. **Formato de Imagen**: Las imágenes se convierten a Base64 antes de enviarlas al servidor
2. **Tamaño de Imagen**: Se redimensionan automáticamente a máximo 800x800px
3. **Token JWT**: Expira en 5 horas (configurable en el backend)
4. **Email**: No se puede cambiar por seguridad
5. **RUT**: No se puede cambiar (solo en registro)

## ❓ Preguntas Frecuentes

**P: ¿Por qué no puedo cambiar mi email?**
R: Por seguridad, el email es el identificador único del usuario y no debe cambiar.

**P: ¿Puedo eliminar mi foto de perfil?**
R: Actualmente no hay opción de eliminar, pero puedes seleccionar una imagen en blanco.

**P: ¿Qué pasa si selecciono una imagen muy grande?**
R: La app automáticamente la redimensiona a 800x800px y la comprime al 85% de calidad.

**P: ¿Los cambios son permanentes?**
R: Sí, se guardan en MongoDB y persisten entre sesiones.

**P: ¿Qué pasa si uso modo invitado?**
R: El modo invitado no permite editar perfil. Debes crear una cuenta.
