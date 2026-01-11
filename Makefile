# Forțează crearea binarului în pachet
FINALPACKAGE = 1
DEBUG = 0
STRICT = 0

TARGET := iphone:clang:latest:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
OneStateUltra_FILES = Tweak.x
OneStateUltra_FRAMEWORKS = UIKit Foundation
OneStateUltra_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

# Această linie este crucială pentru a mări fișierul peste 4KB
OneStateUltra_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/

include $(THEOS_MAKE_PATH)/tweak.mk
