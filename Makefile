TARGET := iphone:clang:16.5:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Preferences SpringBoard

SUBPROJECTS = 26SettingsPrefs

TWEAK_NAME = 26Settings
26Settings_FILES = Tweak/Settings.xm Tweak/Banners.xm Tweak/MLYPrefs.m Tweak/MLYStyle.m Tweak/MLYBannerView.m
26Settings_CFLAGS = -fobjc-arc -ITweak
26Settings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

# Ship the sample/custom icon bundle with the tweak.
internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/26Settings/Icons.bundle$(ECHO_END)
	$(ECHO_NOTHING)cp icons/*.png $(THEOS_STAGING_DIR)/Library/26Settings/Icons.bundle/$(ECHO_END)
