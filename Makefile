TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra

OneStateUltra_FILES = Tweak.xm
OneStateUltra_CFLAGS = -fobjc-arc -Wno-error -Wno-unused-variable -Wno-deprecated-declarations -I.
OneStateUltra_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics Security
OneStateUltra_LDFLAGS = -Wl,-segalign,4000 -Xlinker -unexported_symbol -Xlinker "*"
OneStateUltra_LIBRARIES = 

include $(THEOS_MAKE_PATH)/tweak.mk
