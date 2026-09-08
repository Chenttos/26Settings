BUNDLE_NAME = 26SettingsPrefs

26SettingsPrefs_FILES = 26SPrefsRootListController.m
26SettingsPrefs_FRAMEWORKS = UIKit Preferences
26SettingsPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/26Settings.plist$(ECHO_END)
