extension StringFormattingExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String capitalizeFirstOfEachWord() {
    if (isEmpty) return this;
    // First, handle camelCase by inserting spaces before capital letters
    String spacedString = replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => ' ${match.group(0)}');
    return spacedString.split(' ').map((str) => str.capitalizeFirst()).join(' ');
  }
}