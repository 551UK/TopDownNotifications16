#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>

static NSString *const TDPreferenceDomain = @"com.551.topdownnotifications16";

static inline BOOL TDReadEnabled(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)TDPreferenceDomain);
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Enabled"), (__bridge CFStringRef)TDPreferenceDomain));
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
}

static inline void TDWriteEnabled(BOOL enabled) {
    NSNumber *value = @(enabled);
    CFPreferencesSetAppValue(CFSTR("Enabled"), (__bridge CFPropertyListRef)value, (__bridge CFStringRef)TDPreferenceDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)TDPreferenceDomain);
}

static inline double TDReadOffset(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)TDPreferenceDomain);
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("FirstNotificationOffset"), (__bridge CFStringRef)TDPreferenceDomain));
    double offset = [value isKindOfClass:NSNumber.class] ? [value doubleValue] : 0;
    return isfinite(offset) ? MAX(-100, MIN(250, offset)) : 0;
}
static inline void TDWriteOffset(double value) {
    if (!isfinite(value)) value = 0;
    NSNumber *offset = @(round(MAX(-100, MIN(250, value))));
    CFPreferencesSetAppValue(CFSTR("FirstNotificationOffset"), (__bridge CFPropertyListRef)offset, (__bridge CFStringRef)TDPreferenceDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)TDPreferenceDomain);
}
