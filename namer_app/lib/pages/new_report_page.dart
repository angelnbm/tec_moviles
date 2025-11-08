import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:namer_app/models/report.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'dart:async';

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  ReportCategory _selectedCategory = ReportCategory.found;
  Uint8List? _selectedImageBytes;
  // Audio recording variables
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isRecorderInitialized = false;
  bool _isPaused = false;
  Duration _recordDuration = Duration.zero;
  Duration _currentPlaybackPosition = Duration.zero;
  Duration _totalAudioDuration = Duration.zero;
  static const int maxRecordingDuration = 60;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<ap.PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _setupAudioListeners();
  }

  // NUEVO: Método separado para configurar los listeners
  void _setupAudioListeners() {
    // Escuchar cambios en el estado del reproductor
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == ap.PlayerState.playing;
      });
    });

    // Escuchar la duración total del audio
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalAudioDuration = duration;
      });
    });

    // Cuando el audio termine de reproducirse, resetear el estado
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPlaybackPosition = Duration.zero;
      });
    });
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      _showSnackBar('Error al inicializar grabadora: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    // NUEVO: Cancelar subscripciones
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      _showSnackBar('Grabadora no inicializada', Colors.red);
      return;
    }

    try {
      // Solicitar permiso de micrófono
      final status = await ph.Permission.microphone.request();
      if (!status.isGranted) {
        _showSnackBar('Permiso de micrófono denegado', Colors.red);
        return;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath =
          '${appDocDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordDuration = Duration.zero;
        _audioPath = filePath;
      });

      _updateRecordingDuration();
      _showSnackBar('Grabación iniciada', Colors.green);
    } catch (e) {
      _showSnackBar('Error al iniciar grabación: $e', Colors.red);
    }
  }

  Future<void> _togglePauseRecording() async {
    if (!_isRecording) return;

    try {
      if (_isPaused) {
        // Reanudar grabación
        await _audioRecorder.resumeRecorder();
        setState(() {
          _isPaused = false;
        });
        _showSnackBar('Grabación reanudada', Colors.green);
      } else {
        // Pausar grabación
        await _audioRecorder.pauseRecorder();
        setState(() {
          _isPaused = true;
        });
        _showSnackBar('Grabación pausada', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error al pausar/reanudar: $e', Colors.red);
    }
  }

  void _updateRecordingDuration() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });

        // Detener automáticamente si alcanza el límite
        if (_recordDuration.inSeconds >= maxRecordingDuration) {
          await _stopRecording();
          _showSnackBar(
            'Grabación detenida: límite de ${maxRecordingDuration ~/ 60} minutos alcanzado',
            Colors.orange,
          );
        }
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stopRecorder();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      _showSnackBar(
          'Audio grabado: ${_formatDuration(_recordDuration)}', Colors.green);
    } catch (e) {
      _showSnackBar('Error al detener grabación: $e', Colors.red);
    }
  }

  Future<void> _playPauseAudio() async {
    if (_audioPath == null) return;

    try {
      if (_isPlaying) {
        // Pausar audio
        await _audioPlayer.pause();
        // MODIFICADO: Cancelar la subscripción cuando se pausa
        await _positionSubscription?.cancel();
        _positionSubscription = null;
      } else {
        // MODIFICADO: Iniciar subscripción de posición solo al reproducir
        _positionSubscription =
            _audioPlayer.onPositionChanged.listen((position) {
          if (_isPlaying) {
            // Solo actualizar si está reproduciendo
            setState(() {
              _currentPlaybackPosition = position;
            });
          }
        });

        if (_currentPlaybackPosition.inSeconds > 0 &&
            _currentPlaybackPosition < _totalAudioDuration) {
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.play(ap.DeviceFileSource(_audioPath!));
        }
      }
    } catch (e) {
      _showSnackBar('Error al reproducir audio: $e', Colors.red);
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _positionSubscription?.cancel();
      setState(() {
        _isPlaying = false;
        _currentPlaybackPosition = Duration.zero;
      });
    } catch (e) {
      _showSnackBar('Error al detener reproducción: $e', Colors.red);
    }
  }

  void _deleteAudio() async {
    if (_isPlaying) {
      await _stopAudio();
    }
    if (_isRecording) {
      await _audioRecorder.stopRecorder();
    }
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _audioPath = null;
      _recordDuration = Duration.zero;
      _currentPlaybackPosition = Duration.zero;
      _totalAudioDuration = Duration.zero;
      _isPlaying = false;
      _isRecording = false;
      _isPaused = false;
    });
    _showSnackBar('Audio eliminado', Colors.orange);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _showSnackBar('Servicio de ubicación desactivado', Colors.orange);
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _showSnackBar('Permiso de ubicación denegado', Colors.red);
        return;
      }
    }

    try {
      locationData = await location.getLocation();
      setState(() {
        _locationController.text =
            '${locationData.latitude}, ${locationData.longitude}';
      });
      _showSnackBar('Ubicación obtenida correctamente', Colors.green);
    } catch (e) {
      _showSnackBar('Error al obtener ubicación', Colors.red);
    }
  }

  Future<void> _selectLocationOnMap() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionPage()),
    );

    if (selectedLocation != null) {
      setState(() {
        _locationController.text =
            '${selectedLocation.latitude}, ${selectedLocation.longitude}';
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: Color(0xFFD32F2F)),
                ),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.of(context)
                      .pop(await picker.pickImage(source: ImageSource.gallery));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.photo_camera, color: Color(0xFFD32F2F)),
                ),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.of(context)
                      .pop(await picker.pickImage(source: ImageSource.camera));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();

        // Comprimir la imagen
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 300,
          minHeight: 300,
          quality: 60,
        );

        setState(() {
          _selectedImageBytes = Uint8List.fromList(compressedBytes);
        });
      } catch (e) {
        _showSnackBar('Error al procesar imagen: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<String?> _convertAudioToBase64() async {
    if (_audioPath == null) return null;

    try {
      final bytes = await File(_audioPath!).readAsBytes();
      final base64Audio = base64Encode(bytes);
      return 'data:audio/aac;base64,$base64Audio';
    } catch (e) {
      _showSnackBar('Error al procesar audio: $e', Colors.red);
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate location is provided
    if (_locationController.text.isEmpty) {
      _showSnackBar('Por favor selecciona una ubicación', Colors.orange);
      return;
    }

    // Parse coordinates from location text
    final coords = _locationController.text.split(',');
    if (coords.length != 2) {
      _showSnackBar('Formato de ubicación inválido', Colors.red);
      return;
    }

    final latitude = double.tryParse(coords[0].trim());
    final longitude = double.tryParse(coords[1].trim());

    if (latitude == null || longitude == null) {
      _showSnackBar('Coordenadas inválidas', Colors.red);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Preparar la imagen en base64 si existe
      String? imageBase64;
      if (_selectedImageBytes != null) {
        imageBase64 =
            'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
      }

      String? audioBase64;
      if (_audioPath != null) {
        audioBase64 = await _convertAudioToBase64();
      }
      final result = await ApiService.createReport(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory == ReportCategory.found ? 'found' : 'lost',
        location: 'Universidad de Talca', // You can make this more specific
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageBase64,
        audioUrl: audioBase64,
      );

      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showSnackBar('Reporte creado exitosamente', Colors.green);
        // Wait a bit for the snackbar to show
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showSnackBar('Error: ${result['message']}', Colors.red);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showSnackBar('Error inesperado: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo Reporte',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Completa la información',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Card de Categoría
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.category,
                            color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tipo de reporte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryOption(
                          icon: Icons.check_circle,
                          label: 'Encontré',
                          isSelected: _selectedCategory == ReportCategory.found,
                          color: Colors.green,
                          onTap: () {
                            setState(() {
                              _selectedCategory = ReportCategory.found;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryOption(
                          icon: Icons.search,
                          label: 'Perdí',
                          isSelected: _selectedCategory == ReportCategory.lost,
                          color: Colors.orange,
                          onTap: () {
                            setState(() {
                              _selectedCategory = ReportCategory.lost;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card de Información
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Información del objeto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Mochila azul Nike',
                      prefixIcon:
                          const Icon(Icons.title, color: Color(0xFFD32F2F)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFD32F2F), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción *',
                      hintText: 'Describe el objeto con detalle...',
                      prefixIcon: const Icon(Icons.description,
                          color: Color(0xFFD32F2F)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFD32F2F), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card de Ubicación
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on,
                            color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Ubicación *',
                      hintText: 'Selecciona en el mapa',
                      prefixIcon:
                          const Icon(Icons.map, color: Color(0xFFD32F2F)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location,
                            color: Color(0xFFD32F2F)),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Usar mi ubicación',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFD32F2F), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                    onTap: _selectLocationOnMap,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectLocationOnMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Seleccionar en mapa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card de Imagen
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image,
                            color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Imagen (opcional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedImageBytes != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(_selectedImageBytes == null
                          ? Icons.add_photo_alternate
                          : Icons.edit),
                      label: Text(_selectedImageBytes == null
                          ? 'Agregar imagen'
                          : 'Cambiar imagen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: _selectedImageBytes == null
                              ? Colors.grey.shade400
                              : const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card de Audio
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic,
                            color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Audio (opcional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_audioPath == null) ...[
                    if (_isRecording) ...[
                      // MODIFICADO: Nueva UI durante grabación con pausa
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isPaused
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPaused
                                ? Colors.orange.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // NUEVO: Botón de pausa/reanudar
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _isPaused ? Colors.orange : Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isPaused
                                                ? Colors.orange
                                                : Colors.red)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isPaused
                                          ? Icons.play_arrow
                                          : Icons.pause,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: _togglePauseRecording,
                                    tooltip: _isPaused ? 'Reanudar' : 'Pausar',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (!_isPaused) ...[
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            _isPaused ? 'Pausada' : 'Grabando',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _isPaused
                                                  ? Colors.orange.shade700
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDuration(_recordDuration),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: _isPaused
                                              ? Colors.orange.shade700
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Botón de detener
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _stopRecording,
                                icon: const Icon(Icons.stop, size: 20),
                                label: const Text('Finalizar grabación'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic),
                          label: const Text('Grabar audio'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFD32F2F)),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Audio grabado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  size: 48,
                                  color: Colors.green.shade700,
                                ),
                                onPressed: _playPauseAudio,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPlaying
                                          ? 'Reproduciendo...'
                                          : 'Audio grabado',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Duración: ${_formatDuration(_recordDuration)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // MODIFICADO: Agregar GestureDetector para prevenir propagación de eventos
                              GestureDetector(
                                onTap: () {
                                  // Llamar directamente sin propagación
                                  _deleteAudio();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_totalAudioDuration.inSeconds > 0 && _isPlaying)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(
                                value: _currentPlaybackPosition.inMilliseconds /
                                    _totalAudioDuration.inMilliseconds,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green.shade700),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // REMOVIDO: Eliminar el botón "Regrabar audio" para evitar confusión
                    // Después de borrar, el usuario simplemente puede presionar "Grabar audio" de nuevo
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Máximo ${maxRecordingDuration ~/ 60} minutos de grabación',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Botón de crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFFD32F2F).withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Crear Reporte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapSelectionPage extends StatefulWidget {
  const MapSelectionPage({super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  final LatLng _initialPosition = const LatLng(-35.0025173, -71.2294064);
  LatLng? _selectedPosition;

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Ubicación',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Toca el mapa para marcar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFFD32F2F)),
              onPressed: () {
                Navigator.of(context).pop(_selectedPosition);
              },
              tooltip: 'Confirmar ubicación',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onTap: _onMapTapped,
            markers: _selectedPosition == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: _selectedPosition!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
          ),
          if (_selectedPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFD32F2F),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ubicación seleccionada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
