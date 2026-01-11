TARGET := iphone:clang:latest:14.5
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra
OneStateUltra_FILES = Tweak.x
# Adăugăm Framework-urile necesare pentru alerte și logică de sistem
OneStateUltra_FRAMEWORKS = UIKit Foundation

OneStateUltra_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
