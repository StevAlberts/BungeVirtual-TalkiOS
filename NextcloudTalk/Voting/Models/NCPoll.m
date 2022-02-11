//
//  NCPoll.m
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

#import "NCPoll.h"
#import <Foundation/Foundation.h>

@implementation NCPoll

+ (instancetype)activityWithDictionary:(NSDictionary *)pollDict
{
    if (!pollDict) {
        return nil;
    }
    
    NCPoll *poll = [[self alloc] init];
    poll.pollId = [[pollDict objectForKey:@"id"] integerValue];
    poll.title = [pollDict objectForKey:@"title"];
    poll.descriptn = [pollDict objectForKey:@"description"];
    poll.owner = [pollDict objectForKey:@"owner"];
    poll.created = [[pollDict objectForKey:@"created"] integerValue];
    poll.expire = [[pollDict objectForKey:@"expire"] integerValue];
    poll.voteType = [pollDict objectForKey:@"voteType"];
    poll.notifMins = [[pollDict objectForKey:@"notifMins"] integerValue];
    poll.meetingName = [pollDict objectForKey:@"meetingName"];
    poll.meetingId = [pollDict objectForKey:@"meetingId"];
    poll.openingTime = [[pollDict objectForKey:@"openingTime"] integerValue];
    poll.allowView = [[pollDict objectForKey:@"allowView"] boolValue];
    poll.allowVote = [[pollDict objectForKey:@"allowVote"] boolValue];
    poll.displayName = [pollDict objectForKey:@"displayName"];
    poll.isOwner = [[pollDict objectForKey:@"isOwner"] boolValue];
    poll.loggedIn = [[pollDict objectForKey:@"loggedIn"] boolValue];
    poll.userHasVoted = [[pollDict objectForKey:@"userHasVoted"] boolValue];
    poll.userId = [pollDict objectForKey:@"userId"];
    poll.userIsInvolved = [[pollDict objectForKey:@"userIsInvolved"] boolValue];
    poll.pollExpired = [[pollDict objectForKey:@"pollExpired"] boolValue];
    poll.pollExpire = [[pollDict objectForKey:@"pollExpire"] integerValue];

    return poll;
}

@end
