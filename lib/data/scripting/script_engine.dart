class ScriptEngine {

  // hard-coded transformation because of QuickJS constraints
  static double transform(int rawValue) {
    
    return rawValue * 0.12 + 34;
  }
}
