//
//  Settings.xm — iOS 26 Settings look, injected into com.apple.Preferences.
//
//  Reference: real iOS 26 Settings screenshots in Apple's iPhone User Guide
//  (support.apple.com/guide/iphone/.../26/ios/26) — 22pt group cards with a
//  continuous corner curve, taller rows, sentence-case section headers,
//  29pt squircle glyphs and a translucent navigation bar with a circular
//  glass back button.
//

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "MLYBannerView.h"
#import "MLYPrefs.h"
#import "MLYStyle.h"

@interface PSSpecifier : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
+ (instancetype)preferenceSpecifierNamed:(NSString *)name
                                  target:(id)target
                                     set:(SEL)set
                                     get:(SEL)get
                                  detail:(Class)detail
                                    cell:(NSInteger)cell
                                    edit:(Class)edit;
+ (instancetype)groupSpecifierWithName:(NSString *)name;
- (void)setProperty:(id)property forKey:(NSString *)key;
@end

@interface PSListController : UIViewController
@property (nonatomic, retain) NSMutableArray *_specifiers;
- (PSSpecifier *)specifier;
- (UITableView *)table;
@end

@interface PSTableCell : UITableViewCell
- (PSSpecifier *)specifier;
@end

static const NSInteger PSLinkCell = 2;
static const NSInteger PSSwitchCell = 6;

static const NSInteger kBannerTag = 26002;
static char kNavBarStyledKey;
static char kSpecifiersInjectedKey;

#pragma mark - Small helpers

static BOOL MLYActive(void) {
    return MLYPrefs.shared.enabled;
}

static UITableView *MLYTableViewForCell(UITableViewCell *cell) {
    UIView *view = cell.superview;
    while (view && ![view isKindOfClass:UITableView.class]) view = view.superview;
    return (UITableView *)view;
}

/// Locates the glyph image view of a Settings row across the different
/// PSTableCell layouts Apple has shipped (imageView, iconImageView, or a plain
/// leading UIImageView).
static UIImageView *MLYIconViewForCell(UITableViewCell *cell) {
    if (cell.imageView.image) return cell.imageView;

    SEL iconSelectors[] = { NSSelectorFromString(@"iconImageView"),
                            NSSelectorFromString(@"iconImage") };
    for (NSUInteger index = 0; index < 2; index++) {
        if (![cell respondsToSelector:iconSelectors[index]]) continue;
        id (*getter)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        id candidate = getter(cell, iconSelectors[index]);
        if ([candidate isKindOfClass:UIImageView.class] && ((UIImageView *)candidate).image) {
            return candidate;
        }
    }

    for (UIView *subview in cell.contentView.subviews) {
        if (![subview isKindOfClass:UIImageView.class]) continue;
        UIImageView *imageView = (UIImageView *)subview;
        if (!imageView.image) continue;
        if (CGRectGetMinX(imageView.frame) < 40.0 && CGRectGetWidth(imageView.bounds) <= 44.0) {
            return imageView;
        }
    }
    return nil;
}

#pragma mark - Group card background

@interface MLY26CardBackgroundView : UIView
@property (nonatomic) CGFloat radius;
@property (nonatomic) CACornerMask corners;
@end

@implementation MLY26CardBackgroundView

- (void)layoutSubviews {
    [super layoutSubviews];
    MLYRoundContinuous(self, self.radius, self.corners);
}

@end

static void MLYApplyCardBackground(UITableViewCell *cell, UITableView *table) {
    NSIndexPath *indexPath = [table indexPathForCell:cell];
    if (!indexPath) return;

    NSInteger rows = [table numberOfRowsInSection:indexPath.section];
    BOOL isFirst = (indexPath.row == 0);
    BOOL isLast = (indexPath.row == rows - 1);

    CACornerMask corners = 0;
    if (isFirst) corners |= kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    if (isLast) corners |= kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;

    MLY26CardBackgroundView *card = nil;
    if ([cell.backgroundView isKindOfClass:MLY26CardBackgroundView.class]) {
        card = (MLY26CardBackgroundView *)cell.backgroundView;
    } else {
        card = [MLY26CardBackgroundView new];
        card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        cell.backgroundColor = UIColor.clearColor;
        cell.backgroundView = card;
    }
    card.radius = MLYPrefs.shared.cardRadius;
    card.corners = corners;
    [card setNeedsLayout];

    if (![cell.selectedBackgroundView isKindOfClass:MLY26CardBackgroundView.class]) {
        MLY26CardBackgroundView *selected = [MLY26CardBackgroundView new];
        selected.backgroundColor = UIColor.systemFillColor;
        cell.selectedBackgroundView = selected;
    }
    MLY26CardBackgroundView *selected = (MLY26CardBackgroundView *)cell.selectedBackgroundView;
    selected.radius = card.radius;
    selected.corners = corners;
}

