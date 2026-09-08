#import "MLYStyle.h"
#import <objc/message.h>

static NSString *const kGlassEdgeLayerName = @"MLY26GlassEdge";

#pragma mark - Geometry

void MLYRoundContinuous(UIView *view, CGFloat radius, CACornerMask corners) {
    if (!view) return;
    CALayer *layer = view.layer;
    if (@available(iOS 13.0, *)) layer.cornerCurve = kCACornerCurveContinuous;
    if (layer.cornerRadius != radius) layer.cornerRadius = radius;
    layer.maskedCorners = corners;
    view.clipsToBounds = radius > 0.0;
}

void MLYApplyGlassEdge(UIView *view) {
    if (!view) return;
    for (CALayer *sublayer in view.layer.sublayers) {
        if ([sublayer.name isEqualToString:kGlassEdgeLayerName]) {
            sublayer.frame = view.bounds;
            sublayer.cornerRadius = view.layer.cornerRadius;
            return;
        }
    }
    CALayer *edge = [CALayer layer];
    edge.name = kGlassEdgeLayerName;
    edge.frame = view.bounds;
    edge.cornerRadius = view.layer.cornerRadius;
    if (@available(iOS 13.0, *)) edge.cornerCurve = kCACornerCurveContinuous;
    edge.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    edge.borderColor = [UIColor colorWithWhite:1.0 alpha:0.22].CGColor;
    edge.zPosition = 100.0;
    [view.layer addSublayer:edge];
}

static BOOL MLYIsBackdrop(UIView *view) {
    if ([view isKindOfClass:UIVisualEffectView.class]) return YES;
    NSString *name = NSStringFromClass(view.class);
    return [name containsString:@"MTMaterialView"] ||
           [name containsString:@"BackdropView"] ||
           [name containsString:@"PlatterView"];
}

