import 'package:flutter/material.dart';
import 'package:namer_app/models/conversation.dart';
import 'package:namer_app/services/api_service.dart';
import 'package:namer_app/pages/conversation_page.dart';
import 'package:namer_app/widgets/profile_avatar.dart';
import 'package:namer_app/widgets/report_image.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Primero cargar el usuario, LUEGO las conversaciones
    await _loadCurrentUser();
    await _loadConversations();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await ApiService.getUserData();
    
    if (userData != null && mounted) {
      // Backend usa 'id' en lugar de '_id'
      final userId = userData['id']?.toString();
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getMyConversations();

    if (mounted) {
      if (result['success']) {
        final List<dynamic> data = result['data'];
        setState(() {
          _conversations =
              data.map((json) => Conversation.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al cargar conversaciones'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );

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
              'Mensajes de Reportes',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (totalUnread > 0)
              Text(
                '$totalUnread mensaje${totalUnread != 1 ? 's' : ''} sin leer',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes conversaciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aquí aparecerán los mensajes\nde personas interesadas en tus reportes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      
                      // Determinar quién es el otro usuario
                      // Convertir ambos IDs a String para comparación segura
                      final currentUserIdStr = _currentUserId?.toString() ?? '';
                      final reportAuthorIdStr = conversation.reportAuthorId.toString();
                      final isAuthor = currentUserIdStr == reportAuthorIdStr;
                      
                      final otherUser = isAuthor
                          ? conversation.interestedUserData
                          : conversation.reportAuthorData;

                      final otherUserName =
                          '${otherUser['name']} ${otherUser['lastName']}';
                      final otherUserProfileImage = otherUser['profileImage'];

                      final lastMessage = conversation.messages.isNotEmpty
                          ? conversation.messages.last
                          : null;

                      final reportData = conversation.reportData;
                      final reportTitle = reportData['title'] ?? 'Reporte';
                      final reportImage = reportData['imageUrl'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              // Navegar a la conversación
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConversationPage(
                                    conversationId: conversation.id,
                                    otherUserName: otherUserName,
                                    otherUserProfileImage: otherUserProfileImage,
                                    reportTitle: reportTitle,
                                  ),
                                ),
                              );

                              // Si se volvió de la conversación, recargar
                              if (result == true) {
                                _loadConversations();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar del usuario
                                  Stack(
                                    children: [
                                      ProfileAvatar(
                                        profileImageBase64: otherUserProfileImage,
                                        radius: 28,
                                        borderColor: const Color(0xFFD32F2F),
                                        borderWidth: 2,
                                      ),
                                      if (conversation.unreadCount > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFD32F2F),
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                conversation.unreadCount > 9
                                                    ? '9+'
                                                    : '${conversation.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Información de la conversación
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                otherUserName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      conversation.unreadCount > 0
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (lastMessage != null)
                                              Text(
                                                _formatTime(
                                                    lastMessage.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Título del reporte con icono
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.article_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                reportTitle,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: const Color(0xFFD32F2F),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (lastMessage != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            lastMessage.message,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: conversation.unreadCount > 0
                                                  ? Colors.black87
                                                  : Colors.grey[700],
                                              fontWeight:
                                                  conversation.unreadCount > 0
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Imagen del reporte
                                  if (reportImage != null)
                                    ReportImage(
                                      imageBase64: reportImage,
                                      width: 60,
                                      height: 60,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Hoy - mostrar hora
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
