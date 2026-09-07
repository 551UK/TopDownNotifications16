#import "../prefs/TDRootListController.m"
// Supply only the PreferenceLoader superclass on the simulator.
@implementation PSViewController
@end
@interface SmokeDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end
@implementation SmokeDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    TDWriteOffset(0);
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    TDRootListController *root = [TDRootListController new];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:root];
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        TDSettingsTable *screen = root.settingsController;
        BOOL passed = screen && screen.tableView.numberOfSections == 3 && [screen.tableView numberOfRowsInSection:0] == 5;
        passed &= screen.slider.value == 0 && [screen.positionLabel.text isEqualToString:@"Default position (0 pt)"];
        screen.slider.value = 75;
        [screen.slider sendActionsForControlEvents:UIControlEventValueChanged];
        passed &= TDReadOffset() == 75 && [screen.positionLabel.text isEqualToString:@"75 pt down"];
        [screen tableView:screen.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
        passed &= TDReadOffset() == 70;
        [screen tableView:screen.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        passed &= TDReadOffset() == 75;
        [screen tableView:screen.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
        passed &= TDReadOffset() == 0;
        [screen.tableView layoutIfNeeded];
        passed &= screen.slider.window != nil && screen.slider.bounds.size.width > 100;
        for (NSInteger section = 1; section <= 2; section++) {
            UITableViewCell *cell = [screen tableView:screen.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            passed &= [cell.textLabel.text isEqualToString:section == 1 ? @"Respring" : @"GitHub repository"];
        }
        NSString *report = passed ? @"PASS: visible Settings page, default position, slider persistence, up/down, reset, respring and GitHub rows" : @"FAIL";
        [report writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/settings-smoke.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    });
    return YES;
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(SmokeDelegate.class)); }
}
