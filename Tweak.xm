// Tweak.xm - 进程内虚拟定位 (核心 hook)
// 钉钉打卡不触发「虚拟定位检测」：进程内构造普通 CLLocation。
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kPrefDomain    = @"com.zjq.locspoof";
static NSString *const kPrefEnabled   = @"Enabled";
static NSString *const kPrefLatitude  = @"Latitude";
static NSString *const kPrefLongitude = @"Longitude";
static NSString *const kPrefAltitude  = @"Altitude";

static const double kDefaultLatitude  = 30.2590;
static const double kDefaultLongitude = 120.1300;
static const double kDefaultAltitude  = 10.0;

double SpoofPrefLatitude(void);
double SpoofPrefLongitude(void);
void SpoofSetLocation(double lat, double lng, double alt);

static double prefDouble(NSString *key, double def) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefDomain);
    CFNumberRef v = (CFNumberRef)CFPreferencesCopyAppValue(
        (__bridge CFStringRef)key, (__bridge CFStringRef)kPrefDomain);
    double out = def;
    if (v && CFGetTypeID(v) == CFNumberGetTypeID())
        CFNumberGetValue(v, kCFNumberDoubleType, &out);
    if (v) CFRelease(v);
    return out;
}

static BOOL prefBool(NSString *key, BOOL def) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefDomain);
    CFBooleanRef v = (CFBooleanRef)CFPreferencesCopyAppValue(
        (__bridge CFStringRef)key, (__bridge CFStringRef)kPrefDomain);
    BOOL out = def;
    if (v && CFGetTypeID(v) == CFBooleanGetTypeID())
        out = CFBooleanGetValue(v);
    if (v) CFRelease(v);
    return out;
}

double SpoofPrefLatitude(void)  { return prefDouble(kPrefLatitude, kDefaultLatitude); }
double SpoofPrefLongitude(void) { return prefDouble(kPrefLongitude, kDefaultLongitude); }

void SpoofSetLocation(double lat, double lng, double alt) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefDomain);
    CFNumberRef latN = CFNumberCreate(NULL, kCFNumberDoubleType, &lat);
    CFNumberRef lngN = CFNumberCreate(NULL, kCFNumberDoubleType, &lng);
    CFNumberRef altN = CFNumberCreate(NULL, kCFNumberDoubleType, &alt);
    CFPreferencesSetAppValue((__bridge CFStringRef)kPrefLatitude,  latN, (__bridge CFStringRef)kPrefDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)kPrefLongitude, lngN, (__bridge CFStringRef)kPrefDomain);
    CFPreferencesSetAppValue((__bridge CFStringRef)kPrefAltitude,  altN, (__bridge CFStringRef)kPrefDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefDomain);
    if (latN) CFRelease(latN);
    if (lngN) CFRelease(lngN);
    if (altN) CFRelease(altN);
}

static CLLocation *spoofedLocation(void) {
    if (!prefBool(kPrefEnabled, YES)) return nil;
    CLLocationCoordinate2D coord;
    coord.latitude  = SpoofPrefLatitude();
    coord.longitude = SpoofPrefLongitude();
    double alt = prefDouble(kPrefAltitude, kDefaultAltitude);
    return [[CLLocation alloc] initWithCoordinate:coord
                                         altitude:alt
                               horizontalAccuracy:5.0
                                 verticalAccuracy:5.0
                                        timestamp:[NSDate date]];
}

%group SpoofLocation

%hook CLLocationManager

- (CLLocation *)location {
    CLLocation *spoofed = spoofedLocation();
    if (spoofed) return spoofed;
    return %orig;
}

- (void)startUpdatingLocation {
    %orig;
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        CLLocation *s = spoofedLocation();
        if (s) [delegate locationManager:self didUpdateLocations:@[s]];
    }
}

- (void)requestLocation {
    %orig;
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        CLLocation *s = spoofedLocation();
        if (s) [delegate locationManager:self didUpdateLocations:@[s]];
    }
}

- (void)startMonitoringSignificantLocationChanges {
    if (prefBool(kPrefEnabled, YES)) {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
            CLLocation *s = spoofedLocation();
            if (s) [delegate locationManager:self didUpdateLocations:@[s]];
        }
        return;
    }
    %orig;
}

%end

%hook NSObject

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *spoofed = spoofedLocation();
    if (spoofed) {
        %orig(manager, @[spoofed]);
    } else {
        %orig;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation *spoofed = spoofedLocation();
    if (spoofed) {
        %orig(manager, spoofed, oldLocation);
    } else {
        %orig;
    }
}

%end

%hook MKMapView
- (void)setShowsUserLocation:(BOOL)showsUserLocation {
    %orig;
    if (showsUserLocation) {
        CLLocation *spoofed = spoofedLocation();
        if (spoofed) [self setCenterCoordinate:spoofed.coordinate animated:NO];
    }
}
%end

%hook MKUserLocation
- (void)setLocation:(CLLocation *)location {
    CLLocation *spoofed = spoofedLocation();
    if (spoofed) {
        %orig(spoofed);
    } else {
        %orig;
    }
}
%end

%end // %group SpoofLocation

%ctor {
    %init(SpoofLocation);
}
