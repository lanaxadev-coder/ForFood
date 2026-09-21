// lib/utils/address_validator.dart

class AddressValidator {
  static bool isValid(String address) {
    if (address.isEmpty) return false;
    if (address.length < 10) return false;
    
    // ✅ Check if it has a number and street
    bool hasNumber = RegExp(r'\d').hasMatch(address);
    bool hasStreet = RegExp(r'(street|st|avenue|ave|road|rd|boulevard|blvd|drive|dr|lane|ln|way|place|pl)',
      caseSensitive: false,
    ).hasMatch(address);
    
    return hasNumber && hasStreet;
  }
}