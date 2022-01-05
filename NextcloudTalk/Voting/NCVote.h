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

@property (nonatomic, assign) NSInteger voteId;
@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *descriptn;
@property (nonatomic, assign) NSString *owner;
@property (nonatomic, assign) NSInteger created;
@property (nonatomic, assign) NSInteger expire;
@property (nonatomic, assign) NSString *voteType;
@property (nonatomic, assign) NSInteger notifMins;
@property (nonatomic, assign) NSString *meetingName;
@property (nonatomic, assign) NSString *meetingId;
@property (nonatomic, assign) NSInteger openingTime;

+ (instancetype)activityWithDictionary:(NSDictionary *)roomDict;

@end
