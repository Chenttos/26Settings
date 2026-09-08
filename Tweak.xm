//
//  26Settings — iOS 26-style Settings on iOS 15/16
//  Package: com.meowly.26settings
//  Injects ONLY into com.apple.Preferences (see 26Settings.plist filter).
//

#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>

#pragma mark - Preferences

static NSUserDefaults *MLYPreferences(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.meowly.26settings"];
    });
    return defaults;
}

static BOOL MLYBool(NSString *key, BOOL fallback) {
    id value = [MLYPreferences() objectForKey:key];
    return value ? [value boolValue] : fallback;
}

#pragma mark - Custom glyphs

// Drop iOS-26-style glyphs named <specifier-identifier>.png (120x120, white on
// transparent) into this bundle to replace the stock icons:
//   rootless: /var/jb/Library/26Settings/Icons.bundle
//   rootful:  /Library/26Settings/Icons.bundle
static UIImage *MLYCustomGlyph(NSString *name) {
    if (name.length == 0) return nil;
    NSArray<NSString *> *paths = @[
        @"/var/jb/Library/26Settings/Icons.bundle",
        @"/Library/26Settings/Icons.bundle"
    ];
    for (NSString *path in paths) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        UIImage *image = [UIImage imageNamed:name inBundle:bundle
               compatibleWithTraitCollection:nil];
        if (image) return image;
    }
    return nil;
}

#pragma mark - iOS 26 icon tints

static UIColor *MLYTintForIdentifier(NSString *identifier) {
    #define MLYC(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
    NSString *key = identifier.lowercaseString;
    if ([key containsString:@"accessibility"]) return MLYC(0, 122, 255);
    if ([key containsString:@"siri"] || [key containsString:@"intelligence"]) return MLYC(88, 86, 214);
    if ([key containsString:@"display"] || [key containsString:@"brightness"]) return MLYC(255, 159, 10);
    if ([key containsString:@"camera"]) return MLYC(120, 120, 128);
    if ([key containsString:@"control"]) return MLYC(120, 120, 128);
    if ([key containsString:@"wallpaper"]) return MLYC(0, 122, 255);
    if ([key containsString:@"standby"]) return MLYC(88, 86, 214);
    if ([key containsString:@"home"]) return MLYC(0, 122, 255);
    if ([key containsString:@"search"]) return MLYC(120, 120, 128);
    return MLYC(142, 142, 147); // General / fallback
    #undef MLYC
}

#pragma mark - Banner card (root pane header)

@interface MLYBannerView : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UILabel *avatar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@end

@implementation MLYBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.card = [[UIView alloc] init];
    self.card.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.card.layer.cornerRadius = 20.0;               // iOS 26's big card radius
    self.card.layer.cornerCurve = kCACornerCurveContinuous;
    self.card.clipsToBounds = YES;
    [self addSubview:self.card];

    self.avatar = [[UILabel alloc] init];
    self.avatar.text = @"🐾";
    self.avatar.font = [UIFont systemFontOfSize:30];
    self.avatar.textAlignment = NSTextAlignmentCenter;
    self.avatar.backgroundColor = MLYTintForIdentifier(@"general");
    self.avatar.layer.cornerRadius = 25.0;
    self.avatar.clipsToBounds = YES;
    [self.card addSubview:self.avatar];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"iPhone";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.card addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"26Settings — iOS 26 style enabled";
    self.subtitleLabel.font = [UIFont systemFontOfSize:13];
    self.subtitleLabel.textColor = [UIColor secondaryLabelColor];
    [self.card addSubview:self.subtitleLabel];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat margin = 16.0, padding = 14.0, avatarSize = 50.0;
    self.card.frame = CGRectMake(margin, 8.0,
                                 self.bounds.size.width - margin * 2.0,
                                 self.bounds.size.height - 16.0);
    self.avatar.frame = CGRectMake(padding, padding, avatarSize, avatarSize);
    CGFloat textX = padding * 2.0 + avatarSize;
    CGFloat textW = self.card.bounds.size.width - textX - padding;
    self.titleLabel.frame = CGRectMake(textX, padding + 4.0, textW, 24.0);
    self.subtitleLabel.frame = CGRectMake(textX, padding + 30.0, textW, 18.0);
}

@end

#pragma mark - Fake "Liquid Glass" pane (new feature)

static PSSpecifier *MLYSpec(NSString *name, NSString *key, PSListController *target) {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:target
                                                          set:@selector(setPreferenceValue:specifier:)
                                                          get:@selector(readPreferenceValue:)
                                                       detail:nil
                                                         cell:PSSwitchCell
                                                           edit:nil];
    spec.identifier = key;
    return spec;
}

@interface MLYGlassPaneController : PSListController
@end

