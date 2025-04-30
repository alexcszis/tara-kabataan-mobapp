import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'blogs.dart';
import 'settings.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart';

// Import our API service
import 'api_service.dart';

// Format Date
String formatDate(String rawDate) {
  try {
    final parsedDate = DateTime.parse(rawDate);
    return DateFormat('MMMM d, y').format(parsedDate);
  } catch (_) {
    return rawDate;
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>>? events;
  bool isLoading = true;
  bool showAddForm = false;
  Map<String, dynamic>? eventToEdit;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  // Image
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Load events from the API
  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getEvents();
      setState(() {
        events = List<Map<String, dynamic>>.from(response['events']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error loading events: $e');
    }
  }

  // Show add/edit form
  void _showAddEditForm({Map<String, dynamic>? event}) {
    setState(() {
      showAddForm = true;
      eventToEdit = event;
      
      if (event != null) {
        // Populate form with event data
        _titleController.text = event['title'] ?? '';
        _contentController.text = event['content'] ?? '';
        _categoryController.text = event['category'] ?? '';
        _imageUrl = event['image_url'];
      } else {
        // Clear form for new event
        _titleController.clear();
        _contentController.clear();
        _categoryController.clear();
        _imageUrl = null;
      }
      
      _imageBytes = null;
      _imageFileName = null;
    });
  }

  // Cancel add/edit form
  void _cancelAddEdit() {
    setState(() {
      showAddForm = false;
      eventToEdit = null;
      _imageBytes = null;
      _imageFileName = null;
    });
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Pick image from gallery
 // For picking images
Future<void> _pickImage() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Adjust quality as needed
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFileName = image.name;
      });
    }
  } catch (e) {
    _showErrorSnackBar('Error picking image: $e');
  }
}

  // Save event (add or update)
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload image if selected
      String? imageUrl = _imageUrl;
    // In your blog or event form
if (_imageBytes != null && _imageFileName != null) {
  final uploadResponse = await ApiService.uploadBlogImage(_imageBytes!, _imageFileName!);
  if (uploadResponse['success'] == true) {
    imageUrl = uploadResponse['image_url'];
  } else {
    throw Exception('Failed to upload image');
  }
}

      // Prepare event data
      final eventData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'category': _categoryController.text,
        'event_status': 'UPCOMING', // Default status
        'organizer': '1', // Default organizer ID
      };

      if (imageUrl != null) {
        eventData['image_url'] = imageUrl;
      }

      // Add or update event
      if (eventToEdit != null) {
        // Update existing event
        eventData['event_id'] = eventToEdit!['event_id'];
        final updateResponse = await ApiService.updateEvent(eventData);
        if (updateResponse['success'] == true) {
          _showSuccessSnackBar('Event updated successfully');
        } else {
          throw Exception('Failed to update event');
        }
      } else {
        // Add new event
        final addResponse = await ApiService.addEvent(eventData);
        if (addResponse['success'] == true) {
          _showSuccessSnackBar('Event added successfully');
        } else {
          throw Exception('Failed to add event');
        }
      }

      // Reset form and reload events
      setState(() {
        showAddForm = false;
        eventToEdit = null;
        _imageBytes = null;
        _imageFileName = null;
      });
      
      await _loadEvents();
    } catch (e) {
      _showErrorSnackBar('Error saving event: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete event
  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.deleteEvent(eventId);
      if (response['success'] == true) {
        _showSuccessSnackBar('Event deleted successfully');
        await _loadEvents();
      } else {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting event: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Confirm delete dialog
  Future<void> _confirmDeleteEvent(String eventId, String eventTitle) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$eventTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(eventId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        iconTheme: const IconThemeData(color: Color(0xFFFF5A89)),
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(40),
                ),
                height: 45,
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black54,
              child: Icon(Icons.person, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 15),
            Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.black87, size: 35),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFF9DB9),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Image.asset(
                  'assets/public/tarakabataanlogo2.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _SidebarButton(
                        icon: Icons.article_outlined,
                        label: 'Blogs',
                        onTap: () => _navigateTo(context, const BlogsPage()),
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.event_outlined,
                        label: 'Events',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => _navigateTo(context, const SettingsPage()),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 30),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Bogart',
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EVENTS',
                      style: TextStyle(
                        fontFamily: 'Bogart',
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddEditForm(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A3FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Showing',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    _pillButton(
                      child: const Row(
                        children: [
                          Text('10', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    _pillButton(
                      child: const Row(
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Filter', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    _pillButton(
                      child: const Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Select', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : events == null || events!.isEmpty
                          ? const Center(child: Text('No events found.'))
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 10,
                                  headingRowHeight: 56,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 60,
                                  dividerThickness: 0,
                                  showCheckboxColumn: false,
                                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                                  border: TableBorder(
                                    horizontalInside: BorderSide.none,
                                    top: BorderSide.none,
                                    bottom: BorderSide.none,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                  rows: events!.map((event) {
                                    return DataRow(
                                      onSelectChanged: (_) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              backgroundColor: const Color(0xFFFFF6F6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              contentPadding: const EdgeInsets.all(24),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (event['image_url'] != null && event['image_url'].toString().isNotEmpty)
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.network(
                                                          '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/events-images/${event['image_url'].toString().split('/').last}',
                                                          height: 180,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              height: 180,
                                                              width: double.infinity,
                                                              color: Colors.grey[300],
                                                              alignment: Alignment.center,
                                                              child: const Text('Image not available'),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      "Title: ${event['title'] ?? 'N/A'}",
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text("Category: ${event['category'] ?? 'N/A'}"),
                                                    Text("Status: ${event['event_status'] ?? 'N/A'}"),
                                                    Text("Date: ${formatDate(event['created_at'] ?? '')}"),
                                                    const SizedBox(height: 8),
                                                    const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    HtmlWidget(
                                                      event['content'] ?? 'No content.',
                                                      baseUrl: Uri.parse(ApiService.baseUrl),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text("Close"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _showAddEditForm(event: event);
                                                  },
                                                  child: const Text("Edit"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _confirmDeleteEvent(event['event_id'], event['title']);
                                                  },
                                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      cells: [
                                        DataCell(SizedBox(width: 60, child: Text(event['category'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFFFF5A89))))),
                                        DataCell(SizedBox(width: 80, child: Text(event['title'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)))),
                                        DataCell(SizedBox(width: 60, child: Text(event['event_status'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)))),
                                        DataCell(SizedBox(width: 60, child: Text(formatDate(event['created_at'] ?? ''), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)))),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                                onPressed: () => _showAddEditForm(event: event),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                onPressed: () => _confirmDeleteEvent(event['event_id'], event['title']),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
          
          // Add/Edit Form Overlay
          if (showAddForm)
            Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventToEdit != null ? 'Edit Event' : 'Add New Event',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Content',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter content';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text('Image:', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Choose Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A3FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_imageBytes != null)
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          else if (_imageUrl != null)
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.network(
                                '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/events-images/${_imageUrl!.toString().split('/').last}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: const Text('Image not available'),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _cancelAddEdit,
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: _saveEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A3FF),
                                ),
                                child: Text(eventToEdit != null ? 'Update' : 'Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black26,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _pillButton({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 35),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Bogart',
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}