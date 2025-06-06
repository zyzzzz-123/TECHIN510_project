import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Environments
enum Environment {
  development,
  staging,
  production
}

// Current environment
// This should be changed when building for different environments
const Environment currentEnvironment = Environment.production;

// API URLs for different environments
class Config {
  // Local development URL
  static const String devLocalUrl = 'http://localhost:8000';
  
  // For physical device testing in local network
  // Replace with your computer's hostname when testing on physical devices
  static const String devNetworkUrl = 'http://macbook-pro-307.local:8000';
  
  // Production URL - 在成功部署后，用实际的 Railway URL 替换这里
  // static const String productionUrl = 'https://techin510project-production.up.railway.app';
  static const String productionUrl = 'http://valiant-enjoyment-production-5fba.up.railway.app';


  // Staging URL
  static const String stagingUrl = 'https://staging-api.your-domain.com';
  
  // Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.production:
        return productionUrl;
      case Environment.staging:
        return stagingUrl;
      case Environment.development:
      default:
        // 直接使用电脑的主机名，不管设备类型
        return devNetworkUrl;
    }
  }
}

// Export the baseUrl for backward compatibility
String get baseUrl => Config.baseUrl; 