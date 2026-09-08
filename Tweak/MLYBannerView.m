#import "MLYBannerView.h"
#import "MLYPrefs.h"
#import "MLYStyle.h"

#import <sys/mount.h>

static const CGFloat kSideMargin = 16.0;
static const CGFloat kCardPadding = 14.0;
static const CGFloat kAvatarSize = 54.0;
static const CGFloat kGlanceHeight = 46.0;

#pragma mark - Helpers

static NSString *MLYFreeStorageString(void) {
    struct statfs stats;
    if (statfs("/var/mobile", &stats) != 0) return @"—";
    unsigned long long free = (unsigned long long)stats.f_bavail * stats.f_bsize;
    return [NSByteCountFormatter stringFromByteCount:(long long)free
                                          countStyle:NSByteCountFormatterCountStyleFile];
}

static NSString *MLYBatteryString(void) {
    UIDevice *device = UIDevice.currentDevice;
    BOOL wasMonitoring = device.batteryMonitoringEnabled;
    device.batteryMonitoringEnabled = YES;
    float level = device.batteryLevel;
    device.batteryMonitoringEnabled = wasMonitoring;
    if (level < 0.0) return @"—";
    return [NSString stringWithFormat:@"%.0f%%", level * 100.0];
}

static NSString *MLYInitials(NSString *name) {
    NSMutableString *initials = [NSMutableString string];
    for (NSString *word in [name componentsSeparatedByString:@" "]) {
        if (word.length == 0) continue;
        [initials appendString:[[word substringToIndex:1] uppercaseString]];
        if (initials.length >= 2) break;
    }
    return initials.length ? initials : @"iP";
}

#pragma mark - Glance pill

@interface MLYGlancePill : UIView
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *captionLabel;
@end

@implementation MLYGlancePill

- (instancetype)initWithValue:(NSString *)value caption:(NSString *)caption {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    self.backgroundColor = [UIColor.systemFillColor colorWithAlphaComponent:0.10];

    _valueLabel = [UILabel new];
    _valueLabel.text = value;
    _valueLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_valueLabel];

    _captionLabel = [UILabel new];
    _captionLabel.text = caption;
    _captionLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    _captionLabel.textColor = UIColor.secondaryLabelColor;
    _captionLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_captionLabel];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    MLYRoundContinuous(self, 14.0,
                       kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                           kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);
    CGFloat width = self.bounds.size.width;
    self.valueLabel.frame = CGRectMake(0.0, 5.0, width, 18.0);
    self.captionLabel.frame = CGRectMake(0.0, 23.0, width, 14.0);
}

@end

#pragma mark - Banner

@implementation MLYBannerView {
    UIView *_card;
    UILabel *_avatar;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UIImageView *_chevron;
    NSArray<MLYGlancePill *> *_pills;
    BOOL _quickGlance;
}

+ (CGFloat)heightWithQuickGlance:(BOOL)quickGlance {
    CGFloat card = kCardPadding * 2.0 + kAvatarSize;
    if (quickGlance) card += kGlanceHeight + 6.0;
    return card + 16.0;
}

- (instancetype)initWithFrame:(CGRect)frame quickGlance:(BOOL)quickGlance {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _quickGlance = quickGlance;

    _card = [UIView new];
    _card.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    [self addSubview:_card];

    NSString *deviceName = UIDevice.currentDevice.name ?: @"iPhone";

    _avatar = [UILabel new];
    _avatar.text = MLYInitials(deviceName);
    _avatar.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
    _avatar.textColor = UIColor.whiteColor;
    _avatar.textAlignment = NSTextAlignmentCenter;
    _avatar.backgroundColor = MLYTintForRow(@"appleAccount", @"Apple Account");
    _avatar.layer.cornerRadius = kAvatarSize / 2.0;
    _avatar.clipsToBounds = YES;
    [_card addSubview:_avatar];

    _titleLabel = [UILabel new];
    _titleLabel.text = deviceName;
    _titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
    [_card addSubview:_titleLabel];

    _subtitleLabel = [UILabel new];
    _subtitleLabel.text = @"Apple Account, iCloud, and more";
    _subtitleLabel.font = [UIFont systemFontOfSize:13.0];
    _subtitleLabel.textColor = UIColor.secondaryLabelColor;
    [_card addSubview:_subtitleLabel];

    _chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    _chevron.tintColor = UIColor.tertiaryLabelColor;
    _chevron.contentMode = UIViewContentModeScaleAspectFit;
    [_card addSubview:_chevron];

    if (quickGlance) {
        NSString *version =
            [NSString stringWithFormat:@"%@ %@", UIDevice.currentDevice.systemName,
                                       UIDevice.currentDevice.systemVersion];
        _pills = @[
            [[MLYGlancePill alloc] initWithValue:version caption:@"Software"],
            [[MLYGlancePill alloc] initWithValue:MLYBatteryString() caption:@"Battery"],
            [[MLYGlancePill alloc] initWithValue:MLYFreeStorageString() caption:@"Available"]
        ];
        for (MLYGlancePill *pill in _pills) [_card addSubview:pill];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat radius = MLYPrefs.shared.cardRadius;
    _card.frame = CGRectMake(kSideMargin, 8.0,
                             CGRectGetWidth(self.bounds) - kSideMargin * 2.0,
                             CGRectGetHeight(self.bounds) - 16.0);
    MLYRoundContinuous(_card, radius,
                       kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                           kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner);

    CGFloat cardWidth = CGRectGetWidth(_card.bounds);
    _avatar.frame = CGRectMake(kCardPadding, kCardPadding, kAvatarSize, kAvatarSize);

    CGFloat textX = kCardPadding * 2.0 + kAvatarSize;
    CGFloat textWidth = cardWidth - textX - kCardPadding - 18.0;
    _titleLabel.frame = CGRectMake(textX, kCardPadding + 6.0, textWidth, 24.0);
    _subtitleLabel.frame = CGRectMake(textX, kCardPadding + 31.0, textWidth, 18.0);
    _chevron.frame = CGRectMake(cardWidth - kCardPadding - 10.0,
                                kCardPadding + kAvatarSize / 2.0 - 8.0, 10.0, 16.0);

    if (_pills.count == 0) return;
    CGFloat gap = 8.0;
    CGFloat available = cardWidth - kCardPadding * 2.0 - gap * (_pills.count - 1);
    CGFloat pillWidth = available / _pills.count;
    CGFloat y = kCardPadding + kAvatarSize + 6.0;
    for (NSUInteger index = 0; index < _pills.count; index++) {
        _pills[index].frame =
            CGRectMake(kCardPadding + (pillWidth + gap) * index, y, pillWidth, kGlanceHeight - 6.0);
    }
}

@end
