//
//  Gist.m
//  QuickGist
//
//  Created by Rob Johnson on 5/14/13.
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

#import "Gist.h"

@implementation Gist


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.gistId         = [aDecoder decodeObjectForKey:@"gistId"];
        self.description    = [aDecoder decodeObjectForKey:@"description"];
        self.url            = [aDecoder decodeObjectForKey:@"url"];
        self.forks_url      = [aDecoder decodeObjectForKey:@"forks_url"];
        self.commits_url    = [aDecoder decodeObjectForKey:@"commits_url"];
        self.git_pull_url   = [aDecoder decodeObjectForKey:@"git_pull_url"];
        self.git_push_url   = [aDecoder decodeObjectForKey:@"git_push_url"];
        self.html_url       = [aDecoder decodeObjectForKey:@"html_url"];
        self.comments_url   = [aDecoder decodeObjectForKey:@"comments_url"];
        self.created_at     = [aDecoder decodeObjectForKey:@"created_at"];
        self.updated_at     = [aDecoder decodeObjectForKey:@"updated_at"];
        
        self.files          = [aDecoder decodeObjectForKey:@"files"];
        self.history        = [aDecoder decodeObjectForKey:@"history"];
        self.forks          = [aDecoder decodeObjectForKey:@"forks"];
        self.user           = [aDecoder decodeObjectForKey:@"user"];
        
        self.comments       = [aDecoder decodeIntegerForKey:@"comments"];
        
        self.pub            = [aDecoder decodeBoolForKey:@"pub"];
        self.anonymous      = [aDecoder decodeBoolForKey:@"anonymous"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.gistId        forKey:@"gistId"];
    [aCoder encodeObject:self.description   forKey:@"description"];
    [aCoder encodeObject:self.url           forKey:@"url"];
    [aCoder encodeObject:self.forks_url     forKey:@"forks_url"];
    [aCoder encodeObject:self.commits_url   forKey:@"commits_url"];
    [aCoder encodeObject:self.git_pull_url  forKey:@"git_pull_url"];
    [aCoder encodeObject:self.git_push_url  forKey:@"git_push_url"];
    [aCoder encodeObject:self.html_url      forKey:@"html_url"];
    [aCoder encodeObject:self.comments_url  forKey:@"comments_url"];
    [aCoder encodeObject:self.created_at    forKey:@"created_at"];
    [aCoder encodeObject:self.updated_at    forKey:@"updated_at"];
    
    [aCoder encodeObject:self.files         forKey:@"files"];
    [aCoder encodeObject:self.history       forKey:@"history"];
    [aCoder encodeObject:self.forks         forKey:@"forks"];
    [aCoder encodeObject:self.user          forKey:@"user"];
    
    [aCoder encodeInteger:self.comments     forKey:@"comments"];
    
    [aCoder encodeBool:self.pub             forKey:@"pub"];
    [aCoder encodeBool:self.anonymous       forKey:@"anonymous"];
}


@end
