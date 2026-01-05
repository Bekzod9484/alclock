import 'dart:math';

/// Math Equation Generator for PLAN HARD mode
/// 
/// Generates equations of type:
/// - x + A = B
/// - x − A = B
/// 
/// Rules:
/// - x value range: 10–99
/// - A range: 10–50
/// - Result B must be positive
/// - Only ONE operation (+ or −)
/// - Answer must always be an integer
class MathEquationGenerator {
  static final Random _random = Random();

  /// Generate a random math equation
  /// 
  /// Returns a tuple: (equation text, correct answer)
  static ({String equation, int answer}) generate() {
    // Randomly choose addition or subtraction
    final isAddition = _random.nextBool();
    
    if (isAddition) {
      return _generateAddition();
    } else {
      return _generateSubtraction();
    }
  }

  /// Generate addition equation: x + A = B
  static ({String equation, int answer}) _generateAddition() {
    // x range: 10–99
    final x = 10 + _random.nextInt(90); // 10 to 99
    
    // A range: 10–50
    final a = 10 + _random.nextInt(41); // 10 to 50
    
    // B = x + A (always positive)
    final b = x + a;
    
    return (
      equation: 'x + $a = $b',
      answer: x,
    );
  }

  /// Generate subtraction equation: x − A = B
  static ({String equation, int answer}) _generateSubtraction() {
    // x range: 10–99
    final x = 10 + _random.nextInt(90); // 10 to 99
    
    // A range: 10–50
    final a = 10 + _random.nextInt(41); // 10 to 50
    
    // B = x − A (must be positive)
    final b = x - a;
    
    // Ensure B is positive (if not, regenerate)
    if (b <= 0) {
      // Adjust: make sure x is large enough
      final minX = a + 1; // x must be at least a + 1
      final adjustedX = minX + _random.nextInt(99 - minX + 1);
      final adjustedB = adjustedX - a;
      
      return (
        equation: 'x − $a = $adjustedB',
        answer: adjustedX,
      );
    }
    
    return (
      equation: 'x − $a = $b',
      answer: x,
    );
  }
}


