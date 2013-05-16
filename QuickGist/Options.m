//
//  Options.m
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

#import "Options.h"

@implementation Options

#pragma mark - Public
+ (id)sharedInstance
{
    /** Create shared instance. */
    static Options *options = nil;
    static dispatch_once_t onceToken;
    
    /** Thread safe singleton. */
    dispatch_once(&onceToken, ^{
        options = [[self alloc] init];
        
        /** Update the singleton */
        [options update];
    });
    return options;
}

- (void)update
{
    /** Let's sync any unsaved pref changes before setting property values. */
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!self.useragent) {
        NSString *app = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        self.useragent = [NSString stringWithFormat:@"%@ version-%@ (%@)", app, ver, build];
    }
    
    /** Read from user prefs to set options properties.
     -------------------------------------------------- */
    
    /** The stored token. */
    NSData *token      = [[NSUserDefaults standardUserDefaults] valueForKey:kOAuthToken];
    NSString *tokenStr = [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding];
    if ([tokenStr isEqualToString:@""]) tokenStr = kAnonymous;
    
    /** The stored username. */
    NSData *user      = [[NSUserDefaults standardUserDefaults] valueForKey:kGitHubUser];
    NSString *userStr = [[NSString alloc] initWithData:user encoding:NSUTF8StringEncoding];
    if ([userStr isEqualToString:@""]) userStr = kAnonymous;
    
    /** Authed user gists */
    NSData *gists   = [[NSUserDefaults standardUserDefaults] objectForKey:kHistory];
    NSArray *gistsArr = [NSKeyedUnarchiver unarchiveObjectWithData:gists];
    
    /** Anonymous gists */
    NSData *anonGists   = [[NSUserDefaults standardUserDefaults] objectForKey:kAnonHistory];
    NSArray *anonGistsArr = [NSKeyedUnarchiver unarchiveObjectWithData:anonGists];
    
    self.token      = tokenStr;
    self.userName   = userStr;
    self.gists      = gistsArr;
    self.anonGists  = anonGistsArr;
    self.lastCheck  = [[NSUserDefaults standardUserDefaults] valueForKey:kLastCheck];
    self.anonymous  = [[NSUserDefaults standardUserDefaults] boolForKey:kAnonymous];
    self.prompt     = [[NSUserDefaults standardUserDefaults] boolForKey:kPrompt];
    self.notice     = [[NSUserDefaults standardUserDefaults] boolForKey:kNotification];
    self.login      = [[NSUserDefaults standardUserDefaults] boolForKey:kLogin];
    self.secret     = [[NSUserDefaults standardUserDefaults] boolForKey:kPublic];
    self.openURL    = [[NSUserDefaults standardUserDefaults] boolForKey:kOpenURL];
    
    if ([self.token isEqualToString:kAnonymous])
    {
        self.auth = NO;
        self.userName = kAnonymous;
    }
    else self.auth = YES;
}

@end
