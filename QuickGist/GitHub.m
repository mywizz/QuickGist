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

/** api URLS */
static NSString *const apiGistsURL = @"https://api.github.com/gists";
static NSString *const apiUserURL  = @"https://api.github.com/user";
static NSString *const apiTokenURL = @"https://github.com/login/oauth/access_token";
static NSString *const apiAuthURL = @"https://github.com/login/oauth/authorize?client_id=%@&scope=gist";
static NSString *const apiGistIdURL = @"%@/%@";

/** api data */
static NSString *const apiBearer = @"bearer %@";
static NSString *const gistFileAndContent = @"\"%@\": { \"content\": \"%@\" } ";
static NSString *const apiTokenRequest = @"client_id=%@&client_secret=%@&code=%@";

/** Request header methods */
static NSString *const HeaderMethodGet = @"GET";
static NSString *const HeaderMethodPost = @"POST";
static NSString *const HeaderMethodDelete = @"DELETE";
static NSString *const HeaderAuth = @"Authorization";

/** Request header fields */
static NSString *const HeaderFieldContent = @"Content-Type";
static NSString *const HeaderFieldModifiedSince = @"If-Modified-Since";
static NSString *const HeaderFieldAcceptEncoding = @"Accept-Encoding";
static NSString *const HeaderFieldUserAgent = @"User-Agent";

/** Request header values */
static NSString *const HeaderValueJSON = @"text/json";
static NSString *const HeaderValueGistJSONData = @"{ \"description\":\"%@\", \"public\": \"%@\", \"files\": { %@ }}";
static NSString *const HeaderValueGzip = @"gzip";

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

- (NSString *)apiTokenRequestURL
{
    if (!_apiGistRequestURL && self.options.clientId)
        _apiGistRequestURL = [NSString stringWithFormat:apiAuthURL, self.options.clientId];
    
    return _apiGistRequestURL;
}

#pragma mark - Public
- (void)requestDataForType:(GitHubRequestType)dataType withData:(id)data cachedResponse:(BOOL)cached
{
    /** Construct a url request based on dataType, 
     cacheing option and any passed in params */
    
    __block NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
    __block NSString * HTTPMethod;
    __block id postData;
    
    switch (dataType)
    {
        case GitHubRequestTypeCreateGist:
            if ([data isKindOfClass:[Gist class]])
            {
                Gist *gist = (Gist*)data;
                NSString __block *files = @"";
                
                
                [gist.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    GistFile *gistfile = (GistFile *)[gist.files objectAtIndex:idx];
                    NSString *file = [NSString stringWithFormat:gistFileAndContent,
                                      gistfile.filename, gistfile.content];
                    
                    if (idx > 0) file = [NSString stringWithFormat:@", %@", file];
                    files = [files stringByAppendingString:file];
                }];
                
                [req setURL:[NSURL URLWithString:apiGistsURL]];
                HTTPMethod = HeaderMethodPost;
                
                NSString *public = @"true";
                if (self.options.secret)
                    public = @"false";
                
                postData = [NSString stringWithFormat:HeaderValueGistJSONData,
                            gist.description, public, files ];
                
                if (self.options.user.useAccount)
                    [req setValue:[NSString stringWithFormat:apiBearer, self.options.token] forHTTPHeaderField:HeaderAuth];
                
                [req setValue:HeaderValueJSON forHTTPHeaderField:HeaderFieldContent];
            }
            break;
            
        case GitHubRequestTypeAccessToken:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *code = (NSString*)data;
                [req setURL:[NSURL URLWithString:apiTokenURL]];
                HTTPMethod = HeaderMethodPost;
                postData = [NSString stringWithFormat:apiTokenRequest, self.options.clientId, self.options.clientSecret, code];
            }
            break;
            
        case GitHubRequestTypeGetUser:
            [req setURL:[NSURL URLWithString:apiUserURL]];
            [req setValue:[NSString stringWithFormat:apiBearer, self.options.token] forHTTPHeaderField:HeaderAuth];
            HTTPMethod = HeaderMethodGet;
            break;
            
        case GitHubRequestTypeGetUserAvatar:
            [req setURL:[NSURL URLWithString:self.options.user.avatar_url]];
            HTTPMethod = HeaderMethodGet;
            break;
            
        case GitHubRequestTypeGetGist:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *gistId = (NSString*)data;
                NSString *url = [NSString stringWithFormat:apiGistIdURL, apiGistsURL, gistId];
                [req setURL:[NSURL URLWithString:url]];
            }
            [req setValue:[NSString stringWithFormat:apiBearer, self.options.token] forHTTPHeaderField:HeaderAuth];
            HTTPMethod = HeaderMethodGet;
            break;
            
        case GitHubRequestTypeGetAllGists:
            [req setURL:[NSURL URLWithString:apiGistsURL]];
            [req setValue:[NSString stringWithFormat:apiBearer, self.options.token] forHTTPHeaderField:HeaderAuth];
            HTTPMethod = HeaderMethodGet;
            break;
            
        case GitHubRequestTypeDeleteGist:
            if ([data isKindOfClass:[NSString class]])
            {
                NSString *gistId = (NSString*)data;
                [req setURL:[NSURL URLWithString:[NSString stringWithFormat:apiGistIdURL, apiGistsURL, gistId]]];
            }
            [req setValue:[NSString stringWithFormat:apiBearer, self.options.token] forHTTPHeaderField:HeaderAuth];
            HTTPMethod = HeaderMethodDelete;
            break;
            
        default:
            break;
    }
    
    if (postData)
        [req setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (cached)
        [req setValue:self.options.lastRequest forHTTPHeaderField:HeaderFieldModifiedSince];
    
    [req setHTTPMethod:HTTPMethod];
    [req setValue:HeaderValueGzip forHTTPHeaderField:HeaderFieldAcceptEncoding];
    [req addValue:self.options.useragent forHTTPHeaderField:HeaderFieldUserAgent];
    
    GitHubAPIRequest *apiReq = [[GitHubAPIRequest alloc] init];
    [apiReq setDelegate:self];
    [apiReq submitRequest:req forDataType:dataType];
}


