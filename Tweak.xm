#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <string.h>
#import "PositionPreferences.h"

static CGFloat TDOffset = 0;

@interface CSCoverSheetViewController : UIViewController
- (CGFloat)listMinY;
@end

%group FirstNotificationPosition
%hook CSCoverSheetViewController
- (CGFloat)listMinY {
    CGFloat nativeY = %orig;
    if (TDOffset == 0 || !isfinite(nativeY)) return nativeY;
    return MAX(0, nativeY + TDOffset);
}
%end
%end

@interface NCNotificationListView : UIScrollView
@property (nonatomic) BOOL layoutFromBottom;
@end

%group TopDownLayout
%hook NCNotificationListView
- (BOOL)layoutFromBottom {
    return NO;
}
- (void)setLayoutFromBottom:(BOOL)fromBottom {
    %orig(NO);
}
%end
%end

static BOOL TDIsBooleanMethod(Method method, unsigned int arguments) {
    if (!method || method_getNumberOfArguments(method) != arguments) return NO;
    char type[32] = {0};
    method_getReturnType(method, type, sizeof(type));
    if (arguments == 3) {
        if (strcmp(type, @encode(void)) != 0) return NO;
        method_getArgumentType(method, 2, type, sizeof(type));
    }
    return strcmp(type, @encode(BOOL)) == 0 || strcmp(type, "B") == 0 || strcmp(type, "c") == 0;
}

%ctor {
    @autoreleasepool {
        if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 16) return;
        if (!TDReadEnabled()) {
            NSLog(@"[TopDownNotifications16] Disabled in preferences.");
            return;
        }

        Class list = objc_getClass("NCNotificationListView");
        Method getter = class_getInstanceMethod(list, @selector(layoutFromBottom));
        Method setter = class_getInstanceMethod(list, @selector(setLayoutFromBottom:));
        if (!TDIsBooleanMethod(getter, 2) || !TDIsBooleanMethod(setter, 3)) {
            NSLog(@"[TopDownNotifications16] Native layout selectors unavailable; leaving layout unchanged.");
            return;
        }

        %init(TopDownLayout);
        TDOffset = TDReadOffset();

        Method minimumY = class_getInstanceMethod(objc_getClass("CSCoverSheetViewController"), @selector(listMinY));
        char resultType[32] = {0};
        if (minimumY) method_getReturnType(minimumY, resultType, sizeof(resultType));
        if (minimumY && method_getNumberOfArguments(minimumY) == 2 && strcmp(resultType, @encode(CGFloat)) == 0) {
            %init(FirstNotificationPosition);
        }

        NSLog(@"[TopDownNotifications16] Native top-down layout enabled.");
    }
}