#pragma mark - Icons

static void MLYRestyleIcon(UITableViewCell *cell) {
    MLYPrefs *prefs = MLYPrefs.shared;
    UIImageView *icon = MLYIconViewForCell(cell);
    if (!icon || icon.hidden) return;

    CGFloat side = prefs.iconSize;
    CGFloat radius = prefs.iconRadius;

    NSString *identifier = nil;
    NSString *label = cell.textLabel.text;
    if ([cell respondsToSelector:@selector(specifier)]) {
        PSSpecifier *specifier = [(PSTableCell *)cell specifier];
        identifier = specifier.identifier;
        if (!label) label = specifier.name;
    }

    UIImage *override = MLYGlyphOverride(identifier, label);
    if (override) {
        // A supplied white glyph gets the iOS 26 tinted squircle behind it.
        icon.image = [override imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        icon.tintColor = UIColor.whiteColor;
        icon.backgroundColor = MLYTintForRow(identifier, label);
        icon.contentMode = UIViewContentModeCenter;
    } else if (prefs.tintedGlyphs) {
        icon.image = [icon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        icon.tintColor = MLYTintForRow(identifier, label);
        icon.backgroundColor = UIColor.clearColor;
    }

    CGRect frame = icon.frame;
    frame.size = CGSizeMake(side, side);
    frame.origin.y = (CGRectGetHeight(cell.contentView.bounds) - side) / 2.0;
    icon.frame = frame;

    MLYRoundContinuous(icon, radius,
                       kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                           kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
}

#pragma mark - Navigation bar

static void MLYStyleNavigationBar(UINavigationBar *bar) {
    if (objc_getAssociatedObject(bar, &kNavBarStyledKey)) return;
    objc_setAssociatedObject(bar, &kNavBarStyledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UINavigationBarAppearance *standard = [UINavigationBarAppearance new];
    [standard configureWithDefaultBackground];
    standard.backgroundColor = UIColor.clearColor;
    standard.backgroundEffect =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    standard.shadowColor = [UIColor.separatorColor colorWithAlphaComponent:0.35];

    UINavigationBarAppearance *scrollEdge = [UINavigationBarAppearance new];
    [scrollEdge configureWithTransparentBackground];

    bar.standardAppearance = standard;
    bar.compactAppearance = standard;
    bar.scrollEdgeAppearance = scrollEdge;
}

#pragma mark - Row / section metrics

static CGFloat (*orig_heightForRow)(id, SEL, UITableView *, NSIndexPath *);
static CGFloat mly_heightForRow(id self, SEL _cmd, UITableView *table, NSIndexPath *indexPath) {
    CGFloat height = orig_heightForRow(self, _cmd, table, indexPath);
    MLYPrefs *prefs = MLYPrefs.shared;
    if (!prefs.enabled || !prefs.cardStyle) return height;
    if (height <= 0.0 || height == UITableViewAutomaticDimension) return height;
    return height + prefs.rowHeightBoost;
}

static CGFloat (*orig_heightForFooter)(id, SEL, UITableView *, NSInteger);
static CGFloat mly_heightForFooter(id self, SEL _cmd, UITableView *table, NSInteger section) {
    CGFloat height = orig_heightForFooter(self, _cmd, table, section);
    MLYPrefs *prefs = MLYPrefs.shared;
    if (!prefs.enabled || !prefs.cardStyle) return height;
    if (height < 0.0) return height;
    return height + prefs.groupSpacing;
}

/// Replaces `selector` on `cls` only when the class actually implements it, so
/// we never end up calling a NULL original on iOS versions that differ.
static BOOL MLYSwizzle(Class cls, SEL selector, IMP replacement, IMP *original) {
    if (!cls) return NO;
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return NO;
    IMP previous = method_setImplementation(method, replacement);
    if (original) *original = previous;
    return YES;
}

#pragma mark - Table + banner installation

static BOOL MLYIsRootPane(PSListController *controller) {
    if ([controller specifier] != nil) return NO;
    UINavigationController *nav = controller.navigationController;
    return nav != nil && nav.viewControllers.firstObject == controller;
}

static void MLYStyleTable(PSListController *controller) {
    UITableView *table = controller.table;
    if (![table isKindOfClass:UITableView.class]) return;
    if (!MLYPrefs.shared.cardStyle) return;

    table.backgroundColor = UIColor.systemGroupedBackgroundColor;
    table.separatorInset = UIEdgeInsetsMake(0.0, 58.0, 0.0, 0.0);
    table.separatorColor = [UIColor.separatorColor colorWithAlphaComponent:0.25];
}

static void MLYInstallBanner(PSListController *controller) {
    MLYPrefs *prefs = MLYPrefs.shared;
    if (!prefs.banner || !MLYIsRootPane(controller)) return;

    UITableView *table = controller.table;
    if (![table isKindOfClass:UITableView.class]) return;

    CGFloat width = CGRectGetWidth(table.bounds);
    if (width <= 0.0) return;
    CGFloat height = [MLYBannerView heightWithQuickGlance:prefs.quickGlance];

    UIView *header = table.tableHeaderView;
    if (header.tag == kBannerTag) {
        if (CGRectGetWidth(header.bounds) == width) return;
        header.frame = CGRectMake(0.0, 0.0, width, height);
        table.tableHeaderView = header;
        return;
    }

    MLYBannerView *banner =
        [[MLYBannerView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)
                                 quickGlance:prefs.quickGlance];
    banner.tag = kBannerTag;
    table.tableHeaderView = banner;
}

#pragma mark - "Liquid Glass" pane (new in 26Settings)

@interface MLYGlassPaneController : PSListController
@end

@implementation MLYGlassPaneController

static PSSpecifier *MLYSwitchSpecifier(NSString *name, NSString *key, id target) {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                            target:target
                                                               set:@selector(setPreferenceValue:
                                                                                     specifier:)
                                                               get:@selector(readPreferenceValue:)
                                                            detail:nil
                                                              cell:PSSwitchCell
                                                              edit:nil];
    specifier.identifier = key;
    return specifier;
}

- (NSArray *)specifiers {
    if (self._specifiers) return self._specifiers;
    NSMutableArray *specifiers = [NSMutableArray array];

    PSSpecifier *appearance = [PSSpecifier groupSpecifierWithName:@"Appearance"];
    [appearance setProperty:@"Liquid Glass floats translucent controls above your "
                            @"content. Turn pieces of it off if you prefer more contrast."
                     forKey:@"footerText"];
    [specifiers addObject:appearance];
    [specifiers addObject:MLYSwitchSpecifier(@"Glass Navigation Bar", @"glassNavigationBar", self)];
    [specifiers addObject:MLYSwitchSpecifier(@"Clear Glyphs", @"tintedGlyphs", self)];

    PSSpecifier *banners = [PSSpecifier groupSpecifierWithName:@"Notifications"];
    [banners setProperty:@"Rounds and frosts incoming banners the way iOS 26 does."
                  forKey:@"footerText"];
    [specifiers addObject:banners];
    [specifiers addObject:MLYSwitchSpecifier(@"Glass Banners", @"styleNotificationBanners", self)];

    PSSpecifier *list = [PSSpecifier groupSpecifierWithName:@"Settings List"];
    [specifiers addObject:list];
    [specifiers addObject:MLYSwitchSpecifier(@"Rounded Group Cards", @"cardStyle", self)];
    [specifiers addObject:MLYSwitchSpecifier(@"Sentence Case Headers", @"sentenceCaseHeaders", self)];
    [specifiers addObject:MLYSwitchSpecifier(@"Quick Glance Card", @"quickGlance", self)];

    self._specifiers = specifiers;
    return specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MLYPrefsSuite];
    [defaults setObject:value forKey:specifier.identifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)MLYPrefsChangedNotification, NULL,
                                         NULL, true);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MLYPrefsSuite];
    id value = [defaults objectForKey:specifier.identifier];
    if (value) return value;
    // Fall back to the tweak's own default so the switches start in sync.
    return [[MLYPrefs shared] valueForKey:specifier.identifier] ?: @NO;
}

