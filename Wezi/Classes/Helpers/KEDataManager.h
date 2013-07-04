//
//  KEDataManager.h
//  Wezi
//
//  Created by Каркан Евгений on 19.05.13.
//  Copyright (c) 2013 EvgenyKarkan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KEAppDelegate;

@interface KEDataManager : NSObject

+ (KEDataManager *)sharedDataManager;
- (KEAppDelegate *)returnAppDelegate;
- (NSManagedObjectContext *)managedObjectContextFromAppDelegate;
- (NSFetchRequest *)requestWithEntityName:(NSString *)entity;


@end
