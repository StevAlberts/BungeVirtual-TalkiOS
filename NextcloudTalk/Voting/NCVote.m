//
//  NCVote.m
//  NextcloudTalk
//
//  Created by StevalbertS on 04/01/2022.
//

#import "NCVote.h"
#import <Foundation/Foundation.h>

@implementation NCVote

+ (instancetype)activityWithDictionary:(NSDictionary *)voteDict
{    
    if (!voteDict) {
        return nil;
    }
        
    NCVote *vote = [[self alloc] init];
    vote.voteId = [[voteDict objectForKey:@"id"] integerValue];
    vote.title = [voteDict objectForKey:@"title"];
    vote.descriptn = [voteDict objectForKey:@"description"];
    vote.owner = [voteDict objectForKey:@"owner"];
    vote.created = [[voteDict objectForKey:@"created"] integerValue];
    vote.expire = [[voteDict objectForKey:@"expire"] integerValue];
    vote.voteType = [voteDict objectForKey:@"voteType"];
    vote.notifMins = [[voteDict objectForKey:@"notifMins"] integerValue];
    vote.meetingName = [voteDict objectForKey:@"meetingName"];
    vote.meetingId = [voteDict objectForKey:@"meetingId"];
    vote.openingTime = [[voteDict objectForKey:@"openingTime"] integerValue];

    return vote;
}

@end
