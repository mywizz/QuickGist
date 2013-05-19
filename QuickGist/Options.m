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
        
        /** Register user defaults */
        [options registerUserDefaults];
        
        /** Update the singleton */
        [options update];
    });
    return options;
}

- (void)update
{
    /** Let's sync any unsaved pref changes before reading
     them to set property values. */
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.token       = [self tokenFromPrefs];
    self.user        = [self userFromPrefs:kGitHubUser];
    self.gists       = [NSMutableArray arrayWithArray:[self arrayFrom:kHistory]];
    self.anonGists   = [NSMutableArray arrayWithArray:[self arrayFrom:kAnonHistory]];
    
    /** Sort with newest gists first */
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:NO];
    self.gists = [NSMutableArray arrayWithArray:[self.gists sortedArrayUsingDescriptors:@[ sorter]]];
    self.anonGists = [NSMutableArray arrayWithArray:[self.anonGists sortedArrayUsingDescriptors:@[ sorter]]];
    
    self.lastRequest = [[NSUserDefaults standardUserDefaults] valueForKey:kLastRequest];
    
    /** BOOL ------------------------------------------------------------------------ */
    self.notice      = [[NSUserDefaults standardUserDefaults] boolForKey:kNotification];
    self.login       = [[NSUserDefaults standardUserDefaults] boolForKey:kLogin];
    self.secret      = [[NSUserDefaults standardUserDefaults] boolForKey:kPublic];
    self.openURL     = [[NSUserDefaults standardUserDefaults] boolForKey:kOpenURL];
}

- (NSString *)useragent
{
    if (!_useragent) {
        NSString *app = [[[NSBundle mainBundle] infoDictionary]
                         objectForKey:@"CFBundleName"];
        
        NSString *ver = [[[NSBundle mainBundle] infoDictionary]
                         objectForKey:@"CFBundleShortVersionString"];
        
        NSString *build = [[[NSBundle mainBundle] infoDictionary]
                           objectForKey:@"CFBundleVersion"];
        
        _useragent = [NSString stringWithFormat:@"%@ version-%@ (%@)", app, ver, build];
    }
    return _useragent;
}

- (NSArray *)arrayFrom:(NSString *)userPrefsKey
{
    NSArray *arr;
    NSData *data = [[NSUserDefaults standardUserDefaults]
                         objectForKey:userPrefsKey];
    if (data)
        arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    else arr = @[];
    
    return arr;
}

- (GitHubUser *)userFromPrefs:(NSString *)userPrefsKey
{
    GitHubUser *user;
    NSData *data = [[NSUserDefaults standardUserDefaults]
                    objectForKey:userPrefsKey];
    if (data)
        user = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return user;
}

- (NSString *)tokenFromPrefs
{
    NSString *token;
    NSData *data = [[NSUserDefaults standardUserDefaults]
                    valueForKey:kOAuthToken];
    if (data)
        token = [[NSString alloc] initWithData:data
                                      encoding:NSUTF8StringEncoding];
    else
        token = @"anonymous";
    
    return token;
}

- (void)registerUserDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithContentsOfFile:
      [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
}

@end
