TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = DingTalk
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = locationSpoof

locationSpoof_FILES = Tweak.xm
locationSpoof_CFLAGS = -fobjc-arc
locationSpoof_LDFLAGS = -fuse-ld=lld
locationSpoof_FRAMEWORKS = CoreLocation MapKit UIKit Foundation
locationSpoof_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
