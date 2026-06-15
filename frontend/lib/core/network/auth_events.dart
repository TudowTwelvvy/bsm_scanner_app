import 'dart:async';

// AuthEvents is a neutral third party. Dio emits an event.
// AuthRepository listens for that event and reacts.
class AuthEvents {
  // StreamController.broadcast() allows multiple listeners.
  // Single-subscription streams only allow ONE listener, which would break
  // if both AuthRepository and a screen tried to listen.
  static final _controller = StreamController<void>.broadcast();

  // The public stream that other classes listen to.
  // void means "no data, just a signal" — like a doorbell, not a letter.
  static Stream<void> get onUnauthorized => _controller.stream;

  // Called by Dio interceptor when 401 is received.
  static void emitUnauthorized() => _controller.add(null);
}