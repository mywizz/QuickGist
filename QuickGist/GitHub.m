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
#import "GitHubAPIRequest.h"

static NSString *const apiCreateGistURL = @"https://api.github.com/gists";
static NSString *const apiUserURL       = @"https://api.github.com/user";
static NSString *const apiTokenURL      = @"https://github.com/login/oauth/access_token";

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
        {
            _apiGistRequestURL = [NSString stringWithFormat:
                                  @"https://github.com/login/oauth/authorize?client_id=%@&scope=gist",
                                  self.clientId];
        }
    }
    
    return _apiGistRequestURL;
}

#pragma mark - Public
- (void)requestDataForType:(GitHubRequestType)dataType withData:(id)data
{
    NSMutableURLRequest *req;
    NSString * HTTPMethod;
    id postData;
    
    switch (dataType) {
        case GitHubRequestTypeCreateGist:
            if ([data isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *dict = (NSDictionary *)data;
                
                for (id key in dict)
                    NSLog(@"%@", [dict objectForKey:key]);
                HTTPMethod = @"POST";
                [req setURL:[NSURL URLWithString:@""]];
            }
            break;
            
        case GitHubRequestTypeAccessToken:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *code = (NSString*)data;
                 postData = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@",
                                         self.clientId, self.clientSecret, code];
                HTTPMethod = @"POST";
                req = [[NSMutableURLRequest alloc]
                       initWithURL:[NSURL URLWithString:apiTokenURL]];
            }
            break;
            
        default:
            break;
    }
    
    if (req)
    {
        if (postData)
            [req setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
            
        [req setHTTPMethod:HTTPMethod];
        [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [req addValue:self.options.useragent forHTTPHeaderField:@"User-Agent"];
        
        GitHubAPIRequest *apiReq = [[GitHubAPIRequest alloc] init];
        [apiReq setDelegate:self];
        [apiReq submitRequest:req forDataType:dataType];
    }
}

- (void)handleData:(id)responseData forDataType:(GitHubRequestType)requestType
{
    switch (requestType) {
        case GitHubRequestTypeCreateGist:
            //
            break;
            
        case GitHubRequestTypeAccessToken:
            if ([responseData isKindOfClass:[NSString class]])
            {
                NSString *token = (NSString *)responseData;
                
                /** Let's request the user data, and the gists
                 now that we have a token. */
                
                if (!self.options.user)
                    [self getUserDataAndGistsFromToken:token];
                
                /** Process the token for user defaults */
                NSData *data = [token dataUsingEncoding:NSUTF8StringEncoding];
                [[NSUserDefaults standardUserDefaults] setValue:data forKey:kOAuthToken];
            }
            break;
            
        default:
            break;
    }
    
    [self.delegate update];
}


- (void)getUserDataAndGistsFromToken:(NSString *)token
{
    
}


@end
