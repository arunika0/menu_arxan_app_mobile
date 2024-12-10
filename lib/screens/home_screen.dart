// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';  // Add this import
import '../models/menu_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      menuProvider.updateToken(token);
      categoryProvider.updateToken(token);

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

  int? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    List<MenuItem> menuItems = selectedCategoryId == null
        ? menuProvider.menuItems
        : menuProvider.menuItems
            .where((item) => item.categoryId == selectedCategoryId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Our Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categoryProvider.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text('All'),
                      selected: selectedCategoryId == null,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedCategoryId = null;
                        });
                      },
                    ),
                  );
                }
                final category = categoryProvider.categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategoryId == category.id,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategoryId = selected ? category.id : null;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Menu Items
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: menuItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? 2
                        : 3,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image), // Use a placeholder when imageUrl is null
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: Text(
                          'Rp${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        child: Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
