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

- (Gist *)processCreateGistResponse:(id)data
{
    Gist *gist;
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    if ([json objectForKey:@"message"])
        NSLog(@"GitHub response: %@", [json objectForKey:@"message"]);
    
    else if (json)
        gist = [self processGetGistResponse:json];
    
    return gist;
}

- (NSString *)processTokenResponse:(id)data
{
    NSString *token;
    if (data)
    {
        token = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSString *access = @"access_token=";
        NSRange range = [token rangeOfString:access];
        
        if (range.location!=NSNotFound) {
            token = [token stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
            token = [token stringByReplacingOccurrencesOfString:@"&token_type=bearer" withString:@""];
            /** 
             Added for token response change 11/12/13
             Thanks @blofton
             */
            token = [token stringByReplacingOccurrencesOfString:@"&scope=gist" withString:@""];
        }
    }
    return token;
}

- (GitHubUser *)processGetUserResponse:(id)data
{
    GitHubUser *user;
    if (data)
    {
        NSError *error;
        NSDictionary *json;
        
        if (![data isKindOfClass:[NSDictionary class]])
            json = [NSJSONSerialization JSONObjectWithData:data
                                                   options:kNilOptions
                                                     error:&error];
        else json = data;
        
        if (!user) user = [[GitHubUser alloc] init];
        user.login               = [json objectForKey:@"login"];
        user.userId              = [json objectForKey:@"id"];
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
        
        user.name                = [json objectForKey:@"name"];
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
    }
    
    return user;
}

- (Gist *)processGetGistResponse:(id)data
{
    Gist *gist;
    NSError *error;
    NSDictionary *json;
    
    if (![data isKindOfClass:[NSDictionary class]])
         json = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    else json = data;
    
    if (json)
    {
        if (!gist) gist = [[Gist alloc] init];
        gist.url            = [json objectForKey:@"url"];
        gist.forks_url      = [json objectForKey:@"forks_url"];
        gist.commits_url    = [json objectForKey:@"commits_url"];
        gist.gistId         = [json objectForKey:@"id"];
        gist.git_pull_url   = [json objectForKey:@"git_pull_url"];
        gist.git_push_url   = [json objectForKey:@"git_push_url"];
        gist.html_url       = [json objectForKey:@"html_url"];
        gist.created_at     = [json objectForKey:@"created_at"];
        gist.updated_at     = [json objectForKey:@"updated_at"];
        gist.description    = [json objectForKey:@"description"];
        gist.comments_url   = [json objectForKey:@"comments_url"];
        
        NSDictionary *files = [[NSDictionary alloc] initWithDictionary:[json objectForKey:@"files"]];
        for (id key in files)
        {
            NSDictionary *file = [files objectForKey:key];
            GistFile *gistfile = [[GistFile alloc] init];
            if (!gist.files)
                gist.files = [[NSMutableArray alloc] init];
            
            gistfile.filename  = [file objectForKey:@"filename"];
            gistfile.content   = [file objectForKey:@"content"];
            gistfile.language  = [file objectForKey:@"language"];
            gistfile.type      = [file objectForKey:@"type"];
            gistfile.raw_url   = [file objectForKey:@"raw_url"];
            gistfile.size      = [[file objectForKey:@"size"] integerValue];
            [gist.files addObject:gistfile];
        }
        
        if (![[json objectForKey:@"user"] isKindOfClass:[NSNull class]])
            gist.user = [self processGetUserResponse:[json objectForKey:@"user"]];
        
        gist.comments       = [[json objectForKey:@"comments"] integerValue];
        gist.pub            = [[json objectForKey:@"public"] boolValue];
        gist.anonymous      = (gist.user.login == nil);
    }
    
    
    return gist;
}

- (NSArray *)processGetAllGistsResponse:(NSData *)data
{
    NSMutableArray *gists;
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    if ([json isKindOfClass:[NSArray class]]) {
        gists = [[NSMutableArray alloc] init];
        NSArray *jsonArray = (NSArray *)json;
        [jsonArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dict = jsonArray[idx];
            Gist *gist = [self processGetGistResponse:dict];
            [gists addObject:gist];
        }];
    }
    
    return gists;
}

@end

