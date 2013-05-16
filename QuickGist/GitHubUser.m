//
//  GitHubUser.m
//  QuickGist
//
//  Created by Rob Johnson on 5/15/13.
//  Copyright (c) 2013 CornDog Computers. All rights reserved.
//
//   _____              ___              _____                     __
//  / ___/__  _______  / _ \___  ___ _  / ___/__  __ _  ___  __ __/ /____ _______
// / /__/ _ \/ __/ _ \/ // / _ \/ _ `/ / /__/ _ \/  ' \/ _ \/ // / __/ -_) __(_-<
// \___/\___/_/ /_//_/____/\___/\_, /  \___/\___/_/_/_/ .__/\_,_/\__/\__/_/ /___/
//                             /___/                 /_/
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1.  Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//  2.  Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//  3.  The name of the author may not be used to endorse or promote products
//      derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "GitHubUser.h"

@implementation GitHubUser

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        /** NSStrings ------------------------------------------------------------------ */
        self.login               = [aDecoder decodeObjectForKey:@"login"];
        self.userId              = [aDecoder decodeObjectForKey:@"userId"];
        self.avatar_url          = [aDecoder decodeObjectForKey:@"avatar_url"];
        self.gravatar_id         = [aDecoder decodeObjectForKey:@"gravatar_id"];
        self.url                 = [aDecoder decodeObjectForKey:@"url"];
        self.html_url            = [aDecoder decodeObjectForKey:@"html_url"];
        self.followers_url       = [aDecoder decodeObjectForKey:@"followers_url"];
        self.following_url       = [aDecoder decodeObjectForKey:@"following_url"];
        self.gists_url           = [aDecoder decodeObjectForKey:@"gists_url"];
        self.starred_url         = [aDecoder decodeObjectForKey:@"starred_url"];
        self.subscriptions_url   = [aDecoder decodeObjectForKey:@"subscriptions_url"];
        self.organizations_url   = [aDecoder decodeObjectForKey:@"organizations_url"];
        self.repos_url           = [aDecoder decodeObjectForKey:@"repos_url"];
        self.events_url          = [aDecoder decodeObjectForKey:@"events_url"];
        self.received_events_url = [aDecoder decodeObjectForKey:@"received_events_url"];
        self.type                = [aDecoder decodeObjectForKey:@"type"];
        self.name                = [aDecoder decodeObjectForKey:@"name"];
        self.company             = [aDecoder decodeObjectForKey:@"company"];
        self.blog                = [aDecoder decodeObjectForKey:@"blog"];
        self.location            = [aDecoder decodeObjectForKey:@"location"];
        self.email               = [aDecoder decodeObjectForKey:@"email"];
        self.bio                 = [aDecoder decodeObjectForKey:@"bio"];
        self.created_at          = [aDecoder decodeObjectForKey:@"created_at"];
        self.updated_at          = [aDecoder decodeObjectForKey:@"updated_at"];
        /** NSIntegers ------------------------------------------------------------------ */
        self.public_repos        = [aDecoder decodeIntegerForKey:@"public_repos"];
        self.public_gists        = [aDecoder decodeIntegerForKey:@"public_gists"];
        self.followers           = [aDecoder decodeIntegerForKey:@"followers"];
        self.following           = [aDecoder decodeIntegerForKey:@"following"];
        /** BOOL ------------------------------------------------------------------------ */
        self.hireable            = [aDecoder decodeBoolForKey:@"hireable"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    /** NSStrings ------------------------------------------------------------------ */
    [aCoder encodeObject:self.login               forKey:@"login"];
    [aCoder encodeObject:self.userId              forKey:@"userId"];
    [aCoder encodeObject:self.avatar_url          forKey:@"avatar_url"];
    [aCoder encodeObject:self.gravatar_id         forKey:@"gravatar_id"];
    [aCoder encodeObject:self.url                 forKey:@"url"];
    [aCoder encodeObject:self.html_url            forKey:@"html_url"];
    [aCoder encodeObject:self.followers_url       forKey:@"followers_url"];
    [aCoder encodeObject:self.following_url       forKey:@"following_url"];
    [aCoder encodeObject:self.gists_url           forKey:@"gists_url"];
    [aCoder encodeObject:self.starred_url         forKey:@"starred_url"];
    [aCoder encodeObject:self.subscriptions_url   forKey:@"subscriptions_url"];
    [aCoder encodeObject:self.organizations_url   forKey:@"organizations_url"];
    [aCoder encodeObject:self.repos_url           forKey:@"repos_url"];
    [aCoder encodeObject:self.events_url          forKey:@"events_url"];
    [aCoder encodeObject:self.received_events_url forKey:@"received_events_url"];
    [aCoder encodeObject:self.type                forKey:@"type"];
    [aCoder encodeObject:self.name                forKey:@"name"];
    [aCoder encodeObject:self.company             forKey:@"company"];
    [aCoder encodeObject:self.blog                forKey:@"blog"];
    [aCoder encodeObject:self.location            forKey:@"location"];
    [aCoder encodeObject:self.email               forKey:@"email"];
    [aCoder encodeObject:self.bio                 forKey:@"bio"];
    [aCoder encodeObject:self.created_at          forKey:@"created_at"];
    [aCoder encodeObject:self.updated_at          forKey:@"updated_at"];
    /** NSIntegers ------------------------------------------------------------------ */
    [aCoder encodeInteger:self.public_repos       forKey:@"public_repos"];
    [aCoder encodeInteger:self.public_gists       forKey:@"public_gists"];
    [aCoder encodeInteger:self.followers          forKey:@"followers"];
    [aCoder encodeInteger:self.following          forKey:@"following"];
    /** BOOL ------------------------------------------------------------------------ */
    [aCoder encodeBool:self.hireable              forKey:@"hireable"];
}

@end
