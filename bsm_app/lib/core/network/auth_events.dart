import 'dart:async';

 
class AuthEvents {
  
  static final _controller = StreamController<void>.broadcast();

  
  static Stream<void> get onUnauthorized => _controller.stream;

  
  static void emitUnauthorized() => _controller.add(null);
}