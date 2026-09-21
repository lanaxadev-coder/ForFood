// lib/service/language/translations.dart
import 'package:shared_preferences/shared_preferences.dart';

class Translations {
  static String _currentLanguage = 'en';
  
  static String get currentLanguage => _currentLanguage;

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'notification': 'Notification Setting',
      'password': 'Password Setting',
      'darkMode': 'Dark Mode',
      'privacy': 'Privacy Policy',
      'terms': 'Terms of Service',
      'deleteAccount': 'Delete Account',
      'yourMenu': 'Your Menu',
      'gallery': 'Gallery',
      'orders': 'Orders',
      'views': 'Views',
      'welcomeBack': 'Welcome back',
      'goodMorning': 'Good Morning',
      'search': 'Search...',
      'myOrders': 'My Orders',
      'myProfile': 'My Profile',
      'deliveryAddress': 'Delivery Address',
      'contactUs': 'Contact Us',
      'helpFAQs': 'Help & FAQs',
      'logOut': 'Log Out',
    },
    'ar': {
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'notification': 'إعدادات الإشعارات',
      'password': 'إعدادات كلمة المرور',
      'darkMode': 'الوضع الداكن',
      'privacy': 'سياسة الخصوصية',
      'terms': 'شروط الخدمة',
      'deleteAccount': 'حذف الحساب',
      'yourMenu': 'قائمتك',
      'gallery': 'المعرض',
      'orders': 'الطلبات',
      'views': 'المشاهدات',
      'welcomeBack': 'مرحباً بعودتك',
      'goodMorning': 'صباح الخير',
      'search': 'بحث...',
      'myOrders': 'طلباتي',
      'myProfile': 'ملفي الشخصي',
      'deliveryAddress': 'عنوان التوصيل',
      'contactUs': 'اتصل بنا',
      'helpFAQs': 'المساعدة والأسئلة الشائعة',
      'logOut': 'تسجيل الخروج',
    },
    'fr': {
      'settings': 'Paramètres',
      'language': 'Langue',
      'notification': 'Paramètres de notification',
      'password': 'Paramètres du mot de passe',
      'darkMode': 'Mode sombre',
      'privacy': 'Politique de confidentialité',
      'terms': "Conditions d'utilisation",
      'deleteAccount': 'Supprimer le compte',
      'yourMenu': 'Votre menu',
      'gallery': 'Galerie',
      'orders': 'Commandes',
      'views': 'Vues',
      'welcomeBack': 'Bon retour',
      'goodMorning': 'Bonjour',
      'search': 'Rechercher...',
      'myOrders': 'Mes commandes',
      'myProfile': 'Mon profil',
      'deliveryAddress': 'Adresse de livraison',
      'contactUs': 'Contactez-nous',
      'helpFAQs': 'Aide & FAQ',
      'logOut': 'Déconnexion',
    },
  };

  static String t(String key) {
    return _translations[_currentLanguage]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language_code') ?? 'en';
  }

  static Future<void> changeLanguage(String code) async {
    _currentLanguage = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', code);
  }
}