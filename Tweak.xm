#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
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

/*
 * Notification restoration logic adapted from LockScreenRestore's
 * iOS 15 notification section only.
 *
 * MIT License
 * Copyright (c) 2026 aronsz26
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

static const CGFloat kIOS15CardCornerRadius = 13.0;
static const CGFloat kIOS15CardInsetReduction = 4.0;
static const CGFloat kIOS15ListInset = 8.0;
static const CGFloat kIOS16ListInset = 10.0;

@interface NCNotificationShortLookView : UIView
- (CGFloat)_continuousCornerRadius;
- (void)_setContinuousCornerRadius:(CGFloat)radius;
@end

@interface NCNotificationSeamlessContentView : UIView
@end

@interface ACUISSizeDimensionRequest : NSObject
+ (instancetype)fixed:(CGFloat)value;
@property (readonly, nonatomic) CGFloat minimum;
@property (readonly, nonatomic) CGFloat maximum;
@end

@interface ACUISActivityItemMetricsRequest : NSObject <NSCopying>
@property (nonatomic, strong) ACUISSizeDimensionRequest *widthRequest;
@end

@interface ACUISActivityMetricsRequest : NSObject <NSCopying>
@property (nonatomic, copy) ACUISActivityItemMetricsRequest *lockScreenMetrics;
@end

@interface NCNotificationListSectionHeaderView : UIView
@property (nonatomic, weak) id delegate;
@end

@interface NCNotificationListView : UIScrollView
@property (nonatomic) BOOL layoutFromBottom;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic) CGFloat revealPercentage;
- (BOOL)isRevealed;
@end

/*
 * iOS 16 exposes three global lock-screen notification display styles:
 * 0 = Standard/List, 1 = Stack, 2 = Hidden/Count.
 *
 * TopDownNotifications16 is a list-style tweak, so SpringBoard must stay in
 * Standard/List mode while the tweak is enabled. The user's saved preference
 * is not rewritten; only SpringBoard's effective/runtime value is overridden.
 */
static const long long kTDListDisplayStyle = 0;

@interface NCNotificationSystemSettings : NSObject
- (unsigned long long)listDisplayStyleSetting;
@end

@interface NCNotificationMasterList : NSObject
- (unsigned long long)currentListDisplayStyleSetting;
- (void)setCurrentListDisplayStyleSetting:(unsigned long long)setting;
@end

static BOOL TDIsHistoryHeader(UIView *header) {
    if (![header isKindOfClass:NSClassFromString(@"NCNotificationListSectionHeaderView")]) return NO;
    id section = ((NCNotificationListSectionHeaderView *)header).delegate;
    return [section respondsToSelector:@selector(isHistorySection)]
        && ((BOOL (*)(id, SEL))objc_msgSend)(section, @selector(isHistorySection));
}

static CGFloat TDHistoryHeaderMaxAlpha(UIView *header) {
    NCNotificationListView *list = (NCNotificationListView *)header.superview;
    if (![list isKindOfClass:NSClassFromString(@"NCNotificationListView")] ||
        list.headerView != header ||
        !TDIsHistoryHeader(header)) {
        return 1.0;
    }

    return list.isRevealed ? 1.0 : MIN(MAX(list.revealPercentage, 0.0), 1.0);
}

static void TDApplyHistoryHeaderReveal(NCNotificationListView *list) {
    UIView *header = list.headerView;
    if (!TDIsHistoryHeader(header)) return;

    CGFloat alpha = TDHistoryHeaderMaxAlpha(header);
    if (fabs(header.alpha - alpha) > 0.001) {
        header.alpha = alpha;
    }
}

%group TopDownLayout

%hook NCNotificationSystemSettings
- (unsigned long long)listDisplayStyleSetting {
    return (unsigned long long)kTDListDisplayStyle;
}
%end

%hook NCNotificationMasterList
- (unsigned long long)currentListDisplayStyleSetting {
    return (unsigned long long)kTDListDisplayStyle;
}

- (void)setCurrentListDisplayStyleSetting:(unsigned long long)setting {
    %orig((unsigned long long)kTDListDisplayStyle);
}
%end

