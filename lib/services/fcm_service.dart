import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// FcmService — sends real FCM push notifications from the admin panel
/// via the FCM HTTP v1 API using a service account JWT.
///
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// ONE-TIME SETUP (required to make push notifications work):
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 1. Open Firebase Console → bgmi-tournamentor → Project Settings →
///    Service Accounts tab
/// 2. Click "Generate new private key" and confirm
/// 3. A JSON file is downloaded. Open it and copy:
///    - "private_key_id"  → paste into [_privateKeyId]
///    - "private_key"     → paste the entire -----BEGIN...END----- block into
///      [_privateKey] (keep the \n characters as actual newlines)
/// ─────────────────────────────────────────────────────────────────────────────

class FcmService {
  static const String _projectId   = 'bgmi-tournamentor';
  static const String _clientEmail =
      'firebase-adminsdk-fbsvc@bgmi-tournamentor.iam.gserviceaccount.com';

  // ─── PASTE YOUR SERVICE ACCOUNT KEY HERE ─────────────────────────────────
  // Get this from Firebase Console → Project Settings → Service Accounts →
  // Generate new private key → open the downloaded JSON → copy "private_key"
  static const String _privateKey = '''
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDSLcLdPq1EJ/7T
cr0jOdabZ1WV+6s89qPqrjoraucV1Fedat9xjAXHYyvOFDRwq5NfWQtQIdpvYfeP
edE1k9BoqToc+u/9Wo89JoPq2fP8lG8H1N/N1C+nhsMJcsJgeVZOK85/hk/3ZcFr
L/ftPhHevzBwGfiM+wGKCx6LAwE5qUf11X30+Q5X8ClnIUHKeA9v273RT9u8mlhJ
bwREENG3hoW7igXWiBRmhm1ZjQGx/TpIznq9h9LKbWRjg0k4q9qb9QkarhiSENJS
w2s7NCt9ybUoi3rCuN+Tpp9XggxuMnc45KCxCD525F4LFxnMdLfAeJxapTh1ouab
S/d7nsphAgMBAAECggEAAV1oIchTeeDtR0v7F2GViQ7nSGNCOBMNAYFpR3xkQs/G
ap4LsaWFEqYOmIMmUqk7RurN6akwcW5bWv+vDTaNpv7MOzCYnP07rPt75frxbSxK
icz2tyKCUzSOilTymV62zaaA17qDBjNOW6fPPSeu0FLVkmtjSD7hbQC9f/4A/ozu
kYW0pn9ClmpLvLLCSTGyyI72fXTnp3Isa4xYZXw/xzBD/PgtrJq2KBX4ISj8AQc6
8D3EgZoLfWf31vUUVYIHqHGq8RCQ3Y3BFllbI0fWy9DxgvSYY4oVkJUtaJ9Arz+u
N6on0EKZWfbARcP5YkMv+DrJ6PfJAO659EK+RScCwwKBgQDsjxoLSH/GNLMIEqXs
t1vGBeGxzsvUl++2MwzJuaMPefVbIWbqUylaum1Yn3errb0VePlcSsXGrCObhc1d
a2plBxutzLSVGAc4jDYyjBaOG9kNX/LLVudCtVSYWRUD2LNF2eovFkLT8kNMn7z/
3wB/bhNR+TqFwgoynwRp+XkMuwKBgQDjc6cuvPgcDs3vwsSvaQLFxjxoG1du0jmC
+yJuoG8T5RiY/NLW3rN6UAQT3OXT8tLnQJFQkxEhEwr6c7OdOBTHQZnaqS4CYOQ+
HmGmlHkEAGb9VZQNGSsGE4/5LIkBJgWvUF7GEvQwP7AmB6mSDXHdQHrELTm/zdcz
6q4CVxNBkwKBgCY229M0zAdd3goQ0SMTX8z2iEYsDPtz6/J3/rnbtj66yesF01VJ
R+XzNdTaNf/S2jfMyiOhpJ96kWn/THSp9I8LfeoupoFrV0dIRz0VKlOcpgymElfM
2yEIn/jYcy+i4xsGn/EpXHRWr46CQ4rmIHN1ecOFSnHvLayNya3A8lAfAoGARthW
IYOwkCS4Vk7HLo+50lpdpFunzxfh2/9XCTglgP/hun09OrohEx7rNjieyXaf5HHD
EWLNegzRZZM2Reka57lyL550ez8suICED/u8+dcaPRwzwiSttvXO6WDKx7XNHX8e
Ffn/XyvnNOE8GwbfCXg1BPfFPg3iUwRs8MOodssCgYAcfh92tBViczQUnakpsWDz
T/IxugzU2rWQ0YUr6p6/czmbkV/CufNUS76fnuqq13oZzyWX+CL/ZhYPjLhy5NK7
3dQZCs+jykjhbRPEsLxbYuZp1gvCk/jcCk2AojCjLvOHp6mnrME8S3Yy/EF+fNTc
WcV2cGEb7xpdUIHUXC+R0g==
-----END PRIVATE KEY-----''';
  // ──────────────────────────────────────────────────────────────────────────

  static bool get isConfigured =>
      _privateKey.contains('-----BEGIN PRIVATE KEY-----') &&
      !_privateKey.contains('PASTE_YOUR_PRIVATE_KEY_HERE');

  static const String _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  static const String _tokenEndpoint =
      'https://oauth2.googleapis.com/token';
  static const String _scope =
      'https://www.googleapis.com/auth/firebase.messaging';

  /// Sends an FCM push to the `all_users` topic (all devices that have the app).
  static Future<void> sendToAllUsers({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Push notifications not configured: open lib/services/fcm_service.dart '
        'and paste your Firebase service account private key into _privateKey.',
      );
    }

    final accessToken = await _getAccessToken();

    final response = await http.post(
      Uri.parse(_fcmEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          'topic': 'all_users',
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'bgmi_tournament_channel',
              'color': '#F47B25',
              'sound': 'default',
              'notification_priority': 'PRIORITY_MAX',
              'default_vibrate_timings': true,
            },
          },
          'data': {
            'type': type,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'FCM returned ${response.statusCode}: ${response.body}');
    }
  }

  /// Build a signed JWT and exchange it for a short-lived OAuth2 access token.
  static Future<String> _getAccessToken() async {
    final now = DateTime.now();

    // Build and sign the JWT using RSA-SHA256
    final jwt = JWT(
      {
        'iss': _clientEmail,
        'scope': _scope,
        'aud': _tokenEndpoint,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      },
    );

    final token = jwt.sign(
      RSAPrivateKey(_privateKey),
      algorithm: JWTAlgorithm.RS256,
    );

    // Exchange the signed JWT for an access token
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': token,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Token exchange failed (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body)['access_token'] as String;
  }
}
