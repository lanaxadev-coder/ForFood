// ============================================================
// ADD/EDIT MENU ITEM VIEW — FIXED (CREATE + EDIT MODE)
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';

import 'package:forfood/models/menu_item_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/menu/menu_bloc.dart';
import 'package:forfood/service/menu/menu_event.dart';
import 'package:forfood/service/menu/menu_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';

class AddMenuItemView extends StatefulWidget {
  final MenuItemModel? editItem;

  const AddMenuItemView({super.key, this.editItem});

  @override
  State<AddMenuItemView> createState() => _AddMenuItemViewState();
}

class _AddMenuItemViewState extends State<AddMenuItemView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();

  int _currentIndex = 0;
  bool _isSaving = false;
  File? _selectedImage;
  String? _restaurantId;

  // ✅ FIXED: Pre-fill fields when editing
  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _nameController.text = widget.editItem!.name;
      _priceController.text = widget.editItem!.price.toStringAsFixed(2);
    }
    _fetchRestaurantId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Fetch actual restaurant ID
  void _fetchRestaurantId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ✅ FIXED: Single save handler for both create and edit
  Future<void> _handleSaveItem() async {
    final name = _nameController.text.trim();
    final priceString = _priceController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name is required')),
      );
      return;
    }

    final price = double.tryParse(priceString);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save menu items')),
      );
      return;
    }
       if (widget.editItem == null) {
    final menuState = context.read<MenuBloc>().state;
    final currentCount = menuState is MenuStateLoaded
        ? menuState.menuItems.length
        : 0;

    if (currentCount >= 35) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Free plan limit reached (35 items). Upgrade to add more.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
  }
    setState(() => _isSaving = true);

    try {
      String? imageUrl = widget.editItem?.imageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        imageUrl = await _firestoreProvider.uploadImage(
          file: _selectedImage!,
          path: 'menu_items/${authState.user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (widget.editItem != null) {
        // ✅ UPDATE existing item
        final updatedItem = widget.editItem!.copyWith(
          name: name,
          price: price,
          imageUrl: imageUrl,
        );
        context.read<MenuBloc>().add(MenuEventUpdateItem(menuItem: updatedItem));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // ✅ CREATE new item
        final menuItem = MenuItemModel(
          id: '',
          restaurantId: _restaurantId ?? authState.user.id,
          name: name,
          price: price,
          description: null,
          imageUrl: imageUrl,
          orderCount: 0,
          createdAt: DateTime.now(),
        );
        context.read<MenuBloc>().add(MenuEventAddItem(menuItem: menuItem));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      setState(() => _isSaving = false);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $e')),
        );
      }
    }
  }

  // ✅ FIXED: Bottom nav navigation
 void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(tabRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(tabRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        tabRoute(const ProfileViewRestaurant()),
      );
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    final isEditing = widget.editItem != null;

    return BlocListener<MenuBloc, MenuState>(
      listener: (context, state) {
        if (state is MenuStateError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String restaurantName = '';
          String restaurantEmail = '';
          String? profileImageUrl;

          if (authState is AuthStateLoggedIn) {
            restaurantName = authState.user.fullName;
            restaurantEmail = authState.user.email;
            profileImageUrl = authState.user.profileImageUrl;
          }

          return BlocBuilder<RestaurantBloc, RestaurantState>(
            builder: (context, restaurantState) {
              if (restaurantState is RestaurantStateLoaded) {
                restaurantName = restaurantState.restaurant.name;
                if (_restaurantId != restaurantState.restaurant.id) {
                  _restaurantId = restaurantState.restaurant.id;
                }
              }

              return GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  child:  Scaffold(
                endDrawer: buildRestaurantDrawer(
                  name: restaurantName,
                  email: restaurantEmail,
                  profileImageUrl: profileImageUrl,
                ),
                body: Container(
                  width: screenWidth,
                  height: screenHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF5CB58),
                    shape: RoundedRectangleBorder(
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 163 * heightScale,
                        child: Container(
                          width: screenWidth,
                          height: screenHeight - (163 * heightScale),
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ✅ Dynamic title
                      Positioned(
                        top: 75 * heightScale,
                        left: isEditing ? 125 * widthScale : 141 * widthScale,
                        child: Text(
                          isEditing ? 'Edit Item' : 'New Item',
                          style: TextStyle(
                            color: AppColor.nearWhite,
                            fontSize: 28 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 35 * widthScale,
                        top: 84 * heightScale,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            'assets/icons/BackiconArrow.png',
                            width: 20 * widthScale,
                            height: 20 * heightScale,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      Positioned(
                        left: 0,
                        right: 0,
                        top: 160 * heightScale,
                        bottom: 0,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20 * widthScale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 30 * heightScale),

                              // Image picker with preview
                              Center(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 151 * widthScale,
                                    height: 141 * heightScale,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 148, 143, 142),
                                      border: Border.all(
                                        color: AppColor.black,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(21),
                                      image: _selectedImage != null
                                          ? DecorationImage(
                                              image: FileImage(_selectedImage!),
                                              fit: BoxFit.cover,
                                            )
                                          : widget.editItem?.imageUrl != null
                                              ? DecorationImage(
                                                  image: NetworkImage(widget.editItem!.imageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                    ),
                                    child: (_selectedImage == null &&
                                            (widget.editItem?.imageUrl == null ||
                                                widget.editItem!.imageUrl!.isEmpty))
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '+',
                                                style: TextStyle(
                                                  color: AppColor.textDark,
                                                  fontSize: 40 * widthScale,
                                                  fontFamily: 'League Spartan',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 8 * heightScale),
                                              Text(
                                                'add image',
                                                style: TextStyle(
                                                  color: AppColor.textDark,
                                                  fontSize: 18 * widthScale,
                                                  fontFamily: 'League Spartan',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              ),

                              SizedBox(height: 30 * heightScale),

                              // Item Name
                              Row(
                                children: [
                                  Text(
                                    'Item Name',
                                    style: TextStyle(
                                      color: AppColor.textDark,
                                      fontSize: 20 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 20 * widthScale),
                                  Expanded(
                                    child: Container(
                                      height: 45 * heightScale,
                                      decoration: BoxDecoration(
                                        color: AppColor.yellow2,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: TextField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          hintText: 'e.g. pizza, burger, tacos..',
                                          hintStyle: TextStyle(
                                            color: AppColor.textDark,
                                            fontSize: 14 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w300,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16 * widthScale,
                                            vertical: 12 * heightScale,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 35 * heightScale),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: AppColor.divider,
                              ),
                              SizedBox(height: 35 * heightScale),

                              // Price
                              Row(
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      color: AppColor.textDark,
                                      fontSize: 20 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 75 * widthScale),
                                  Expanded(
                                    child: Container(
                                      height: 45 * heightScale,
                                      decoration: BoxDecoration(
                                        color: AppColor.yellow2,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: TextField(
                                        controller: _priceController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: 'e.g 10 \$',
                                          hintStyle: TextStyle(
                                            color: AppColor.textDark,
                                            fontSize: 14 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w300,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16 * widthScale,
                                            vertical: 12 * heightScale,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 110 * heightScale),

                              // ✅ Dynamic button text
                              Center(
                                child: GestureDetector(
                                  onTap: _isSaving ? null : _handleSaveItem,
                                  child: Container(
                                    width: 157 * widthScale,
                                    height: 38 * heightScale,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _isSaving ? AppColor.gray : AppColor.orange,
                                      border: Border.all(color: AppColor.orange, width: 1),
                                      borderRadius: BorderRadius.circular(51.57),
                                    ),
                                    child: _isSaving
                                        ? SizedBox(
                                            width: 24 * widthScale,
                                            height: 24 * heightScale,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            isEditing ? 'Update' : 'Add',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 23 * widthScale,
                                              fontFamily: 'League Spartan',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20 * heightScale),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: BottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: _handleBottomNavTap,
                    isRestaurant: true,  // ✅ ADD THIS

                ),
              ));
            },
          );
        },
      ),
    );
  }
}