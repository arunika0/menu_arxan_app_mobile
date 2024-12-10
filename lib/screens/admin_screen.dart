// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';  // Add this import
import '../services/api_service.dart';     // Add this import
import '../models/category.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  String activeTab = 'menu'; // 'menu' atau 'categories'
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // --- Menu Form ---
  Map<String, dynamic> menuForm = {
    'id': null,
    'name': '',
    'price': '',
    'description': '',
    'imageUrl': '',
    'categoryId': null,
  };
  bool isUploading = false;
  String uploadError = '';
  bool isEditingMenu = false;

  // Controllers for Menu Form
  late TextEditingController menuNameController;
  late TextEditingController menuPriceController;
  late TextEditingController menuDescriptionController;

  // --- Category Form ---
  Map<String, dynamic> categoryForm = {
    'id': null,
    'name': '',
  };
  bool isEditingCategory = false;

  // Controllers for Category Form
  late TextEditingController categoryNameController;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Initialize controllers with initial values
    menuNameController = TextEditingController(text: menuForm['name']);
    menuPriceController = TextEditingController(text: menuForm['price'].toString());
    menuDescriptionController = TextEditingController(text: menuForm['description']);
    categoryNameController = TextEditingController(text: categoryForm['name']);
    print('Controllers initialized');
  }

  Future<void> _loadInitialData() async {
    try {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      await Future.wait([
        menuProvider.loadMenuItems(),
        categoryProvider.loadCategories(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    menuNameController.dispose();
    menuPriceController.dispose();
    menuDescriptionController.dispose();
    categoryNameController.dispose();
    super.dispose();
    print('Controllers disposed');
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          print('Image picked: ${pickedFile.path}');
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _handleSubmit(MenuProvider menuProvider) async {
    // Validate form
    if (menuForm['name'].toString().trim().isEmpty ||
        menuForm['price'].toString().trim().isEmpty ||
        menuForm['description'].toString().trim().isEmpty ||
        menuForm['categoryId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        final apiService = ApiService(token: Provider.of<AuthProvider>(context, listen: false).token);
        imageUrl = await apiService.uploadImage(_imageFile!);
      }

      // Create form data
      final formData = {
        'name': menuForm['name'].toString(),
        'price': double.tryParse(menuForm['price'].toString()) ?? 0.0,
        'description': menuForm['description'].toString(),
        'category_id': menuForm['categoryId'],
        'image': imageUrl, // Add the uploaded image URL to form data
      };
      
      print('Submitting form data: $formData');
      
      // Save or update
      if (isEditingMenu) {
        await menuProvider.updateMenuItem(menuForm['id'], formData, _imageFile);
      } else {
        await menuProvider.addMenuItem(formData, _imageFile);
      }

      // Reset form on success
      resetMenuForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu item saved successfully')),
      );
    } catch (e) {
      print('Error in _handleSubmit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving menu item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          children: [
            // Tab Navigation
            Container(
              color: Colors.blue,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          activeTab = 'menu';
                          print('Switched to Manage Menu Tab');
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: activeTab == 'menu'
                                ? BorderSide(color: Colors.white, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Manage Menu',
                            style: TextStyle(
                              color:
                                  activeTab == 'menu' ? Colors.white : Colors.white70,
                              fontWeight:
                                  activeTab == 'menu' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          activeTab = 'categories';
                          print('Switched to Manage Categories Tab');
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: activeTab == 'categories'
                                ? BorderSide(color: Colors.white, width: 2)
                                : BorderSide.none,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Manage Categories',
                            style: TextStyle(
                              color: activeTab == 'categories'
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: activeTab == 'categories'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Tab Content
            activeTab == 'menu' ? buildMenuTab(menuProvider, categoryProvider) : buildCategoryTab(categoryProvider),
          ],
        ),
      ),
    );
  }

  // --- Build Menu Tab ---
  Widget buildMenuTab(MenuProvider menuProvider, CategoryProvider categoryProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Form Add/Edit Menu
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditingMenu ? 'Edit Menu Item' : 'Add New Menu Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    controller: menuNameController,
                    onChanged: (value) {
                      menuForm['name'] = value;
                      print('Menu Name Changed: $value');
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    controller: menuPriceController,
                    onChanged: (value) {
                      menuForm['price'] = double.tryParse(value) ?? 0.0;
                      print('Menu Price Changed: $value');
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Description'),
                    controller: menuDescriptionController,
                    onChanged: (value) {
                      menuForm['description'] = value;
                      print('Menu Description Changed: $value');
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _imageFile != null
                            ? Image.file(_imageFile!, height: 100)
                            : menuForm['imageUrl'] != ''
                                ? Image.network(menuForm['imageUrl'], height: 100)
                                : Text('No Image Selected'),
                      ),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Choose Image'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Category'),
                    value: menuForm['categoryId'],
                    items: categoryProvider.categories
                        .map((cat) => DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        menuForm['categoryId'] = value;
                        print('Category Changed: $value');
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isUploading ? null : () => _handleSubmit(menuProvider),
                    child: isUploading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Saving...'),
                            ],
                          )
                        : Text(isEditingMenu ? 'Update Menu' : 'Add Menu'),
                  ),
                  if (isEditingMenu)
                    TextButton(
                      onPressed: () {
                        resetMenuForm();
                      },
                      child: Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // List Menu Items
          Text(
            'Menu Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: menuProvider.menuItems.length,
            itemBuilder: (context, index) {
              final menu = menuProvider.menuItems[index];
              final category = categoryProvider.categories.firstWhere(
                  (cat) => cat.id == menu.categoryId,
                  orElse: () => Category(id: 0, name: 'Unknown'));
              return Card(
                child: ListTile(
                  leading: menu.imageUrl != null
                      ? Image.network(
                          menu.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image), // Use a placeholder when imageUrl is null
                  title: Text(menu.name),
                  subtitle: Text('${category.name} • Rp${menu.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          print('Edit Menu Item: ${menu.name}');
                          setState(() {
                            isEditingMenu = true;
                            menuForm = {
                              'id': menu.id,
                              'name': menu.name,
                              'price': menu.price,
                              'description': menu.description,
                              'imageUrl': menu.imageUrl,
                              'categoryId': menu.categoryId,
                            };
                            // Update controllers
                            menuNameController.text = menu.name;
                            menuPriceController.text = menu.price.toString();
                            menuDescriptionController.text = menu.description;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          print('Delete Menu Item: ${menu.name}');
                          menuProvider.deleteMenuItem(menu.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Build Category Tab ---
  Widget buildCategoryTab(CategoryProvider categoryProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Form Add/Edit Category
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditingCategory ? 'Edit Category' : 'Add New Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    controller: categoryNameController,
                    onChanged: (value) {
                      categoryForm['name'] = value;
                      print('Category Name Changed: $value');
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('Add/Update Category Button Pressed');
                      if (isEditingCategory) {
                        print('Updating Category');
                        // Update Category
                        categoryProvider.updateCategory(
                          categoryForm['id'],
                          categoryForm['name'],
                        );
                      } else {
                        print('Adding Category');
                        // Add Category
                        categoryProvider.addCategory(categoryForm['name']);
                      }
                      print('Resetting Category Form');
                      resetCategoryForm();
                    },
                    child: Text(isEditingCategory ? 'Update Category' : 'Add Category'),
                  ),
                  if (isEditingCategory)
                    TextButton(
                      onPressed: () {
                        resetCategoryForm();
                      },
                      child: Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // List Categories
          Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          print('Edit Category: ${category.name}');
                          setState(() {
                            isEditingCategory = true;
                            categoryForm = {
                              'id': category.id,
                              'name': category.name,
                            };
                            // Update controller
                            categoryNameController.text = category.name;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          print('Delete Category: ${category.name}');
                          categoryProvider.deleteCategory(category.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Reset Forms ---
  void resetMenuForm() {
    setState(() {
      menuForm = {
        'id': null,
        'name': '',
        'price': '0.0',  // Changed to string
        'description': '',
        'imageUrl': '',
        'categoryId': null,
      };
      isEditingMenu = false;
      isUploading = false;
      uploadError = '';
      // Reset controllers
      menuNameController.text = '';
      menuPriceController.text = '0.0';
      menuDescriptionController.text = '';
      _imageFile = null;
      print('Menu Form Reset');
    });
  }

  void resetCategoryForm() {
    setState(() {
      categoryForm = {
        'id': null,
        'name': '',
      };
      isEditingCategory = false;
      // Reset controller
      categoryNameController.text = '';
      print('Category Form Reset');
    });
  }
}
