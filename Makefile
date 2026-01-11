TARGET := iphone:clang:latest:14.5
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
STRICT = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
OneStateUltra_FILES = Tweak.x
OneStateUltra_FRAMEWORKS = UIKit Foundation
OneStateUltra_CFLAGS = -fobjc-arc
OneStateUltra_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/

include $(THEOS_MAKE_PATH)/tweak.mk
