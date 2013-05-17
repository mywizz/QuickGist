//
//  GitHub.m
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

#import "GitHub.h"

@interface GitHub() <GitHubRequestDelegate>

@property (strong, nonatomic) Options *options;
@end

@implementation GitHub

- (id)init
{
    self = [super init];
    if (self) {
        self.options = [Options sharedInstance];
    }
    return self;
}

#pragma mark - Getters
- (NSString *)apiTokenRequestURL
{
    if (!_apiGistRequestURL)
    {
        if (self.clientId)
            _apiGistRequestURL = [NSString stringWithFormat:@"https://github.com/login/oauth/authorize?client_id=%@&scope=gist", self.clientId];
    }
    
    return _apiGistRequestURL;
}

#pragma mark - Public
- (void)requestDataForType:(GitHubRequestType)dataType withData:(id)data
{
    switch (dataType) {
        case GitHubRequestTypeCreateGist:
            if ([data isKindOfClass:[NSDictionary class]])
                for (id key in data) NSLog(@"%@: %@", [key description], [data objectForKey:key]);
            break;
            
        case GitHubRequestTypeAccessToken:
            break;
            
        default:
            break;
    }
    
}

- (void)uploadDataToCreateGist:(NSMutableURLRequest *)request
{
    
}

@end
