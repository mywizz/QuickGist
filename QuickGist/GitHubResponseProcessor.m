//
//  GitHubResponseProcessor.m
//  QuickGist
//
//  Created by Rob Johnson on 5/16/13.
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

#import "GitHubResponseProcessor.h"
#import "Gist.h"
#import "GistFile.h"
#import "GitHubUser.h"

@implementation GitHubResponseProcessor

- (id)processData:(NSData *)data forReqestType:(GitHubRequestType)requestType
{
    id processedData;
    
    switch (requestType) {
        case GitHubRequestTypeCreateGist:
            processedData = [self processCreateGistResponse:data];
            break;
        case GitHubRequestTypeAccessToken:
            processedData = [self processTokenResponse:data];
            break;
        case GitHubRequestTypeGetUser:
            processedData = [self processGetUserResponse:data];
            break;
        case GitHubRequestTypeGetUserAvatar:
            processedData = data;
            break;
        case GitHubRequestTypeGetGist:
            processedData = [self processGetGistResponse:data];
            break;
        case GitHubRequestTypeGetAllGists:
            processedData = [self processGetAllGistsResponse:data];
            break;
            
        default:
            break;
    }
 
    return processedData;
}

- (Gist *)processCreateGistResponse:(NSData *)data
{
    Gist *gist;
    GitHubUser *user;
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    if ([json objectForKey:@"message"])
        NSLog(@"GitHub response: %@", [json objectForKey:@"message"]);
    
    else if (json)
    {
        gist = [[Gist alloc] init];
        
        /** Setup the gist files */
        NSDictionary *files = [[NSDictionary alloc]
                              initWithDictionary:[json objectForKey:@"files"]];
        NSMutableArray *filesArray = [[NSMutableArray alloc] init];
        
        for (id key in files)
        {
            NSDictionary *file = [files objectForKey:key];
            GistFile *gistfile = [[GistFile alloc] init];
            
            gistfile.content   = [file objectForKey:@"content"];
            gistfile.filename  = [file objectForKey:@"filename"];
            gistfile.language  = [file objectForKey:@"language"];
            gistfile.type      = [file objectForKey:@"type"];
            gistfile.raw_url   = [file objectForKey:@"raw_url"];
            gistfile.size      = [[file objectForKey:@"size"] integerValue];
            [filesArray addObject:gistfile];
        }
        if ([filesArray count])
            gist.files = filesArray;
        
        gist.history = [json objectForKey:@"history"];
        
        if (![[json objectForKey:@"user"] isKindOfClass:[NSNull class]])
        {
            /** The question is, how much do we really need to know about
             ourselves right now?*/
            NSDictionary *userData = (NSDictionary*)[json objectForKey:@"user"];
            
            if (userData) {
                user = [[GitHubUser alloc] init];
                user.login = [userData objectForKey:@"login"];
                user.userId = [userData objectForKey:@"id"];
                user.avatar_url = [userData objectForKey:@"avatar_url"];
                user.html_url = [userData objectForKey:@"html_url"];
                user.url = [userData objectForKey:@"url"];
            }
        }
        
        if (user)
            gist.user = user;
        
        /** The easy stuff */
        gist.comments_url   = [json objectForKey:@"comments_url"];
        gist.commits_url    = [json objectForKey:@"commits_url"];
        gist.created_at     = [json objectForKey:@"created_at"];
        gist.description    = [json objectForKey:@"description"];
        gist.forks_url      = [json objectForKey:@"forks_url"];        
        gist.git_pull_url   = [json objectForKey:@"git_pull_url"];
        gist.git_push_url   = [json objectForKey:@"git_push_url"];
        gist.html_url       = [json objectForKey:@"html_url"];
        gist.gistId         = [json objectForKey:@"id"];
        gist.updated_at     = [json objectForKey:@"updated_at"];
        gist.url            = [json objectForKey:@"url"];
        
        gist.pub            = [[json objectForKey:@"public"] boolValue];
        gist.anonymous      = (gist.user.login == nil);
    }
    
    return gist;
}

