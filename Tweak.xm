#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <string.h>

@interface NCNotificationListView : UIScrollView
@property (nonatomic) BOOL layoutFromBottom;
@end

%group TopDownLayout
%hook NCNotificationListView

// Let Apple's list engine compute positions from its native top origin.
// This class is shared by the outer list and nested notification group lists.
// Do not replace layoutSubviews, card frames, transforms or animation code.
- (BOOL)layoutFromBottom {
    return NO;
}

// Keep the backing state consistent when SpringBoard configures a list again.
// Calling the original setter preserves any native invalidation/side effects.
- (void)setLayoutFromBottom:(BOOL)fromBottom {
    %orig(NO);
}

%end
%end

static BOOL TDIsBooleanMethod(Method method, unsigned int arguments) {
    if (!method || method_getNumberOfArguments(method) != arguments) return NO;
    char type[32] = {0};
    if (arguments == 2) method_getReturnType(method, type, sizeof(type));
    else {
        method_getReturnType(method, type, sizeof(type));
        if (strcmp(type, @encode(void)) != 0) return NO;
        method_getArgumentType(method, 2, type, sizeof(type));
    }
    return strcmp(type, @encode(BOOL)) == 0 || strcmp(type, "B") == 0 || strcmp(type, "c") == 0;
}

%ctor {
    @autoreleasepool {
        if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 16) return;
        Class list = objc_getClass("NCNotificationListView");
        Method getter = class_getInstanceMethod(list, @selector(layoutFromBottom));
        Method setter = class_getInstanceMethod(list, @selector(setLayoutFromBottom:));
        if (!TDIsBooleanMethod(getter, 2) || !TDIsBooleanMethod(setter, 3)) {
            NSLog(@"[TopDownNotifications16] Native layout selectors unavailable; leaving layout unchanged.");
            return;
        }
        %init(TopDownLayout);
        NSLog(@"[TopDownNotifications16] Native top-down layout enabled.");
    }
}
