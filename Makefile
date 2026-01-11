# Dezactivează tratarea avertismentelor ca erori
STRICT = 0
FINALPACKAGE = 1
DEBUG = 0

TARGET := iphone:clang:latest:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
OneStateUltra_FILES = Tweak.x
OneStateUltra_FRAMEWORKS = UIKit Foundation
# Ignoră avertismentele specifice pentru cod deprecated
OneStateUltra_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
