import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'events.dart';
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

class BlogsPage extends StatefulWidget {
  const BlogsPage({super.key});

  @override
  State<BlogsPage> createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  List<Map<String, dynamic>>? blogs;
  List<Map<String, dynamic>>? users;
  
 String authorInput = '';
  String? selectedBlogStatus = 'PUBLISHED';
  bool isLoading = true;
  bool showAddForm = false;
  Map<String, dynamic>? blogToEdit;
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
    _loadBlogs();
    _loadUsers();
    
  }
Future<void> _loadUsers() async {
  try {
    // Just hardcoding user ID 1 as default for now since we don't have a user list API
    setState(() {
  authorInput = '';
});
    
    // In a real implementation, you'd fetch users from an API
    // final response = await ApiService.getUsers();
    // setState(() {
    //   users = List<Map<String, dynamic>>.from(response['users']);
    // });
  } catch (e) {
    _showErrorSnackBar('Error loading users: $e');
  }
}
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Load blogs from the API
  Future<void> _loadBlogs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getBlogs();
      setState(() {
        blogs = List<Map<String, dynamic>>.from(response['blogs']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error loading blogs: $e');
    }
  }

  // Show add/edit form
  void _showAddEditForm({Map<String, dynamic>? blog}) {
  setState(() {
    showAddForm = true;
    blogToEdit = blog;
    
    if (blog != null) {
      // Populate form with blog data
      _titleController.text = blog['title'] ?? '';
      _contentController.text = blog['content'] ?? '';
      _categoryController.text = blog['category'] ?? '';
      _imageUrl = blog['image_url'];
      authorInput = blog['author'] ?? '';
      selectedBlogStatus = blog['blog_status'] ?? 'PUBLISHED';
    } else {
      // Clear form for new blog
      _titleController.clear();
      _contentController.clear();
      _categoryController.clear();
      _imageUrl = null;
      authorInput = ''; // Changed from selectedAuthorId = '1'
      selectedBlogStatus = 'PUBLISHED';
    }
    
    _imageBytes = null;
    _imageFileName = null;
  });
}
  // Cancel add/edit form
  void _cancelAddEdit() {
    setState(() {
      showAddForm = false;
      blogToEdit = null;
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

  // Save blog (add or update)
// Replace your current _saveBlog method with this one
Future<void> _saveBlog() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  print('Starting to save blog'); // Debug log
  setState(() {
    isLoading = true;
  });

  try {
    // Upload image if selected
    String? imageUrl = _imageUrl;
    
    if (_imageBytes != null && _imageFileName != null) {
      print('Uploading image: $_imageFileName (${_imageBytes!.length} bytes)'); // Debug log
      
      try {
        final uploadResponse = await ApiService.uploadBlogImage(_imageBytes!, _imageFileName!);
        print('Image upload response: $uploadResponse'); // Debug log
        
        if (uploadResponse['success'] == true) {
          imageUrl = uploadResponse['image_url'];
          print('Image uploaded successfully: $imageUrl'); // Debug log
        } else {
          print('Image upload failed: ${uploadResponse['error']}'); // Debug log
          throw Exception('Failed to upload image: ${uploadResponse['error']}');
        }
      } catch (e) {
        print('Exception during image upload: $e'); // Debug log
        _showErrorSnackBar('Error uploading image: $e');
        setState(() {
          isLoading = false;
        });
        return; // Exit the method if image upload fails
      }
    } else {
      print('No new image to upload, using existing image: $imageUrl'); // Debug log
    }

    // Prepare blog data with fixed values
    final blogData = {
      'title': _titleController.text,
      'content': _contentController.text,
      'category': _categoryController.text,
      'blog_status': selectedBlogStatus,
      'author': authorInput, // Using text input instead of ID
    };

    // Only include image_url if it's not null
    if (imageUrl != null && imageUrl.isNotEmpty) {
      blogData['image_url'] = imageUrl;
    }

    print('Blog data to save: $blogData'); // Debug log

    // Add or update blog
    if (blogToEdit != null) {
      // Ensure we have the correct blog_id format
      final String blogId = blogToEdit!['blog_id'];
      
      // Log the exact blog_id being used
      print('Updating blog with ID: $blogId'); // Debug log
      blogData['blog_id'] = blogId;
      
      try {
        final updateResponse = await ApiService.updateBlog(blogData);
        print('Update response: $updateResponse'); // Debug log
        
        if (updateResponse['success'] == true) {
          _showSuccessSnackBar('Blog updated successfully');
          // Reset form and reload blogs
          setState(() {
            showAddForm = false;
            blogToEdit = null;
            _imageBytes = null;
            _imageFileName = null;
          });
          
          await _loadBlogs();
        } else {
          throw Exception('Failed to update blog: ${updateResponse['error'] ?? 'Unknown error'}');
        }
      } catch (e) {
        print('Exception during blog update: $e'); // Debug log
        _showErrorSnackBar('Error updating blog: $e');
      }
    } else {
      // Add new blog logic remains the same
      print('Adding new blog'); // Debug log
      try {
        final addResponse = await ApiService.addBlog(blogData);
        print('Add response: $addResponse'); // Debug log
        
        if (addResponse['success'] == true) {
          _showSuccessSnackBar('Blog added successfully');
          // Reset form and reload blogs
          setState(() {
            showAddForm = false;
            blogToEdit = null;
            _imageBytes = null;
            _imageFileName = null;
          });
          
          await _loadBlogs();
        } else {
          throw Exception('Failed to add blog: ${addResponse['error'] ?? 'Unknown error'}');
        }
      } catch (e) {
        print('Exception during blog addition: $e'); // Debug log
        _showErrorSnackBar('Error adding blog: $e');
      }
    }
  } catch (e) {
    print('General exception in _saveBlog: $e'); // Debug log
    _showErrorSnackBar('Error saving blog: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  // Delete blog
  Future<void> _deleteBlog(String blogId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.deleteBlog(blogId);
      if (response['success'] == true) {
        _showSuccessSnackBar('Blog deleted successfully');
        await _loadBlogs();
      } else {
        throw Exception('Failed to delete blog');
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting blog: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Confirm delete dialog
  Future<void> _confirmDeleteBlog(String blogId, String blogTitle) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$blogTitle"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBlog(blogId);
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
                const Icon(
                  Icons.notifications_none,
                  color: Colors.black87,
                  size: 35,
                ),
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
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 12),
                      _SidebarButton(
                        icon: Icons.event_outlined,
                        label: 'Events',
                        onTap: () => _navigateTo(context, const EventsPage()),
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
                      'BLOGS',
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
                      : blogs == null || blogs!.isEmpty
                          ? const Center(child: Text('No blogs found.'))
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
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  border: TableBorder(
                                    horizontalInside: BorderSide.none,
                                    top: BorderSide.none,
                                    bottom: BorderSide.none,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Category',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Title',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: blogs!.map((blog) {
                                    return DataRow(
                                      onSelectChanged: (_) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              backgroundColor: const Color(
                                                0xFFFFF6F6,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  20,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.all(
                                                24,
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (blog['image_url'] != null && blog['image_url'].toString().isNotEmpty)
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.network(
                                                          '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/blogs-images/${blog['image_url'].toString().split('/').last}',
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
                                                      "Title: ${blog['title'] ?? 'N/A'}",
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text("Category: ${blog['category'] ?? 'N/A'}"),
                                                    Text("Status: ${blog['blog_status'] ?? 'N/A'}"),
                                                    Text("Date: ${formatDate(blog['created_at'] ?? '')}"),
                                                    const SizedBox(height: 8),
                                                    Text("Author: ${blog['author'] ?? 'N/A'}"),
                                                    const SizedBox(height: 8),
                                                    const Text("Content:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 4),
                                                    HtmlWidget(
                                                      blog['content'] ?? 'No content.',
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
                                                    _showAddEditForm(blog: blog);
                                                  },
                                                  child: const Text("Edit"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _confirmDeleteBlog(blog['blog_id'], blog['title']);
                                                  },
                                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              blog['category'] ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFFF5A89),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              blog['title'] ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              blog['blog_status'] ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              formatDate(blog['created_at'] ?? ''),
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                                onPressed: () => _showAddEditForm(blog: blog),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                onPressed: () => _confirmDeleteBlog(blog['blog_id'], blog['title']),
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
                            blogToEdit != null ? 'Edit Blog' : 'Add New Blog',
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
// Author field
TextFormField(
  initialValue: authorInput,
  decoration: const InputDecoration(
    labelText: 'Author',
    border: OutlineInputBorder(),
  ),
  onChanged: (value) {
    setState(() {
      authorInput = value;
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an author';
    }
    return null;
  },
),
const SizedBox(height: 15),
// Blog status field
DropdownButtonFormField<String>(
  value: selectedBlogStatus ?? 'PUBLISHED',
  decoration: const InputDecoration(
    labelText: 'Status',
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem<String>(
      value: 'DRAFT',
      child: Text('Draft'),
    ),
    DropdownMenuItem<String>(
      value: 'PUBLISHED',
      child: Text('Published'),
    ),
    DropdownMenuItem<String>(
      value: 'PINNED',
      child: Text('Pinned'),
    ),
    DropdownMenuItem<String>(
      value: 'ARCHIVED',
      child: Text('Archived'),
    ),
  ],
  onChanged: (value) {
    setState(() {
      selectedBlogStatus = value!;
    });
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
      '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/blogs-images/${_imageUrl!.toString().split('/').last}',
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
                                onPressed: _saveBlog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A3FF),
                                ),
                                child: Text(blogToEdit != null ? 'Update' : 'Save'),
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

void _debugBlogData(BuildContext context, Map<String, dynamic> blog) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Debug Blog Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${blog['blog_id']}'),
              const SizedBox(height: 8),
              Text('Title: ${blog['title']}'),
              const SizedBox(height: 8),
              Text('Category: ${blog['category']}'),
              const SizedBox(height: 8),
              Text('Status: ${blog['blog_status']}'),
              const SizedBox(height: 8),
              Text('Author: ${blog['author']}'),
              const SizedBox(height: 8),
              Text('Image URL: ${blog['image_url']}'),
              const SizedBox(height: 8),
              const Text('Type information:'),
              Text('ID type: ${blog['blog_id'].runtimeType}'),
              Text('Title type: ${blog['title'].runtimeType}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}