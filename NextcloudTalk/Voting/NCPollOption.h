//
//  NCPollOption.h
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

#ifndef NCPollOption_h
#define NCPollOption_h


#endif /* NCPollOption_h */

// NCPollOption.h

#import <Foundation/Foundation.h>

@class NCPollOption;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface NCPollOption : NSObject
@property (nonatomic, assign) NSInteger optionId;
@property (nonatomic, assign) NSInteger pollId;
@property (nonatomic, copy)   NSString *owner;
@property (nonatomic, copy)   NSString *ownerDisplayName;
@property (nonatomic, assign) BOOL isOwnerIsNoUser;
@property (nonatomic, assign) NSInteger released;
@property (nonatomic, copy)   NSString *pollOptionText;
@property (nonatomic, assign) NSInteger timestamp;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, assign) NSInteger confirmed;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, assign) NSInteger no;
@property (nonatomic, assign) NSInteger yes;
@property (nonatomic, assign) NSInteger maybe;
@property (nonatomic, assign) NSInteger realNo;
@property (nonatomic, assign) NSInteger votes;
@property (nonatomic, assign) BOOL isBookedUp;

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict;

@end

NS_ASSUME_NONNULL_END
