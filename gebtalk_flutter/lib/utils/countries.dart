class Country {
  final String name;
  final String code; // dialing code, e.g., "+94"
  final String flag; // flag emoji, e.g., "🇱🇰"
  final String formatPlaceholder;
  final String regexPattern;

  const Country({
    required this.name,
    required this.code,
    required this.flag,
    required this.formatPlaceholder,
    required this.regexPattern,
  });
}

class Countries {
  static const List<Country> list = [
    Country(
      name: "Sri Lanka",
      code: "+94",
      flag: "🇱🇰",
      formatPlaceholder: "77 123 4567",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "India",
      code: "+91",
      flag: "🇮🇳",
      formatPlaceholder: "99999 99999",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "United States",
      code: "+1",
      flag: "🇺🇸",
      formatPlaceholder: "(999) 999-9999",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "United Kingdom",
      code: "+44",
      flag: "🇬🇧",
      formatPlaceholder: "7911 123456",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "Canada",
      code: "+1",
      flag: "🇨🇦",
      formatPlaceholder: "(999) 999-9999",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "Australia",
      code: "+61",
      flag: "🇦🇺",
      formatPlaceholder: "412 345 678",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "Singapore",
      code: "+65",
      flag: "🇸🇬",
      formatPlaceholder: "8123 4567",
      regexPattern: r"^[0-9]{8}$",
    ),
    Country(
      name: "Malaysia",
      code: "+60",
      flag: "🇲🇾",
      formatPlaceholder: "12-345 6789",
      regexPattern: r"^[0-9]{9,10}$",
    ),
    Country(
      name: "United Arab Emirates",
      code: "+971",
      flag: "🇦🇪",
      formatPlaceholder: "50 123 4567",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "Saudi Arabia",
      code: "+966",
      flag: "🇸🇦",
      formatPlaceholder: "50 123 4567",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "Pakistan",
      code: "+92",
      flag: "🇵🇰",
      formatPlaceholder: "300 1234567",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "Bangladesh",
      code: "+880",
      flag: "🇧🇩",
      formatPlaceholder: "1712 345678",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "Maldives",
      code: "+960",
      flag: "🇲🇻",
      formatPlaceholder: "771 2345",
      regexPattern: r"^[0-9]{7}$",
    ),
    Country(
      name: "Nepal",
      code: "+977",
      flag: "🇳🇵",
      formatPlaceholder: "985 1012345",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "Germany",
      code: "+49",
      flag: "🇩🇪",
      formatPlaceholder: "170 1234567",
      regexPattern: r"^[0-9]{10,11}$",
    ),
    Country(
      name: "France",
      code: "+33",
      flag: "🇫🇷",
      formatPlaceholder: "6 12 34 56 78",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "Japan",
      code: "+81",
      flag: "🇯🇵",
      formatPlaceholder: "90 1234 5678",
      regexPattern: r"^[0-9]{10}$",
    ),
    Country(
      name: "China",
      code: "+86",
      flag: "🇨🇳",
      formatPlaceholder: "139 1234 5678",
      regexPattern: r"^[0-9]{11}$",
    ),
    Country(
      name: "Brazil",
      code: "+55",
      flag: "🇧🇷",
      formatPlaceholder: "11 91234-5678",
      regexPattern: r"^[0-9]{10,11}$",
    ),
    Country(
      name: "South Africa",
      code: "+27",
      flag: "🇿🇦",
      formatPlaceholder: "82 123 4567",
      regexPattern: r"^[0-9]{9}$",
    ),
    Country(
      name: "New Zealand",
      code: "+64",
      flag: "🇳🇿",
      formatPlaceholder: "21 123 4567",
      regexPattern: r"^[0-9]{8,10}$",
    ),
  ];

  static Country getByIsoOrCode(String codeOrName) {
    return list.firstWhere(
      (c) => c.code == codeOrName || c.name.toLowerCase() == codeOrName.toLowerCase(),
      orElse: () => list.firstWhere((c) => c.code == "+1"), // Default to US
    );
  }

  // Format local numbers based on country code
  static String formatNumber(String text, Country country) {
    // Strip non-digits
    final digits = text.replaceAll(RegExp(r'\D'), '');
    
    if (country.code == "+94") { // Sri Lanka: XX XXX XXXX
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) return "${digits.substring(0, 2)} ${digits.substring(2)}";
      return "${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, _min(9, digits.length))}";
    }
    if (country.code == "+91") { // India: XXXXX XXXXX
      if (digits.length <= 5) return digits;
      return "${digits.substring(0, 5)} ${digits.substring(5, _min(10, digits.length))}";
    }
    if (country.code == "+1") { // US/Canada: (XXX) XXX-XXXX
      if (digits.isEmpty) return "";
      if (digits.length <= 3) return "($digits";
      if (digits.length <= 6) return "(${digits.substring(0, 3)}) ${digits.substring(3)}";
      return "(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, _min(10, digits.length))}";
    }
    if (country.code == "+44") { // UK: XXXX XXXXXX
      if (digits.length <= 4) return digits;
      return "${digits.substring(0, 4)} ${digits.substring(4, _min(10, digits.length))}";
    }
    if (country.code == "+61") { // Australia: XXX XXX XXX
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) return "${digits.substring(0, 3)} ${digits.substring(3)}";
      return "${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, _min(9, digits.length))}";
    }
    
    return digits;
  }
  
  static int _min(int a, int b) => a < b ? a : b;
}