@implementation MLYGlassPaneController

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    NSMutableArray *specs = [NSMutableArray new];

    PSSpecifier *appearance = [PSSpecifier groupSpecifierWithName:@"Appearance"];
    [appearance setProperty:@"Choose your preferred look for Liquid Glass. "
                            "Clear reveals content beneath; Tinted adds contrast."
                     forKey:@"footerText"];
    [specs addObject:appearance];
    [specs addObject:MLYSpec(@"Clear", @"glassClear", self)];
    [specs addObject:MLYSpec(@"Tinted", @"glassTinted", self)];

    [specs addObject:[PSSpecifier groupSpecifierWithName:@"New in iOS 26"]];
    [specs addObject:MLYSpec(@"Glass Notifications", @"glassNotifications", self)];
    [specs addObject:MLYSpec(@"Clear Tab Bar", @"glassTabBar", self)];

    _specifiers = specs;
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [MLYPreferences() setObject:value forKey:specifier.identifier];
    [MLYPreferences() synchronize];
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.meowly.26settings.prefschanged"),
        NULL, NULL, true);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id value = [MLYPreferences() objectForKey:specifier.identifier];
    return value ?: @NO;
}

@end

#pragma mark - Hooks

%hook PSTableCell

// iOS 26 puts every settings glyph on a soft circular tinted background.
- (void)layoutSubviews {
    %orig;

    if (!MLYBool(@"circularIcons", YES)) return;

    UIImageView *icon = self.iconImage;
    if (!icon || icon.hidden || icon.image == nil) return;

    static const CGFloat kDiameter = 29.0;
    UIView *circle = [self.contentView viewWithTag:26001];
    if (!circle) {
        circle = [[UIView alloc] init];
        circle.tag = 26001;
        circle.layer.cornerRadius = kDiameter / 2.0;
        circle.clipsToBounds = YES;
        circle.userInteractionEnabled = NO;
        [self.contentView insertSubview:circle belowSubview:icon];
    }

    circle.bounds = CGRectMake(0, 0, kDiameter, kDiameter);
    circle.center = icon.center;
    circle.backgroundColor = MLYTintForIdentifier(self.specifier.identifier ?: @"");

    UIImage *glyph = MLYCustomGlyph(self.specifier.identifier);
    if (glyph) icon.image = glyph;
    icon.image = [icon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    icon.tintColor = UIColor.whiteColor;
}

%end

%hook PSListController

- (void)viewDidLoad {
    %orig;

    // Card-style backdrop, iOS 26-style.
    if (MLYBool(@"cardStyle", YES)) {
        UITableView *table = [self valueForKey:@"table"]; // PSListController ivar
        if ([table isKindOfClass:[UITableView class]]) {
            table.backgroundColor = [UIColor systemGroupedBackgroundColor];
            table.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    }

    // Root-pane banner card.
    if (!MLYBool(@"banner", YES)) return;
    if (self.specifier) return;                         // only the root pane
    NSString *title = self.navigationItem.title ?: self.title;
    if (![title isEqualToString:@"Settings"]) return;

    UITableView *table = [self valueForKey:@"table"];
    if (![table isKindOfClass:[UITableView class]]) return;
    if (table.tableHeaderView.tag == 26002) return;

    MLYBannerView *banner = [[MLYBannerView alloc]
        initWithFrame:CGRectMake(0, 0, table.bounds.size.width, 92.0)];
    banner.tag = 26002;
    table.tableHeaderView = banner;
}

// Inject a "Liquid Glass" row into the root Settings list (iOS 26's new pane).
- (NSMutableArray *)specifiers {
    NSMutableArray *specs = %orig;

    static const void *kInjectedKey;
    if (![NSThread isMainThread]) return specs;
    if (self.specifier != nil) return specs;            // not the root pane
    if (objc_getAssociatedObject(self, kInjectedKey)) return specs;
    objc_setAssociatedObject(self, kInjectedKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!MLYBool(@"glassPane", YES)) return specs;

    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@" "];
    [group setProperty:@"Rendered locally by 26Settings. No glass was harmed."
                forKey:@"footerText"];
    [specs addObject:group];

    PSSpecifier *glass = [PSSpecifier
        preferenceSpecifierNamed:@"Liquid Glass"
                          target:self
                             set:nil
                             get:nil
                          detail:[MLYGlassPaneController class]
                            cell:PSLinkCell
                              edit:nil];
    glass.identifier = @"MeowlyLiquidGlass";
    if (@available(iOS 13.0, *)) {
        [glass setProperty:[UIImage systemImageNamed:@"drop.fill"]
                    forKey:@"iconImage"];
    }
    [specs addObject:glass];

    return specs;
}

%end
