//
//  NCKActivity.h
//  NextcloudTalk
//
//  Created by StevalbertS on 20/11/2021.
//

//#ifndef NCKActivity_h
//#define NCKActivity_h
//
//
//#endif /* NCKActivity_h */

#import <Foundation/Foundation.h>


@interface NCKActivity : NSObject

@property (nonatomic, assign) NSInteger activityId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, assign) NSString *userId;
@property (nonatomic, assign) NSInteger activityType;
@property (nonatomic, assign) BOOL approved;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL canceled;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger talkingSince;

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict;
+ (NSMutableDictionary *)indexedActivitiesFromUsersArray:(NSArray *)activities;

//+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict andAccountId:(NSString *)accountId;

@end
