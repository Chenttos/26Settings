//
//  MLYStyle.h — shared drawing helpers for the iOS 26 look.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Continuous ("squircle") corner rounding, matching iOS 26's geometry.
void MLYRoundContinuous(UIView *view, CGFloat radius, CACornerMask corners);

/// Recursively applies `radius` to a platter and any backdrop/material layers
/// nested inside it, so the blur is clipped instead of poking out of the corners.
void MLYRoundPlatter(UIView *platter, CGFloat radius, BOOL addGlassEdge);

/// The hairline highlight that gives Liquid Glass its lit edge.
void MLYApplyGlassEdge(UIView *view);

/// iOS 26 accent for a Settings row, keyed off its specifier identifier/label.
UIColor *MLYTintForRow(NSString *_Nullable identifier, NSString *_Nullable label);

/// A user-supplied glyph from Library/26Settings/Icons.bundle, if present.
UIImage *_Nullable MLYGlyphOverride(NSString *_Nullable identifier,
                                    NSString *_Nullable label);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
