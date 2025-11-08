import 'package:flutter/material.dart';
import 'package:namer_app/widgets/profile_avatar.dart';
import 'package:namer_app/widgets/report_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/pages/conversation_page.dart';
import 'dart:convert';
import 'dart:async';

class ObjectDetailPage extends StatefulWidget {
  final dynamic report;

  const ObjectDetailPage({super.key, required this.report});

  @override
  State<ObjectDetailPage> createState() => _ObjectDetailPageState();
}

class _ObjectDetailPageState extends State<ObjectDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _conversationExists = false;
  bool _isCheckingConversation = true;
  bool _isOwnReport = false;
  String? _currentUserName;
  String? _currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _checkExistingConversation();
    _checkIfOwnReport();
  }

  Future<void> _checkIfOwnReport() async {
    final userData = await ApiService.getUserData();
    final currentUserId = userData?['_id']?.toString() ?? '';
    final reportUserId = widget.report['userId'] is Map
        ? widget.report['userId']['_id']?.toString() ?? ''
        : widget.report['userId']?.toString() ?? '';

    if (mounted) {
      setState(() {
        _isOwnReport = currentUserId.isNotEmpty && currentUserId == reportUserId;
        if (_isOwnReport && userData != null) {
          _currentUserName = '${userData['name']} ${userData['lastName']}';
          _currentUserProfileImage = userData['profileImage'];
        }
      });
    }
  }

  Future<void> _checkExistingConversation() async {
    setState(() {
      _isCheckingConversation = true;
    });

    final result = await ApiService.checkConversationForReport(widget.report['_id']);
    
    if (mounted) {
      setState(() {
        _conversationExists = result['success'] && result['data']['exists'] == true;
        _isCheckingConversation = false;
      });
    }
  }

  void _setupAudioListeners() {
    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _playPauseAudio() async {
    final audioUrl = widget.report['audioUrl'];
    if (audioUrl == null || audioUrl.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        await _positionSubscription?.cancel();
        _positionSubscription = null;
      } else {
        _positionSubscription =
            _audioPlayer.onPositionChanged.listen((position) {
          if (_isPlaying && mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        });

        if (_currentPosition.inSeconds > 0 &&
            _currentPosition < _totalDuration) {
          await _audioPlayer.resume();
        } else {
          if (audioUrl.startsWith('data:audio/')) {
            final base64String = audioUrl.split(',')[1];
            final bytes = base64Decode(base64String);
            await _audioPlayer.play(BytesSource(bytes));
          } else {
            await _audioPlayer.play(UrlSource(audioUrl));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _showContactDialog() async {
    final userId = widget.report['userId'];
    final userName = userId != null && userId is Map
        ? '${userId['name']} ${userId['lastName']}'
        : 'Usuario UTALCA';
    final userProfileImage =
        userId != null && userId is Map ? userId['profileImage'] : null;

    // Primero verificar si ya existe una conversación
    final checkResult = await ApiService.checkConversationForReport(widget.report['_id']);
    
    if (checkResult['success'] && checkResult['data']['exists'] == true) {
      // Ya existe una conversación, ir directamente al chat
      final conversation = checkResult['data']['conversation'];
      final userData = await ApiService.getUserData();
      final currentUserId = userData?['_id']?.toString() ?? '';

      // Determinar quién es el otro usuario
      final reportAuthorId = conversation['reportAuthorId']['_id']?.toString() ?? '';
      final isAuthor = currentUserId == reportAuthorId;
      final otherUser = isAuthor
          ? conversation['interestedUserId']
          : conversation['reportAuthorId'];

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: conversation['_id'],
              otherUserName: '${otherUser['name']} ${otherUser['lastName']}',
              otherUserProfileImage: otherUser['profileImage'],
              reportTitle: conversation['reportId']['title'],
            ),
          ),
        );
      }
      return;
    }

    // No existe conversación, mostrar diálogo para crear una
    final messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.message,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Contactar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Usuario info
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        profileImageBase64: userProfileImage,
                        radius: 40,
                        borderColor: const Color(0xFFD32F2F),
                        borderWidth: 3,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Miembro de la comunidad',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo de mensaje
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Escribe tu mensaje sobre el objeto...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            hintStyle: TextStyle(fontSize: 14),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón enviar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  final message =
                                      messageController.text.trim();
                                  if (message.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Por favor escribe un mensaje'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isSending = true;
                                  });

                                  // Crear conversación
                                  final result =
                                      await ApiService.createConversation(
                                    reportId: widget.report['_id'],
                                    initialMessage: message,
                                  );

                                  if (!mounted) return;

                                  if (result['success']) {
                                    Navigator.pop(dialogContext);

                                    // Actualizar el estado para mostrar "Ver Chat"
                                    setState(() {
                                      _conversationExists = true;
                                    });

                                    // Navegar a la página de conversación
                                    final conversation = result['data'];
                                    final userData =
                                        await ApiService.getUserData();
                                    final currentUserId = userData?['_id']?.toString() ?? '';

                                    // Determinar quién es el otro usuario
                                    final reportAuthorId = conversation['reportAuthorId']['_id']?.toString() ?? '';
                                    final isAuthor = currentUserId == reportAuthorId;
                                    final otherUser = isAuthor
                                        ? conversation['interestedUserId']
                                        : conversation['reportAuthorId'];

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ConversationPage(
                                          conversationId: conversation['_id'],
                                          otherUserName:
                                              '${otherUser['name']} ${otherUser['lastName']}',
                                          otherUserProfileImage:
                                              otherUser['profileImage'],
                                          reportTitle:
                                              conversation['reportId']['title'],
                                        ),
                                      ),
                                    );
                                  } else {
                                    setDialogState(() {
                                      isSending = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ??
                                            'Error al enviar mensaje'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Enviar mensaje',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.report['category'] == 'lost';
    final reportType = isLost ? 'Objeto Perdido' : 'Objeto Encontrado';
    final createdAt = DateTime.parse(widget.report['createdAt']);
    final formattedDate =
        "${createdAt.day}/${createdAt.month}/${createdAt.year}";
    final statusColor = isLost ? Colors.orange : Colors.green;

    // Usuario information
    final userId = widget.report['userId'];
    String userName;
    String? userProfileImage;
    
    // Si es el propio reporte del usuario, usar datos del usuario actual
    if (_isOwnReport && _currentUserName != null) {
      userName = _currentUserName!;
      userProfileImage = _currentUserProfileImage;
    } else {
      // Usuario de otro reporte
      userName = userId != null && userId is Map
          ? '${userId['name']} ${userId['lastName']}'
          : 'Usuario UTALCA';
      userProfileImage =
          userId != null && userId is Map ? userId['profileImage'] : null;
    }

    final audioUrl = widget.report['audioUrl'];
    final hasAudio = audioUrl != null && audioUrl.toString().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.report['title'],
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFD32F2F)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.share, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Función de compartir próximamente'),
                    ],
                  ),
                  backgroundColor: Color(0xFFD32F2F),
                ),
              );
            },
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Imagen del objeto con badge
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ReportImage(
                  imageBase64: widget.report['imageUrl'],
                  fit: BoxFit.cover,
                ),
                // Badge de estado en la esquina
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.shade200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLost ? Icons.search : Icons.check_circle,
                          size: 20,
                          color: statusColor.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reportType,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Título y descripción
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.report['description'],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NUEVO: Card de Audio (solo si existe)
          if (hasAudio)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        child: const Icon(
                          Icons.audiotrack,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nota de Audio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? const Color(0xFFD32F2F).withOpacity(0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPlaying
                            ? const Color(0xFFD32F2F).withOpacity(0.3)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD32F2F)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _playPauseAudio,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPlaying
                                        ? 'Reproduciendo...'
                                        : 'Toca para escuchar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_totalDuration.inSeconds > 0)
                                    Text(
                                      _isPlaying
                                          ? '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}'
                                          : 'Duración: ${_formatDuration(_totalDuration)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isPlaying)
                              IconButton(
                                icon: Icon(
                                  Icons.stop,
                                  color: Colors.grey[700],
                                ),
                                onPressed: _stopAudio,
                                tooltip: 'Detener',
                              ),
                          ],
                        ),
                        if (_totalDuration.inSeconds > 0 && _isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _currentPosition.inMilliseconds /
                                    _totalDuration.inMilliseconds,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD32F2F),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (hasAudio) const SizedBox(height: 16),
          const SizedBox(height: 16),
          // Ubicación y Fecha
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        Icons.info_outline,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Información del reporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Ubicación
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.report['location'] ?? 'Sin ubicación',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map_outlined,
                          color: Color(0xFFD32F2F)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.map, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Vista de mapa próximamente'),
                              ],
                            ),
                            backgroundColor: Color(0xFFD32F2F),
                          ),
                        );
                      },
                      tooltip: 'Ver en mapa',
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Fecha
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha del reporte',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 16),
          // Información de contacto
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reportado por',
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
                    ProfileAvatar(
                      profileImageBase64: userProfileImage,
                      radius: 28,
                      borderColor: const Color(0xFFD32F2F),
                      borderWidth: 2,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Miembro de la comunidad',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
          const SizedBox(height: 20),
          // Botón de contactar (solo si no es el propio reporte)
          if (!_isOwnReport)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: _isCheckingConversation
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _showContactDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0xFFD32F2F).withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _conversationExists ? Icons.chat : Icons.message,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _conversationExists ? 'Ver Chat' : 'Contactar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          if (!_isOwnReport) const SizedBox(height: 30),
          if (_isOwnReport) const SizedBox(height: 20),
          // Footer
          Column(
            children: [
              Icon(
                Icons.school,
                color: Colors.grey[400],
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                '© 2025 Universidad de Talca',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sistema de Objetos Perdidos',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
