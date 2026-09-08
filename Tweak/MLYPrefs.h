//
//  MLYPrefs.h — 26Settings (com.meowly.26settings)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const MLYPrefsSuite;
extern NSString *const MLYPrefsChangedNotification;

/// Snapshot of the on-disk preferences, shared by the Preferences and
/// SpringBoard injections. Reloaded on the Darwin notification posted by the
/// preference bundle.
@interface MLYPrefs : NSObject

+ (instancetype)shared;

/// Re-reads the plist and starts listening for changes (idempotent).
- (void)startObserving;
- (void)reload;

@property (nonatomic, readonly) BOOL enabled;

// Settings list
@property (nonatomic, readonly) BOOL cardStyle;
@property (nonatomic, readonly) CGFloat cardRadius;
@property (nonatomic, readonly) CGFloat rowHeightBoost;
@property (nonatomic, readonly) CGFloat groupSpacing;
@property (nonatomic, readonly) BOOL sentenceCaseHeaders;
@property (nonatomic, readonly) BOOL pillSearchBar;
@property (nonatomic, readonly) BOOL glassNavigationBar;
@property (nonatomic, readonly) BOOL biggerSwitches;

// Icons
@property (nonatomic, readonly) BOOL restyleIcons;
@property (nonatomic, readonly) CGFloat iconSize;
@property (nonatomic, readonly) CGFloat iconRadius;
@property (nonatomic, readonly) BOOL tintedGlyphs;

// Root pane extras
@property (nonatomic, readonly) BOOL banner;
@property (nonatomic, readonly) BOOL quickGlance;
@property (nonatomic, readonly) BOOL glassPane;

// Notification banners (SpringBoard)
@property (nonatomic, readonly) BOOL styleNotificationBanners;
@property (nonatomic, readonly) CGFloat notificationBannerRadius;
@property (nonatomic, readonly) BOOL notificationBannerGlass;

@end

NS_ASSUME_NONNULL_END