- (NSString *)processTokenResponse:(NSData *)data
{
    NSString *token = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSString *access = @"access_token=";
    NSRange range = [token rangeOfString:access];
    
    if (range.location!=NSNotFound)
    {
        token = [token stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
        token = [token stringByReplacingOccurrencesOfString:@"&token_type=bearer" withString:@""];
    }
    
    return token;
}

- (GitHubUser *)processGetUserResponse:(NSData *)data
{
    GitHubUser *user = [[GitHubUser alloc] init];;
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    
    user.userId              = [json objectForKey:@"id"];
    user.login               = [json objectForKey:@"login"];
    user.name                = [json objectForKey:@"name"];
    user.avatar_url          = [json objectForKey:@"avatar_url"];
    user.gravatar_id         = [json objectForKey:@"gravatar_id"];
    user.url                 = [json objectForKey:@"url"];
    user.html_url            = [json objectForKey:@"html_url"];
    user.followers_url       = [json objectForKey:@"followers_url"];
    user.following_url       = [json objectForKey:@"following_url"];
    user.gists_url           = [json objectForKey:@"gists_url"];
    user.starred_url         = [json objectForKey:@"starred_url"];
    user.subscriptions_url   = [json objectForKey:@"subscriptions_url"];
    user.organizations_url   = [json objectForKey:@"organizations_url"];
    user.repos_url           = [json objectForKey:@"repos_url"];
    user.events_url          = [json objectForKey:@"events_url"];
    user.received_events_url = [json objectForKey:@"received_events_url"];
    user.type                = [json objectForKey:@"type"];
    user.company             = [json objectForKey:@"company"];
    user.location            = [json objectForKey:@"location"];
    user.email               = [json objectForKey:@"email"];
    user.bio                 = [json objectForKey:@"bio"];
    user.created_at          = [json objectForKey:@"created_at"];
    user.updated_at          = [json objectForKey:@"updated_at"];
    
    user.public_repos        = [[json objectForKey:@"public_repos"] integerValue];
    user.public_gists        = [[json objectForKey:@"public_gists"] integerValue];
    user.followers           = [[json objectForKey:@"followers"] integerValue];
    user.following           = [[json objectForKey:@"following"] integerValue];
    
    user.hireable            = [[json objectForKey:@"hireable"] boolValue];
    
    
    return user;
}

- (Gist *)processGetGistResponse:(NSData *)data
{
    Gist *gist;
    
    return gist;
}

- (NSArray *)processGetAllGistsResponse:(NSData *)data
{
    NSMutableArray *gists;
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if ([json isKindOfClass:[NSArray class]]) {
        
        gists = [[NSMutableArray alloc] init];
        NSArray *jsonArray = (NSArray *)json;
        
        [jsonArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *gistDict = (NSDictionary*)[jsonArray objectAtIndex:idx];
            Gist *gist = [[Gist alloc] init];
            GitHubUser *user;
            
            /** Setup the gist files */
            NSDictionary *files = [[NSDictionary alloc]
                                   initWithDictionary:[gistDict objectForKey:@"files"]];
            NSMutableArray *filesArray = [[NSMutableArray alloc] init];
            
            for (id key in files)
            {
                NSDictionary *file = [files objectForKey:key];
                GistFile *gistfile = [[GistFile alloc] init];
                
                //gistfile.content   = [file objectForKey:@"content"];
                gistfile.filename  = [file objectForKey:@"filename"];
                gistfile.language  = [file objectForKey:@"language"];
                gistfile.type      = [file objectForKey:@"type"];
                gistfile.raw_url   = [file objectForKey:@"raw_url"];
                gistfile.size      = [[file objectForKey:@"size"] integerValue];
                [filesArray addObject:gistfile];
            }
            if ([filesArray count])
                gist.files = filesArray;
            
            // gist.history = [json objectForKey:@"history"];
            
            if (![[gistDict objectForKey:@"user"] isKindOfClass:[NSNull class]])
            {
                /** The question is, how much do we really need to know about
                 ourselves right now?*/
                NSDictionary *userData = (NSDictionary*)[gistDict objectForKey:@"user"];
                
                if (userData) {
                    user = [[GitHubUser alloc] init];
                    user.login = [userData objectForKey:@"login"];
                    user.userId = [userData objectForKey:@"id"];
                    user.avatar_url = [userData objectForKey:@"avatar_url"];
                    user.html_url = [userData objectForKey:@"html_url"];
                    user.url = [userData objectForKey:@"url"];
                }
            }
            
            if (user)
                gist.user = user;
            
            /** The easy stuff */
            gist.comments_url   = [gistDict objectForKey:@"comments_url"];
            gist.commits_url    = [gistDict objectForKey:@"commits_url"];
            gist.created_at     = [gistDict objectForKey:@"created_at"];
            gist.description    = [gistDict objectForKey:@"description"];
            gist.forks_url      = [gistDict objectForKey:@"forks_url"];
            gist.git_pull_url   = [gistDict objectForKey:@"git_pull_url"];
            gist.git_push_url   = [gistDict objectForKey:@"git_push_url"];
            gist.html_url       = [gistDict objectForKey:@"html_url"];
            gist.gistId         = [gistDict objectForKey:@"id"];
            gist.updated_at     = [gistDict objectForKey:@"updated_at"];
            gist.url            = [gistDict objectForKey:@"url"];
            
            gist.pub            = [[gistDict objectForKey:@"public"] boolValue];
            gist.anonymous      = (gist.user.login == nil);
           
            [gists addObject:gist];
        }];
    }
    
    return gists;
}

@end
