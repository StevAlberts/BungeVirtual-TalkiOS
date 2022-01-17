//
//  NCVote.h
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

//#ifndef NCVote_h
//#define NCVote_h
//
//
//#endif /* NCVote_h */
#import <Foundation/Foundation.h>

@interface NCVote : NSObject

@property  NSInteger voteId;
@property  NSString *title;
@property  NSString *descriptn;
@property  NSString *owner;
@property  NSInteger created;
@property  NSInteger expire;
@property  NSString *voteType;
@property  NSInteger notifMins;
@property  NSString *meetingName;
@property  NSString *meetingId;
@property  NSInteger openingTime;

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict;

@end
