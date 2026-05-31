package dev.bitanon.authenticator

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (instead of FlutterActivity) is required by
// local_auth so the biometric prompt can attach to a FragmentActivity.
class MainActivity : FlutterFragmentActivity()
