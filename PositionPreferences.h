#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>

static NSString *const TDPreferenceDomain = @"com.551.topdownnotifications16";
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
