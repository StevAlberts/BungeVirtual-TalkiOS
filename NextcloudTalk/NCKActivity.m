//
//  NSKActivity.m
//  NextcloudTalk
//
//  Created by StevalbertS on 20/11/2021.
//

#import "NCKActivity.h"
#import <Foundation/Foundation.h>


@implementation NCKActivity

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict
{
    if (!roomDict) {
        return nil;
    }
    
    NCKActivity *activity = [[self alloc] init];
    activity.activityId = [[roomDict objectForKey:@"id"] integerValue];
    activity.token = [roomDict objectForKey:@"token"];
    activity.userId = [roomDict objectForKey:@"userId"];
    activity.activityType = [[roomDict objectForKey:@"activityType"] integerValue];
    activity.approved = [[roomDict objectForKey:@"approved"] boolValue];
    activity.started = [[roomDict objectForKey:@"started"] boolValue];
    activity.paused = [[roomDict objectForKey:@"paused"] boolValue];
    activity.canceled = [[roomDict objectForKey:@"canceled"] boolValue];
    activity.duration = [[roomDict objectForKey:@"duration"] integerValue];
    activity.talkingSince = [[roomDict objectForKey:@"talkingSince"] integerValue];

    return activity;
}

+ (NSMutableDictionary *)indexedActivitiesFromUsersArray:(NSArray *)activities
{
    NSMutableDictionary *indexedActivities = [[NSMutableDictionary alloc] init];
    for (NCKActivity *activity in activities) {
        NSString *index = [[activity.userId substringToIndex:1] uppercaseString];
       
        NSMutableArray *activitiesForIndex = [indexedActivities valueForKey:index];
        if (activitiesForIndex == nil) {
            activitiesForIndex = [[NSMutableArray alloc] init];
        }
        [activitiesForIndex addObject:activity];
        [indexedActivities setObject:activitiesForIndex forKey:index];
    }
    return indexedActivities;
}

@end
