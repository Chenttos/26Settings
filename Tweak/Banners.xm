//
//  Banners.xm — iOS 26 notification banners in SpringBoard.
//
//  iOS 26 banners are noticeably rounder (a full continuous-corner capsule of
//  glass) than the 13pt platters iOS 15/16 draws.
//

#import <UIKit/UIKit.h>

#import "MLYPrefs.h"
#import "MLYStyle.h"

@interface PLPlatterView : UIView
@end

@interface NCNotificationShortLookView : UIView
@end

static BOOL MLYBannersActive(void) {
    MLYPrefs *prefs = MLYPrefs.shared;
    return prefs.enabled && prefs.styleNotificationBanners;
}

%group Banners

%hook PLPlatterView

- (void)layoutSubviews {
    %orig;
    if (!MLYBannersActive()) return;
    MLYPrefs *prefs = MLYPrefs.shared;
    CGFloat radius = MIN(prefs.notificationBannerRadius, CGRectGetHeight(self.bounds) / 2.0);
    MLYRoundPlatter(self, radius, prefs.notificationBannerGlass);
}

%end

%hook NCNotificationShortLookView

- (void)layoutSubviews {
    %orig;
    if (!MLYBannersActive()) return;
    MLYPrefs *prefs = MLYPrefs.shared;
    CGFloat radius = MIN(prefs.notificationBannerRadius, CGRectGetHeight(self.bounds) / 2.0);
    MLYRoundPlatter(self, radius, prefs.notificationBannerGlass);
}

%end

%end

%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier
                isEqualToString:@"com.apple.springboard"]) {
            return;
        }
        [MLYPrefs.shared startObserving];
        %init(Banners);
    }
}