%hook NCNotificationListView
- (BOOL)layoutFromBottom {
    return NO;
}

- (void)setLayoutFromBottom:(BOOL)fromBottom {
    %orig(NO);
}

- (void)layoutSubviews {
    %orig;
    TDApplyHistoryHeaderReveal(self);
}

- (void)setRevealPercentage:(CGFloat)percentage {
    %orig;
    TDApplyHistoryHeaderReveal(self);
}

- (void)setRevealed:(BOOL)revealed {
    %orig;
    TDApplyHistoryHeaderReveal(self);
}
%end

%hook NCNotificationListSectionHeaderView
- (void)setAlpha:(CGFloat)alpha {
    %orig(MIN(alpha, TDHistoryHeaderMaxAlpha(self)));
}
%end

%hook CSCombinedListViewController
- (CGFloat)horizontalInsetMargin {
    return kIOS15ListInset;
}
%end

%hook ACUISActivityHostViewControllerFactory
+ (id)activityHostViewControllerWithDescriptor:(id)descriptor
                                     sceneType:(NSInteger)type
                                metricsRequest:(ACUISActivityMetricsRequest *)request {
    ACUISActivityItemMetricsRequest *lockScreen = request.lockScreenMetrics;
    ACUISSizeDimensionRequest *width = lockScreen.widthRequest;

    if (width && fabs(width.minimum - width.maximum) < 0.01) {
        CGFloat wider = width.maximum + 2.0 * (kIOS16ListInset - kIOS15ListInset);

        ACUISActivityMetricsRequest *adjusted = [request copy];
        ACUISActivityItemMetricsRequest *adjustedLockScreen = [lockScreen copy];
        adjustedLockScreen.widthRequest = [%c(ACUISSizeDimensionRequest) fixed:wider];
        adjusted.lockScreenMetrics = adjustedLockScreen;
        request = adjusted;
    }

    return %orig(descriptor, type, request);
}
%end

%hook NCNotificationSeamlessContentView
- (void)_layoutSubviewInBounds:(CGRect)bounds measuringOnly:(CGSize *)measuredSize {
    CGFloat reduction = kIOS15CardInsetReduction;

    CGRect enlarged = bounds;
    enlarged.size.width += 2.0 * reduction;
    enlarged.size.height += 2.0 * reduction;

    %orig(enlarged, measuredSize);

    if (measuredSize) {
        measuredSize->width = MAX(0.0, measuredSize->width - 2.0 * reduction);
        measuredSize->height = MAX(0.0, measuredSize->height - 2.0 * reduction);
        return;
    }

    CGRect viewBounds = self.bounds;
    if (!CGPointEqualToPoint(viewBounds.origin, CGPointMake(reduction, reduction))) {
        viewBounds.origin = CGPointMake(reduction, reduction);
        self.bounds = viewBounds;
    }

    CGFloat wantedCenterY = CGRectGetMidY(viewBounds);
    for (UIView *subview in self.subviews) {
        if (![NSStringFromClass([subview class]) containsString:@"BadgedIconView"]) continue;

        CGPoint center = subview.center;
        if (fabs(center.y - wantedCenterY) > 0.01) {
            subview.center = CGPointMake(center.x, wantedCenterY);
        }
    }
}
%end

%hook NCNotificationShortLookView
- (void)_setContinuousCornerRadius:(CGFloat)radius {
    %orig(kIOS15CardCornerRadius);
}

- (void)layoutSubviews {
    %orig;

    if (fabs(self._continuousCornerRadius - kIOS15CardCornerRadius) > 0.01) {
        [self _setContinuousCornerRadius:kIOS15CardCornerRadius];
    }

    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_stackDimmingOverlayView");
    UIView *dimming = ivar ? object_getIvar(self, ivar) : nil;
    if (dimming && fabs(dimming.layer.cornerRadius - kIOS15CardCornerRadius) > 0.01) {
        dimming.layer.cornerRadius = kIOS15CardCornerRadius;
        dimming.layer.cornerCurve = kCACornerCurveContinuous;
    }
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
