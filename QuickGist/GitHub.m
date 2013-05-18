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

static NSString *const apiGistsURL = @"https://api.github.com/gists";
static NSString *const apiUserURL  = @"https://api.github.com/user";
static NSString *const apiTokenURL = @"https://github.com/login/oauth/access_token";

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

- (NSString *)bearer
{
    return [NSString stringWithFormat:@"bearer %@", self.options.token];
}

#pragma mark - Public
- (void)requestDataForType:(GitHubRequestType)dataType withData:(id)data cachedResponse:(BOOL)cached
{
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
    NSString * HTTPMethod;
    id postData;
    
    switch (dataType) {
        case GitHubRequestTypeCreateGist:
            if ([data isKindOfClass:[Gist class]])
            {
                Gist *gist = (Gist*)data;
                NSString __block *files = @"";
                
                
                for (int i =0; i<[gist.files count]; i++) {
                    GistFile *gistfile = (GistFile *)[gist.files objectAtIndex:i];
                    NSString *file = [NSString stringWithFormat:@"\"%@\": { \"content\": \"%@\" } ",
                                      gistfile.filename, gistfile.content];
                    
                    if (i > 0) file = [NSString stringWithFormat:@", %@", file];
                    files = [files stringByAppendingString:file];
                }
                
                [req setURL:[NSURL URLWithString:apiGistsURL]];
                HTTPMethod = @"POST";
                
                NSString *public = @"true";
                if (self.options.secret) public = @"false";
                
                postData = [NSString stringWithFormat:@"{ \"description\":\"%@\", \"public\": \"%@\", \"files\": { %@ }}",
                            gist.description, public, files ];
                
                if (!self.options.anonymous)
                    [req setValue:[self bearer] forHTTPHeaderField:@"Authorization"];
                
                [req setValue:@"text/json" forHTTPHeaderField:@"Content-Type"];
            }
            break;
            
        case GitHubRequestTypeAccessToken:
            if ([data isKindOfClass:[NSString class]])
            {
                [req setURL:[NSURL URLWithString:apiTokenURL]];
                HTTPMethod = @"POST";
                postData = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@",
                            self.clientId, self.clientSecret, data];
                
            }
            break;
            
        case GitHubRequestTypeGetUser:
            [req setURL:[NSURL URLWithString:apiUserURL]];
            [req setValue:[self bearer] forHTTPHeaderField:@"Authorization"];
            HTTPMethod = @"GET";
            break;
            
        case GitHubRequestTypeGetUserAvatar:
            [req setURL:[NSURL URLWithString:self.options.user.avatar_url]];
            HTTPMethod = @"GET";
            break;
            
        case GitHubRequestTypeGetGist:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *url = [NSString stringWithFormat:@"%@/%@", apiGistsURL, data];
                [req setURL:[NSURL URLWithString:url]];
            }
            [req setValue:[self bearer] forHTTPHeaderField:@"Authorization"];
            HTTPMethod = @"GET";
            break;
            
        case GitHubRequestTypeGetAllGists:
            [req setURL:[NSURL URLWithString:apiGistsURL]];
            [req setValue:[self bearer] forHTTPHeaderField:@"Authorization"];
            HTTPMethod = @"GET";
            break;
            
        case GitHubRequestTypeDeleteGist:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *url = [NSString stringWithFormat:@"%@/%@", apiGistsURL, data];
                [req setURL:[NSURL URLWithString:url]];
            }
            [req setValue:[self bearer] forHTTPHeaderField:@"Authorization"];
            HTTPMethod = @"DELETE";
            break;
            
        default:
            break;
    }
    
    if (req)
    {
        if (postData)
            [req setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (cached)
            [req setValue:self.options.lastRequest forHTTPHeaderField:@"If-Modified-Since"];
        
        [req setHTTPMethod:HTTPMethod];
        [req setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [req addValue:self.options.useragent forHTTPHeaderField:@"User-Agent"];
        
        GitHubAPIRequest *apiReq = [[GitHubAPIRequest alloc] init];
        [apiReq setDelegate:self];
        [apiReq submitRequest:req forDataType:dataType];
    }
}


#pragma mark - GitHub Request Delegate
- (void)handleData:(id)responseData forDataType:(GitHubRequestType)requestType fromLastRequest:(NSString *)lastRequest
{
    switch (requestType)
    {
        case GitHubRequestTypeCreateGist:
            if ([responseData isKindOfClass:[Gist class]])
            {
                Gist* gist = (Gist*)responseData;
                
                void(^addToGistsHistory)(Gist*) = ^(Gist* gist) {
                    (gist.anonymous) ? [self.options.anonGists addObject:gist]
                                     : [self.options.gists addObject:gist];
                    
                    NSData *gistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.gists];
                    [[NSUserDefaults standardUserDefaults] setObject:gistsData forKey:kHistory];
                    
                    NSData *anaonGistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.anonGists];
                    [[NSUserDefaults standardUserDefaults] setObject:anaonGistsData forKey:kAnonHistory];
                    
                };
                
                addToGistsHistory(gist);
                
                NSString *title = [NSString stringWithFormat:@"%@ created", gist.description];
                [self.delegate update];
                [self.delegate postUserNotification:title subtitle:gist.html_url];
                
                /** Copy the new gist url to the clipboard */
                NSPasteboard *pboard = [NSPasteboard generalPasteboard];
                NSArray *objectsToCopy = [[NSArray alloc] initWithObjects:gist.html_url, nil];
                [pboard clearContents];
                [pboard writeObjects:objectsToCopy];
            }
            break;
            
        case GitHubRequestTypeAccessToken:
            if ([responseData isKindOfClass:[NSString class]])
            {
                NSData *data = [responseData dataUsingEncoding:NSUTF8StringEncoding];
                [[NSUserDefaults standardUserDefaults] setValue:data forKey:kOAuthToken];
            }
            break;
            
        case GitHubRequestTypeGetUser:
            if ([responseData isKindOfClass:[GitHubUser class]])
            {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:responseData];
                [[NSUserDefaults standardUserDefaults] setValue:data forKey:kGitHubUser];
            }
            break;
            
        case GitHubRequestTypeGetUserAvatar:
            if ([responseData isKindOfClass:[NSData class]])
            {
                if (self.options.user)
                {
                    self.options.user.avatar = responseData;
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.options.user];
                    [[NSUserDefaults standardUserDefaults] setValue:data forKey:kGitHubUser];
                }
            }
            break;
            
        case GitHubRequestTypeGetGist:
            if ([responseData isKindOfClass:[Gist class]])
            {
                /** Not sure what to do here yet */
            }
            break;
            
        case GitHubRequestTypeGetAllGists:
            if ([responseData isKindOfClass:[NSArray class]])
            {
                NSArray *gists = (NSArray *)responseData;
                NSData *gistsData = [NSKeyedArchiver archivedDataWithRootObject:gists];
                [[NSUserDefaults standardUserDefaults] setObject:gistsData forKey:kHistory];
            }
            break;
            
        case GitHubRequestTypeDeleteGist:
            if ([responseData isKindOfClass:[NSString class]])
            {
                if ([responseData isEqualToString:@"success"]) {
                    [self.delegate postUserNotification:@"Gist deleted"
                                               subtitle:@"Your Gist has been deleted."];
                    
                    [self requestDataForType:GitHubRequestTypeGetAllGists
                                    withData:nil
                              cachedResponse:NO];
                }
            }
            break;
            
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:lastRequest forKey:kLastRequest];
    [self.delegate update];
}

- (void)postUserNotification:(NSString *)title subtitle:(NSString *)subtitle
{
    [self.delegate postUserNotification:title subtitle:subtitle];
}

@end