void MLYRoundPlatter(UIView *platter, CGFloat radius, BOOL addGlassEdge) {
    if (!platter) return;

    // PLPlatterView / MTMaterialView expose the private continuous radius that
    // SpringBoard itself uses; prefer it so the blur is masked correctly.
    SEL continuous = NSSelectorFromString(@"setContinuousCornerRadius:");
    if ([platter respondsToSelector:continuous]) {
        void (*setter)(id, SEL, CGFloat) = (void (*)(id, SEL, CGFloat))objc_msgSend;
        setter(platter, continuous, radius);
    }
    MLYRoundContinuous(platter, radius, kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                                            kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);

    for (UIView *subview in platter.subviews) {
        if (!MLYIsBackdrop(subview)) continue;
        if ([subview respondsToSelector:continuous]) {
            void (*setter)(id, SEL, CGFloat) = (void (*)(id, SEL, CGFloat))objc_msgSend;
            setter(subview, continuous, radius);
        }
        MLYRoundContinuous(subview, radius,
                           kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                               kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
    }

    if (addGlassEdge) MLYApplyGlassEdge(platter);
}

#pragma mark - Tints

#define MLYRGB(r, g, b) \
    [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:1.0]

UIColor *MLYTintForRow(NSString *identifier, NSString *label) {
    NSString *key = [NSString stringWithFormat:@"%@ %@", identifier ?: @"", label ?: @""]
                        .lowercaseString;

    if ([key containsString:@"airplane"]) return MLYRGB(255, 149, 0);
    if ([key containsString:@"wifi"] || [key containsString:@"wi-fi"])
        return MLYRGB(0, 122, 255);
    if ([key containsString:@"bluetooth"]) return MLYRGB(0, 122, 255);
    if ([key containsString:@"cellular"] || [key containsString:@"mobile"])
        return MLYRGB(52, 199, 89);
    if ([key containsString:@"hotspot"] || [key containsString:@"tether"])
        return MLYRGB(52, 199, 89);
    if ([key containsString:@"vpn"]) return MLYRGB(0, 122, 255);
    if ([key containsString:@"notification"]) return MLYRGB(255, 59, 48);
    if ([key containsString:@"sound"] || [key containsString:@"haptic"])
        return MLYRGB(255, 45, 85);
    if ([key containsString:@"focus"]) return MLYRGB(88, 86, 214);
    if ([key containsString:@"screentime"] || [key containsString:@"screen time"])
        return MLYRGB(88, 86, 214);
    if ([key containsString:@"intelligence"] || [key containsString:@"siri"])
        return MLYRGB(94, 92, 230);
    if ([key containsString:@"display"] || [key containsString:@"brightness"])
        return MLYRGB(0, 122, 255);
    if ([key containsString:@"wallpaper"]) return MLYRGB(48, 176, 199);
    if ([key containsString:@"standby"]) return MLYRGB(28, 28, 30);
    if ([key containsString:@"accessibility"]) return MLYRGB(0, 122, 255);
    if ([key containsString:@"search"] || [key containsString:@"spotlight"])
        return MLYRGB(90, 90, 95);
    if ([key containsString:@"faceid"] || [key containsString:@"face id"] ||
        [key containsString:@"touchid"] || [key containsString:@"passcode"])
        return MLYRGB(52, 199, 89);
    if ([key containsString:@"emergency"] || [key containsString:@"sos"])
        return MLYRGB(255, 59, 48);
    if ([key containsString:@"battery"] || [key containsString:@"power"])
        return MLYRGB(52, 199, 89);
    if ([key containsString:@"privacy"] || [key containsString:@"security"])
        return MLYRGB(0, 122, 255);
    if ([key containsString:@"appstore"] || [key containsString:@"app store"])
        return MLYRGB(0, 122, 255);
    if ([key containsString:@"wallet"] || [key containsString:@"applepay"])
        return MLYRGB(28, 28, 30);
    if ([key containsString:@"game"]) return MLYRGB(255, 149, 0);
    if ([key containsString:@"control"]) return MLYRGB(90, 90, 95);
    if ([key containsString:@"camera"]) return MLYRGB(90, 90, 95);
    if ([key containsString:@"photo"]) return MLYRGB(255, 149, 0);
    if ([key containsString:@"developer"]) return MLYRGB(90, 90, 95);
    return MLYRGB(142, 142, 147);  // General and everything else
}

#pragma mark - Glyph overrides

UIImage *MLYGlyphOverride(NSString *identifier, NSString *label) {
    static NSArray<NSBundle *> *bundles;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray *found = [NSMutableArray array];
        for (NSString *path in @[ @"/var/jb/Library/26Settings/Icons.bundle",
                                  @"/Library/26Settings/Icons.bundle" ]) {
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            if (bundle) [found addObject:bundle];
        }
        bundles = found;
    });

    for (NSString *name in @[ identifier ?: @"", label ?: @"" ]) {
        if (name.length == 0) continue;
        for (NSBundle *bundle in bundles) {
            UIImage *image = [UIImage imageNamed:name
                                        inBundle:bundle
                   compatibleWithTraitCollection:nil];
            if (image) return image;
        }
    }
    return nil;
}

#pragma mark - Gloss

void MLYApplyIconGloss(UIView *iconView, CGFloat radius) {
    if (!iconView) return;

    CAGradientLayer *gloss = nil;
    for (CALayer *sublayer in iconView.layer.sublayers) {
        if (sublayer.name && [sublayer.name isEqualToString:@"MLY26Gloss"]) {
            gloss = (CAGradientLayer *)sublayer;
            break;
        }
    }
    if (!gloss) {
        gloss = [CAGradientLayer layer];
        gloss.name = @"MLY26Gloss";
        gloss.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.30].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.06].CGColor,
            (id)[UIColor colorWithWhite:0.0 alpha:0.06].CGColor
        ];
        gloss.locations = @[ @0.0, @0.55, @1.0 ];
        gloss.startPoint = CGPointMake(0.5, 0.0);
        gloss.endPoint = CGPointMake(0.5, 1.0);
        [iconView.layer addSublayer:gloss];
    }
    gloss.frame = iconView.bounds;
    gloss.cornerRadius = radius;
    if (@available(iOS 13.0, *)) gloss.cornerCurve = kCACornerCurveContinuous;
}
