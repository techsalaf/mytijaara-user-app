class TypeConverterHelper {
  static bool getBool(dynamic value){
    return value == 1 || value == true || value == '1' || value == 'true';
  }

  static double getDouble(dynamic value){
    return num.tryParse(value.toString())?.toDouble() ?? 0.0;
  }

  static int getInt(dynamic value){
    return num.tryParse(value.toString())?.toInt() ?? 0;
  }

  /// 1 => 1 | 1.0 => 1.0 | 1.2 => 1.2 (first priority INT)
  static dynamic getIntOrDouble(dynamic value){
    final res = num.tryParse(value.toString()) ?? 0;
    if(res == res.toInt()){
      return res.toInt();
    }
    return res.toDouble();
  }
}