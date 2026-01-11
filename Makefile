ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
OneStateUltra_FILES = Tweak.xm
OneStateUltra_CFLAGS = -fobjc-arc
OneStateUltra_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
