//
//  MHLocationManager.m
//  Padoc
//
//  Created by quarta on 05/04/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "MHLocationManager.h"




@interface MHLocation ()

@end


@implementation MHLocation

- (instancetype)init;
{
    self = [super init];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.x = [decoder decodeDoubleForKey:@"x"];
        self.y = [decoder decodeDoubleForKey:@"y"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeDouble:self.x forKey:@"x"];
    [encoder encodeDouble:self.y forKey:@"y"];
}

@end




@interface MHLocationManager () <CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) MHLocation *position;

@property (nonatomic, strong) NSMutableDictionary *beacons;
@property (nonatomic, strong) NSMutableDictionary *beaconsProximity;
@property (nonatomic, strong) CLBeaconRegion *ownBeaconRegion;
@property (nonatomic, strong) NSDictionary *beaconPeripheralData;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@property (nonatomic) BOOL started;
@property (nonatomic) BOOL beaconActive;
@property (nonatomic) BOOL useGPS;
@property (nonatomic) BOOL useBeacon;

@end


#pragma mark - Singleton static variables

static MHLocationManager *locationManager = nil;
static NSString *beaconID = @"";
static BOOL useGPS = YES;
static BOOL useBeacon = YES;




@implementation MHLocationManager

- (instancetype)initWithBeaconID:(NSString*)beaconID
                         withGPS:(BOOL)useGPS
                      withBeacon:(BOOL)useBeacon
{
    self = [super init];
    
    if(self)
    {
        self.useGPS = useGPS;
        self.useBeacon = useBeacon;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        // Request authorizations
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        
        // Setting initial position
        self.position = [[MHLocation alloc] init];
        
        CLLocation *curPos = self.locationManager.location;
        
        self.position.x = curPos.coordinate.longitude;
        self.position.y = curPos.coordinate.latitude;
        
        
        self.started = NO;
        self.beaconActive = NO;
        self.beacons = [[NSMutableDictionary alloc] init];
        self.beaconsProximity = [[NSMutableDictionary alloc] init];
        
        // Create the beacon region.
        self.ownBeaconRegion = [[CLBeaconRegion alloc]
                                initWithProximityUUID:[[NSUUID alloc]initWithUUIDString:beaconID]
                                           identifier:[MHComputation makeUniqueStringFromSource:beaconID]];
        
        // Create a dictionary of advertisement data.
        self.beaconPeripheralData = [self.ownBeaconRegion peripheralDataWithMeasuredPower:nil];
        
        // Create the peripheral manager.
        self.peripheralManager = [[CBPeripheralManager alloc]
                                 initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

- (void)dealloc
{
    self.position = nil;
    self.ownBeaconRegion = nil;
    self.beaconPeripheralData = nil;
    [self.beacons removeAllObjects];
    self.beacons = nil;
    [self.beaconsProximity removeAllObjects];
    self.beaconsProximity = nil;
    self.locationManager = nil;
}

- (void)start
{
    // Start position updates
    if (self.useGPS)
    {
        [self.locationManager startUpdatingLocation];
    }
  
    if (self.useBeacon)
    {
        // Start monitoring all iBeacon regions
        for (id beaconKey in self.beacons.allKeys)
        {
            CLBeaconRegion *beacon = [self.beacons objectForKey:beaconKey];
            
            [self.locationManager startMonitoringForRegion:beacon];
            [self.locationManager startRangingBeaconsInRegion:beacon];
        }
        
        if (self.beaconActive)
        {
            // Start advertising the beacon's region
            [self.peripheralManager startAdvertising:self.beaconPeripheralData];
        }
    }
    self.started = YES;
}

- (void)stop
{
    // Stop location updates
    if (self.useGPS)
    {
        [self.locationManager stopUpdatingLocation];
    }
    
    if (self.useBeacon)
    {
        // Stop monitoring all ibeaocn regions
        for (id beaconKey in self.beacons.allKeys)
        {
            CLBeaconRegion *beacon = [self.beacons objectForKey:beaconKey];
            
            [self.locationManager stopMonitoringForRegion:beacon];
            [self.locationManager stopRangingBeaconsInRegion:beacon];
        }
        
        // Stop advertise own ibeacon region
        [self.peripheralManager stopAdvertising];
    }
    self.started = NO;
}


- (void)registerBeaconRegionWithUUID:(NSString *)proximityUUID
{
    if (self.useBeacon)
    {
        // Create the beacon region to be monitored
        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc]
                                        initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:proximityUUID]
                                        identifier:[MHComputation makeUniqueStringFromSource:proximityUUID]];
        
        [self.beacons setObject:beaconRegion forKey:proximityUUID];
        
        [self.beaconsProximity setObject:@(CLProximityUnknown) forKey:proximityUUID];
        
        
        if(self.started)
        {
            // Register the beacon region with the location manager
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)unregisterBeaconRegionWithUUID:(NSString *)proximityUUID
{
    if (self.useBeacon)
    {
        CLBeaconRegion *beaconRegion = [self.beacons objectForKey:proximityUUID];
        
        // Stop monitoring region
        if(self.started)
        {
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        }
        
        // Remove region
        [self.beacons removeObjectForKey:proximityUUID];
        [self.beaconsProximity removeObjectForKey:proximityUUID];
    }
}

- (MHLocation*)getGPSPosition
{
    MHLocation *loc = [[MHLocation alloc] init];
    loc.x = self.position.x;
    loc.y = self.position.y;
    
    return loc;
}

- (MHLocation*)getMPosition
{
    MHLocation *loc = [[MHLocation alloc] init];
    
    if (self.useGPS)
    {
        MHLocation *origin = [[MHLocation alloc] init];
        origin.x = 0.0;
        origin.y = 0.0;
        
        MHLocation *target = [[MHLocation alloc] init];
        
        // Calculating x axis of GPS position in meters
        target.x = self.position.x;
        target.y = 0.0;
        loc.x = [MHLocationManager getDistanceFromGPSLocation:origin toGPSLocation:target] * [MHComputation sign:self.position.x];
        
        // Calculating y axis of GPS position in meters
        target.x = 0.0;
        target.y = self.position.y;
        loc.y = [MHLocationManager getDistanceFromGPSLocation:origin toGPSLocation:target] * [MHComputation sign:self.position.y];
    }
    else
    {
        loc.x = arc4random_uniform([MHConfig getSingleton].netDeviceTransmissionRange);
        loc.y = arc4random_uniform([MHConfig getSingleton].netDeviceTransmissionRange);
    }

    
    return loc;
}


- (CLProximity)getProximityForUUID:(NSString *)proximityUUID
{
    if (self.useBeacon)
    {
        NSNumber *proximity = [self.beaconsProximity objectForKey:proximityUUID];
        
        if(proximity == nil)
        {
            return CLProximityUnknown;
        }
        
        return [proximity integerValue];
    }
    else
    {
        return CLProximityUnknown;
    }
}


#pragma mark - CCLocationManagerDelegate methods
- (void) locationManager:(CLLocationManager *)manager
     didUpdateToLocation:(CLLocation *)newLocation
            fromLocation:(CLLocation *)oldLocation
{
    self.position.x = newLocation.coordinate.longitude;
    self.position.y = newLocation.coordinate.latitude;
}

- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error
{
    NSLog(@"The Location Manager encountered an error");
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    if ([beacons count] > 0) {
        CLBeacon *nearestExhibit = [beacons firstObject];

        // The proximity value for the specified region
        [self.beaconsProximity setObject:@(nearestExhibit.proximity) forKey:[region.proximityUUID UUIDString]];
    }
}

#pragma mark - CBPeripheralManagerDelegate methods
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if(peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        NSLog(@"Ibeacon unsupported");
    }
    else if(peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        if(self.started && self.useBeacon)
        {
            // Start advertising the beacon's region (important to start only now)
            [self.peripheralManager startAdvertising:self.beaconPeripheralData];
        }
        
        self.beaconActive = YES;
    }
    else if(peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        // Stop advertising region
        if (self.started)
        {
            [self.peripheralManager stopAdvertising];
        }
        
        self.beaconActive = NO;
    }
}


#pragma mark - Singleton methods
+ (void)setBeaconIDWithPeerID:(NSString*)peerID
{
    beaconID = peerID;
}

+ (void)useGPS:(BOOL)use
{
    useGPS = use;
}

+ (void)useBeacon:(BOOL)use
{
    useBeacon = use;
}

+ (MHLocationManager*)getSingleton
{
    if (locationManager == nil)
    {
        // Initialize location manager singleton
        locationManager = [[MHLocationManager alloc] initWithBeaconID:beaconID
                                                              withGPS:useGPS
                                                           withBeacon:useBeacon];
    }
    
    return locationManager;
}



#pragma mark - GPS methods
// We assume these are meter coordinates
+ (double)getDistanceFromMLocation:(MHLocation*)l1 toMLocation:(MHLocation*)l2
{
    return sqrt(pow((l2.x - l1.x), 2) + pow((l2.y - l1.y), 2));
}


// We assume these are GPS coordinates
+ (double)getDistanceFromGPSLocation:(MHLocation*)l1 toGPSLocation:(MHLocation*)l2
{
    double R = 6371000.0; // Earth radius (m)
    double dLat = [MHComputation toRad:(l2.y-l1.y)];
    double dLon = [MHComputation toRad:(l2.x-l1.x)];
    double lat1 = [MHComputation toRad:l1.y];
    double lat2 = [MHComputation toRad:l2.y];
    
    double a = sin(dLat/2.0) * sin(dLat/2.0) + sin(dLon/2.0) * sin(dLon/2.0) * cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1.0-a));
    double d = R * c;
    
    return d;
}

@end