#pragma mark - GitHub Request Delegate
- (void)handleData:(id)responseData forDataType:(GitHubRequestType)requestType fromLastRequest:(NSString *)lastRequest
{
    /** Handle processed data based on data type
     and expected return type. */
    
    switch (requestType)
    {
        case GitHubRequestTypeCreateGist:
            if ([responseData isKindOfClass:[Gist class]])
            {
                Gist* gist = (Gist*)responseData;
                
                void(^addToGistsHistory)(Gist*) = ^(Gist* gist)
                {
                    /** If the gist to the correct array based on gist.anonymous */
                    (gist.anonymous) ? [self.options.anonGists addObject:gist]
                                     : [self.options.gists addObject:gist];
                    
                    NSData *gistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.gists];
                    [[NSUserDefaults standardUserDefaults] setObject:gistsData forKey:kHistory];
                    
                    NSData *anaonGistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.anonGists];
                    [[NSUserDefaults standardUserDefaults] setObject:anaonGistsData forKey:kAnonHistory];
                    
                };
                
                addToGistsHistory(gist);
                
                /** Copy the new gist url to the clipboard */
                NSPasteboard *pboard = [NSPasteboard generalPasteboard];
                NSArray *objectsToCopy = [[NSArray alloc] initWithObjects:gist.html_url, nil];
                [pboard clearContents];
                [pboard writeObjects:objectsToCopy];
                
                NSString *title = [NSString stringWithFormat:@"%@ created", gist.description];
                [self.delegate update];
                [self.delegate postUserNotification:title subtitle:gist.html_url];
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
                GitHubUser *user = (GitHubUser*)responseData;
                /** Set the users initial option to post gists to the users account. */
                user.useAccount = YES;
                self.options.user = user;
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user];
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
                __block Gist *gist = (Gist*)responseData;
                if (![self.options.gists count])
                    [self.options.gists addObject:gist];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gistId == %@", gist.gistId];
                NSArray *filteredArray = [self.options.gists filteredArrayUsingPredicate:predicate];

                if (![filteredArray count])
                    [self.options.gists addObject:gist];

                else if ([filteredArray count] > 0)
                {
                    __block Gist *_gist = (Gist*)[filteredArray objectAtIndex:0];
                    
                    [self.options.gists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        Gist *exitingGist = (Gist*)[self.options.gists objectAtIndex:idx];
                        
                        if ([gist.gistId isEqualToString:exitingGist.gistId])
                        {
                            if (![gist.updated_at isEqualToString:exitingGist.updated_at])
                            {
                                [self.options.gists removeObjectAtIndex:idx];
                                [self.options.gists addObject:_gist];
                                *stop = YES;
                            }
                        }
                    }];
                }
                
                NSData *gistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.gists];
                [[NSUserDefaults standardUserDefaults] setObject:gistsData forKey:kHistory];
            }
            break;
            
        case GitHubRequestTypeGetAllGists:
            if ([responseData isKindOfClass:[NSArray class]])
            {
                NSArray *gists = (NSArray *)responseData;
                
                [gists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    Gist *gist = (Gist*)[gists objectAtIndex:idx];
                    [self requestDataForType:GitHubRequestTypeGetGist
                                    withData:gist.gistId
                              cachedResponse:YES];
                }];
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
                              cachedResponse:YES];
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

- (void)processRemainingApiCalls:(NSString *)apiCallsString
{
    self.options.remainingAPICalls = apiCallsString;
    [self.delegate updateApiCallsLabel];
}

@end
