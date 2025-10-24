/// Environment configuration for the app
enum Environment { production, uat }

/// Environment configuration class
class EnvironmentConfig {
  final Environment environment;
  final String protocol;
  final String serverIp;
  final String port;
  final String name;

  const EnvironmentConfig({
    required this.environment,
    required this.protocol,
    required this.serverIp,
    required this.port,
    required this.name,
  });

  /// Get base URL for the current environment
  String get baseUrl => '$protocol://$serverIp:$port';

  /// Production environment configuration
  static const EnvironmentConfig production = EnvironmentConfig(
    environment: Environment.production,
    protocol: 'https',
    serverIp: '13.126.34.62',
    port: '3030',
    name: 'Production',
  );

  /// UAT environment configuration
  static const EnvironmentConfig uat = EnvironmentConfig(
    environment: Environment.uat,
    protocol: 'http',
    serverIp: '13.126.34.62',
    port: '3032',
    name: 'UAT',
  );

  /// Get current environment configuration
  /// This can be changed based on build flavor or runtime configuration
  static EnvironmentConfig get current {
    // TODO: Change this to switch between environments
    // For now, defaulting to UAT
    return uat;

    // To use Production, change to:
    // return production;
  }

  @override
  String toString() {
    return 'Environment: $name\n'
        'Base URL: $baseUrl\n'
        'Protocol: $protocol\n'
        'Server IP: $serverIp\n'
        'Port: $port';
  }
}
