abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nearride.ekafy.com/api/v1',
  );

  // This must be the Web OAuth client ID also configured as GOOGLE_CLIENT_ID
  // on the NearRide API. Android uses it as the server client ID for ID tokens.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '597324480079-chs8k6vdpaa4q46cj45qcabm3ndumndn.apps.googleusercontent.com',
  );
}
