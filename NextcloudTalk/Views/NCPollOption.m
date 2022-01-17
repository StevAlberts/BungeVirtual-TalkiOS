//
//  NCPollOption.m
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

#import "NCPollOption.h"
#import <Foundation/Foundation.h>

@implementation NCPollOption

+ (instancetype)activityWithDictionary:(NSDictionary *)pollDict
{
    if (!pollDict) {
        return nil;
    }
    
    NCPollOption *poll = [[self alloc] init];
    poll.optionId = [[pollDict objectForKey:@"optionId"] integerValue];
    poll.pollId = [[pollDict objectForKey:@"pollId"] integerValue];
    poll.owner = [pollDict objectForKey:@"owner"];
    poll.ownerDisplayName = [pollDict objectForKey:@"ownerDisplayName"];
    poll.isOwnerIsNoUser = [[pollDict objectForKey:@"isOwnerIsNoUser"] boolValue];
    poll.released = [[pollDict objectForKey:@"released"] integerValue];
    poll.pollOptionText = [pollDict objectForKey:@"pollOptionText"];
    poll.timestamp = [[pollDict objectForKey:@"timestamp"] integerValue];
    poll.order = [[pollDict objectForKey:@"order"] integerValue];
    poll.confirmed = [[pollDict objectForKey:@"confirmed"] integerValue];
    poll.duration = [[pollDict objectForKey:@"duration"] integerValue];
    poll.rank = [[pollDict objectForKey:@"rank"] integerValue];
    poll.no = [[pollDict objectForKey:@"no"] integerValue];
    poll.yes = [[pollDict objectForKey:@"yes"] integerValue];
    poll.maybe = [[pollDict objectForKey:@"maybe"] integerValue];
    poll.realNo = [[pollDict objectForKey:@"realNo"] integerValue];
    poll.votes = [[pollDict objectForKey:@"votes"] integerValue];
    poll.isBookedUp = [[pollDict objectForKey:@"isBookedUp"] boolValue];

    return poll;
}

@end
