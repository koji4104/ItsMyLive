//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<apivideo_live_stream/ApiVideoLiveStreamPlugin.h>)
#import <apivideo_live_stream/ApiVideoLiveStreamPlugin.h>
#else
@import apivideo_live_stream;
#endif

#if __has_include(<battery_plus/FLTBatteryPlusPlugin.h>)
#import <battery_plus/FLTBatteryPlusPlugin.h>
#else
@import battery_plus;
#endif

#if __has_include(<camera/CameraPlugin.h>)
#import <camera/CameraPlugin.h>
#else
@import camera;
#endif

#if __has_include(<native_device_orientation/NativeDeviceOrientationPlugin.h>)
#import <native_device_orientation/NativeDeviceOrientationPlugin.h>
#else
@import native_device_orientation;
#endif

#if __has_include(<path_provider_ios/FLTPathProviderPlugin.h>)
#import <path_provider_ios/FLTPathProviderPlugin.h>
#else
@import path_provider_ios;
#endif

#if __has_include(<shared_preferences_ios/FLTSharedPreferencesPlugin.h>)
#import <shared_preferences_ios/FLTSharedPreferencesPlugin.h>
#else
@import shared_preferences_ios;
#endif

#if __has_include(<wakelock/WakelockPlugin.h>)
#import <wakelock/WakelockPlugin.h>
#else
@import wakelock;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [ApiVideoLiveStreamPlugin registerWithRegistrar:[registry registrarForPlugin:@"ApiVideoLiveStreamPlugin"]];
  [FLTBatteryPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTBatteryPlusPlugin"]];
  [CameraPlugin registerWithRegistrar:[registry registrarForPlugin:@"CameraPlugin"]];
  [NativeDeviceOrientationPlugin registerWithRegistrar:[registry registrarForPlugin:@"NativeDeviceOrientationPlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [FLTSharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTSharedPreferencesPlugin"]];
  [WakelockPlugin registerWithRegistrar:[registry registrarForPlugin:@"WakelockPlugin"]];
}

@end
