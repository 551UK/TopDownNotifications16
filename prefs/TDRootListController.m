#import <UIKit/UIKit.h>
#import "../PositionPreferences.h"
#import <spawn.h>
#import <unistd.h>
extern char **environ;

@interface PSViewController : UIViewController
@end

@interface TDSettingsTable : UITableViewController
@property(nonatomic, strong) UISwitch *enabledSwitch;
@property(nonatomic, strong) UISlider *slider;
@property(nonatomic, strong) UILabel *positionLabel;
@end

@implementation TDSettingsTable
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 50;
    self.tableView.accessibilityIdentifier = @"TDSettingsTable";

    self.enabledSwitch = [[UISwitch alloc] init];
    self.enabledSwitch.on = TDReadEnabled();
    [self.enabledSwitch addTarget:self action:@selector(enabledChanged:) forControlEvents:UIControlEventValueChanged];

    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = -100;
    self.slider.maximumValue = 250;
    self.slider.accessibilityLabel = @"First notification vertical position";
    [self.slider addTarget:self action:@selector(positionChanged:) forControlEvents:UIControlEventValueChanged];

    self.positionLabel = [[UILabel alloc] init];
    self.positionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.positionLabel.textAlignment = NSTextAlignmentCenter;
    [self refreshPosition];
}

- (void)enabledChanged:(UISwitch *)sender {
    TDWriteEnabled(sender.isOn);
}

- (void)refreshPosition {
    double offset = TDReadOffset();
    self.slider.value = offset;
    self.positionLabel.text = offset == 0 ? @"Default position (0 pt)" : [NSString stringWithFormat:@"%.0f pt %@", fabs(offset), offset < 0 ? @"up" : @"down"];
}

- (void)positionChanged:(UISlider *)sender {
    TDWriteOffset(sender.value);
    [self refreshPosition];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 4; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) return 5;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"Tweak", @"First notification position", @"Apply changes", @"About"][section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"Turn TopDownNotifications16 on or off. Respring to apply.";
    if (section == 1) return @"Choose where the first notification starts. Negative values move up; positive values move down. 0 keeps the original position. Notifications and groups grow downward from here.";
    if (section == 2) return @"Respring after changing settings to apply them.";
    return @"iOS 14-style top-down notifications with the native iOS 16 appearance. Includes grouped notifications. Made by 551.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    if (path.section == 0) {
        cell.textLabel.text = @"Enabled";
        cell.accessoryView = self.enabledSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    if (path.section == 1 && path.row < 2) {
        UIView *control = path.row == 0 ? self.positionLabel : self.slider;
        control.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:control];
        [NSLayoutConstraint activateConstraints:@[
            [control.leadingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leadingAnchor],
            [control.trailingAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.trailingAnchor],
            [control.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
        ]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    cell.textLabel.textColor = self.view.tintColor;
    cell.accessibilityTraits |= UIAccessibilityTraitButton;

    if (path.section == 1) {
        cell.textLabel.text = @[@"Move up 5 pt", @"Move down 5 pt", @"Reset to default position"][path.row - 2];
    } else if (path.section == 2) {
        cell.textLabel.text = @"Respring";
    } else {
        cell.textLabel.text = @"GitHub repository";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];

    if (path.section == 1 && path.row >= 2) {
        TDWriteOffset(path.row == 4 ? 0 : TDReadOffset() + (path.row == 2 ? -5 : 5));
        [self refreshPosition];
    } else if (path.section == 3) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://github.com/551UK/TopDownNotifications16"] options:@{} completionHandler:nil];
    } else if (path.section == 2) {
        const char *tool = "/var/jb/usr/bin/sbreload";
        pid_t pid;
        char *args[] = {(char *)tool, NULL};
        if (access(tool, X_OK) == 0 && posix_spawn(&pid, tool, NULL, NULL, args, environ) == 0) return;

        tool = "/var/jb/usr/bin/killall";
        char *fallback[] = {(char *)tool, (char *)"-9", (char *)"SpringBoard", NULL};
        if (access(tool, X_OK) == 0 && posix_spawn(&pid, tool, NULL, NULL, fallback, environ) == 0) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring unavailable" message:@"Please respring using Dopamine or your usual respring shortcut." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
@end

@interface TDRootListController : PSViewController
@property(nonatomic, strong) TDSettingsTable *settingsController;
@end

@implementation TDRootListController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TopDownNotifications16";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.settingsController = [[TDSettingsTable alloc] initWithStyle:UITableViewStyleInsetGrouped];
    [self addChildViewController:self.settingsController];

    UIView *content = self.settingsController.view;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    [self.settingsController didMoveToParentViewController:self];
}
@end
