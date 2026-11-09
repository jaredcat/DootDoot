import 'package:google_fonts/google_fonts.dart';

/// Call from test `main()` so theme construction does not hit the network.
void configureDesignForTests() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