@end

#pragma mark - Hooks

%hook UITableViewCell

- (void)layoutSubviews {
    %orig;
    if (!MLYActive()) return;

    UITableView *table = MLYTableViewForCell(self);
    if (!table || table.style == UITableViewStylePlain) return;

    MLYPrefs *prefs = MLYPrefs.shared;
    if (prefs.cardStyle) MLYApplyCardBackground(self, table);
    if (prefs.restyleIcons) MLYRestyleIcon(self);
}

%end

%hook UITableViewHeaderFooterView

- (void)layoutSubviews {
    %orig;
    if (!MLYActive() || !MLYPrefs.shared.sentenceCaseHeaders) return;

    UILabel *label = self.textLabel;
    NSString *text = label.text;
    if (text.length == 0) return;

    // iOS 26 dropped the all-caps section headers in favour of a larger,
    // sentence-case title.
    if ([text isEqualToString:text.uppercaseString] &&
        ![text isEqualToString:text.lowercaseString]) {
        label.text = [text capitalizedString];
    }
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.secondaryLabelColor;
}

%end

%hook UISearchBar

- (void)layoutSubviews {
    %orig;
    if (!MLYActive() || !MLYPrefs.shared.pillSearchBar) return;
    UITextField *field = [self valueForKey:@"searchField"];
    if (![field isKindOfClass:UITextField.class]) return;
    CGFloat radius = CGRectGetHeight(field.bounds) / 2.0;
    if (radius <= 0.0) return;
    MLYRoundContinuous(field, radius,
                       kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                           kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
}

%end

%hook UISwitch

- (void)layoutSubviews {
    %orig;
    if (!MLYActive() || !MLYPrefs.shared.biggerSwitches) return;
    CGAffineTransform scale = CGAffineTransformMakeScale(1.05, 1.05);
    if (!CGAffineTransformEqualToTransform(self.transform, scale)) self.transform = scale;
}

%end

%hook UINavigationBar

- (void)layoutSubviews {
    %orig;
    if (!MLYActive()) return;
    MLYPrefs *prefs = MLYPrefs.shared;
    if (prefs.glassNavigationBar) MLYStyleNavigationBar(self);
}

%end

%hook PSListController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (!MLYActive()) return;
    MLYStyleTable(self);
    MLYInstallBanner(self);
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (!MLYActive()) return;
    // The stock root pane assigns its own table header after the view loads, so
    // the card is (re)installed on every layout pass rather than once.
    MLYInstallBanner(self);
}

