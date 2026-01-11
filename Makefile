FINALPACKAGE = 1
DEBUG = 0
STRICT = 0

# Setăm SDK-ul și arhitectura
TARGET := iphone:clang:latest:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
# Forțăm recunoașterea fișierului de cod
OneStateUltra_FILES = Tweak.x
OneStateUltra_FRAMEWORKS = UIKit Foundation
OneStateUltra_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

# ACEASTĂ LINIE ESTE OBLIGATORIE PENTRU A TRECE DE 4KB
OneStateUltra_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/

include $(THEOS_MAKE_PATH)/tweak.mk
