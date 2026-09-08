#import "MLYPrefs.h"

NSString *const MLYPrefsSuite = @"com.meowly.26settings";
NSString *const MLYPrefsChangedNotification = @"com.meowly.26settings.prefschanged";

static NSString *const kPrefsPath =
    @"/var/mobile/Library/Preferences/com.meowly.26settings.plist";

@implementation MLYPrefs {
    NSDictionary *_values;
    BOOL _observing;
}

+ (instancetype)shared {
    static MLYPrefs *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [MLYPrefs new];
        [shared reload];
    });
    return shared;
}

static void MLYPrefsDidChange(CFNotificationCenterRef center, void *observer,
                              CFStringRef name, const void *object,
                              CFDictionaryRef info) {
    [[MLYPrefs shared] reload];
}

- (void)startObserving {
    if (_observing) return;
    _observing = YES;
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)self,
        MLYPrefsDidChange, (__bridge CFStringRef)MLYPrefsChangedNotification, NULL,
        CFNotificationSuspensionBehaviorCoalesce);
}

- (void)reload {
    NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:kPrefsPath];
    if (!disk) {
        NSUserDefaults *defaults =
            [[NSUserDefaults alloc] initWithSuiteName:MLYPrefsSuite];
        disk = [defaults dictionaryRepresentation];
    }
    _values = disk ?: @{};
}

#pragma mark - Readers

- (BOOL)boolForKey:(NSString *)key fallback:(BOOL)fallback {
    id value = _values[key];
    return value ? [value boolValue] : fallback;
}

- (CGFloat)floatForKey:(NSString *)key fallback:(CGFloat)fallback {
    id value = _values[key];
    return value ? (CGFloat)[value doubleValue] : fallback;
}

#pragma mark - Values

// Defaults are tuned against the iOS 26 Settings screenshots in Apple's iPhone
// User Guide: 22pt group cards, 51pt rows, 29pt squircle glyphs.

- (BOOL)enabled { return [self boolForKey:@"enabled" fallback:YES]; }

- (BOOL)cardStyle { return [self boolForKey:@"cardStyle" fallback:YES]; }
- (CGFloat)cardRadius { return [self floatForKey:@"cardRadius" fallback:22.0]; }
- (CGFloat)rowHeightBoost { return [self floatForKey:@"rowHeightBoost" fallback:7.0]; }
- (CGFloat)groupSpacing { return [self floatForKey:@"groupSpacing" fallback:10.0]; }
- (BOOL)sentenceCaseHeaders { return [self boolForKey:@"sentenceCaseHeaders" fallback:YES]; }
- (BOOL)pillSearchBar { return [self boolForKey:@"pillSearchBar" fallback:YES]; }
- (BOOL)glassNavigationBar { return [self boolForKey:@"glassNavigationBar" fallback:YES]; }
- (BOOL)circularBackButton { return [self boolForKey:@"circularBackButton" fallback:YES]; }
- (BOOL)biggerSwitches { return [self boolForKey:@"biggerSwitches" fallback:YES]; }

- (BOOL)restyleIcons { return [self boolForKey:@"restyleIcons" fallback:YES]; }
- (CGFloat)iconSize { return [self floatForKey:@"iconSize" fallback:29.0]; }
- (CGFloat)iconRadius { return [self floatForKey:@"iconRadius" fallback:7.0]; }
- (BOOL)glossyIcons { return [self boolForKey:@"glossyIcons" fallback:YES]; }
- (BOOL)tintedGlyphs { return [self boolForKey:@"tintedGlyphs" fallback:NO]; }

- (BOOL)banner { return [self boolForKey:@"banner" fallback:YES]; }
- (BOOL)quickGlance { return [self boolForKey:@"quickGlance" fallback:YES]; }
- (BOOL)glassPane { return [self boolForKey:@"glassPane" fallback:YES]; }

- (BOOL)styleNotificationBanners {
    return [self boolForKey:@"styleNotificationBanners" fallback:YES];
}
- (CGFloat)notificationBannerRadius {
    return [self floatForKey:@"notificationBannerRadius" fallback:28.0];
}
- (BOOL)notificationBannerGlass {
    return [self boolForKey:@"notificationBannerGlass" fallback:YES];
}

@end
