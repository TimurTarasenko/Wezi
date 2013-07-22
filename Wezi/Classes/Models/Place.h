//
//  Place.h
//  Wezi
//
//  Created by Evgeniy Karkan on 21.05.13.
//  Copyright (c) 2013 EvgenyKarkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Place : NSManagedObject

@property (nonatomic, readwrite)	double latitude;
@property (nonatomic, readwrite)	double longitude;
@property (nonatomic, retain)		NSString * city;

@end
