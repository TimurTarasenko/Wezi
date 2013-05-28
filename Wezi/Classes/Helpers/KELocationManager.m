//
//  KELocationManager.m
//  Wezi
//
//  Created by Evgeniy Karkan on 4/29/13.
//  Copyright (c) 2013 Sigma Ukraine. All rights reserved.
//

#import "KELocationManager.h"

NSString * const kLocationDidChangeNotificationKey = @"locationManagerlocationDidChange";

@interface KELocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong)       CLLocationManager *locationManager;
@property (nonatomic, readwrite)    BOOL isMonitoringLocation;

@end

@implementation KELocationManager
@synthesize currentLocation;

@synthesize isMonitoringLocation;

+ (instancetype)sharedManager
{
    static KELocationManager *_sharedLocationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLocationManager = [[KELocationManager alloc] init];
    });
    
    return _sharedLocationManager;
}

#pragma mark - Public API

- (void)startMonitoringLocationChanges
{
    if ([CLLocationManager locationServicesEnabled])
    {
        if (!self.isMonitoringLocation)
        {
            self.isMonitoringLocation = YES;
            self.locationManager.delegate = self;
            [self.locationManager startMonitoringSignificantLocationChanges];
        }
    }
    else
    {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                                        message:@"This app requires location services to be enabled"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
}

- (void)stopMonitoringLocationChanges
{
    if (_locationManager)
    {
        [self.locationManager stopMonitoringSignificantLocationChanges];
        self.locationManager.delegate = nil;
        self.isMonitoringLocation = NO;
        self.locationManager = nil;
    }
}

#pragma mark - Accessors

- (CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        //        [_locationManager setDistanceFilter:1000];
        //        [_locationManager setDesiredAccuracy: kCLLocationAccuracyThreeKilometers];
    }
    
    return _locationManager;
}

- (CLLocation *)currentLocation
{
    return self.locationManager.location;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    if (newLocation) {
        userInfo[@"newLocation"] = newLocation;
    }
    if (oldLocation) {
        userInfo[@"oldLocation"] = oldLocation;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationDidChangeNotificationKey
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error
{
    if ([error code]== kCLErrorDenied)
    {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Denied"
                                                                        message:@"This app requires location services to be allowed"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
}

@end
