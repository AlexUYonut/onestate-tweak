TARGET := iphone:clang:latest:11.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra

OneStateUltra_FILES = Tweak.xm
OneStateUltra_CFLAGS = -fobjc-arc -Wno-error -Wno-unused-variable
OneStateUltra_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
OneStateUltra_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
