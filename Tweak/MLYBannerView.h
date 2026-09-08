//
//  MLYBannerView.h — the iOS 26 account card that sits above the Settings root.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLYBannerView : UIView

/// Height the table header should be given for the current configuration.
+ (CGFloat)heightWithQuickGlance:(BOOL)quickGlance;

- (instancetype)initWithFrame:(CGRect)frame quickGlance:(BOOL)quickGlance;

@end

NS_ASSUME_NONNULL_END