- (NSMutableArray *)specifiers {
    NSMutableArray *specifiers = %orig;
    if (!MLYActive() || !MLYPrefs.shared.glassPane) return specifiers;
    if (![NSThread isMainThread]) return specifiers;
    if (!MLYIsRootPane(self)) return specifiers;
    if (objc_getAssociatedObject(self, &kSpecifiersInjectedKey)) return specifiers;
    objc_setAssociatedObject(self, &kSpecifiersInjectedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"Liquid Glass"];
    [group setProperty:@"Added by 26Settings." forKey:@"footerText"];
    [specifiers addObject:group];

    PSSpecifier *pane = [PSSpecifier preferenceSpecifierNamed:@"Liquid Glass"
                                                       target:self
                                                          set:nil
                                                          get:nil
                                                       detail:MLYGlassPaneController.class
                                                         cell:PSLinkCell
                                                         edit:nil];
    pane.identifier = @"MeowlyLiquidGlass";
    [pane setProperty:[UIImage systemImageNamed:@"drop.fill"] forKey:@"iconImage"];
    [specifiers addObject:pane];

    return specifiers;
}

%end

%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.Preferences"]) {
            return;
        }
        [MLYPrefs.shared startObserving];
        %init;

        Class listController = objc_getClass("PSListController");
        MLYSwizzle(listController, @selector(tableView:heightForRowAtIndexPath:),
                   (IMP)mly_heightForRow, (IMP *)&orig_heightForRow);
        MLYSwizzle(listController, @selector(tableView:heightForFooterInSection:),
                   (IMP)mly_heightForFooter, (IMP *)&orig_heightForFooter);
    }
}
