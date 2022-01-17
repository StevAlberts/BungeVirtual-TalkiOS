//
//  NCPoll.h
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

//#ifndef NCPoll_h
//#define NCPoll_h
//
//
//#endif /* NCPoll_h */

#import <Foundation/Foundation.h>

@interface NCPoll : NSObject

@property (nonatomic, assign) NSInteger pollId;
@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString* descriptn;
@property (nonatomic, assign) NSString *owner;
@property (nonatomic, assign) NSInteger created;
@property (nonatomic, assign) NSInteger expire;
@property (nonatomic, assign) NSString *voteType;
@property (nonatomic, assign) NSInteger notifMins;
@property (nonatomic, assign) NSString *meetingName;
@property (nonatomic, assign) NSString *meetingId;
@property (nonatomic, assign) NSInteger openingTime;
@property (nonatomic, assign) BOOL allowView;
@property (nonatomic, assign) BOOL allowVote;
@property (nonatomic, assign) NSString *displayName;
@property (nonatomic, assign) BOOL isOwner;
@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL userHasVoted;
@property (nonatomic, assign) NSString *userId;
@property (nonatomic, assign) BOOL userIsInvolved;
@property (nonatomic, assign) BOOL pollExpired;
@property (nonatomic, assign) NSInteger pollExpire;

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict;

@end
