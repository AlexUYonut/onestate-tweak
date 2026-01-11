# Specificăm arhitectura pentru dispozitivele iOS noi (64-bit)
ARCHS = arm64 arm64e

# Target-ul minim de iOS (recomandat 14.0 sau mai nou pentru OneState)
TARGET := iphone:clang:latest:14.0

# Importăm regulile standard Theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OneStateUltra

# Fișierul sursă care conține codul Igarashi
OneStateUltra_FILES = Tweak.xm

# Folosim ARC pentru gestionarea automată a memoriei
OneStateUltra_CFLAGS = -fobjc-arc

# Framework-uri native necesare pentru alertă și sistem
# IMPORTANT: Am scos 'substrate' din listă pentru a evita crash-ul
OneStateUltra_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# Comandă pentru a curăța și reporni procesul după instalare (opțional)
after-install::
	install.exec "killall -9 OneState" || true
