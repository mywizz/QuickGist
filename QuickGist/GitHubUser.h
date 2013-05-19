//
//  GitHubUser.h
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

#import <Foundation/Foundation.h>

@interface GitHubUser : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *login;
@property (nonatomic, strong) NSString *avatar_url;
@property (nonatomic, strong) NSString *gravatar_id;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *html_url;
@property (nonatomic, strong) NSString *followers_url;
@property (nonatomic, strong) NSString *following_url;
@property (nonatomic, strong) NSString *gists_url;
@property (nonatomic, strong) NSString *starred_url;
@property (nonatomic, strong) NSString *subscriptions_url;
@property (nonatomic, strong) NSString *organizations_url;
@property (nonatomic, strong) NSString *repos_url;
@property (nonatomic, strong) NSString *events_url;
@property (nonatomic, strong) NSString *received_events_url;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *company;
@property (nonatomic, strong) NSString *blog;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *created_at;
@property (nonatomic, strong) NSString *updated_at;

@property (nonatomic, strong) NSData   *avatar;


@property (nonatomic) NSInteger public_repos;
@property (nonatomic) NSInteger public_gists;
@property (nonatomic) NSInteger followers;
@property (nonatomic) NSInteger following;

@property (nonatomic) BOOL hireable;
@property (nonatomic) BOOL useAccount;



@end
