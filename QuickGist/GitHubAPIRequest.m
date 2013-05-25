//
//  GitHubAPIRequest.m
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

#import "GitHubAPIRequest.h"
#import "GitHubResponseProcessor.h"

@interface GitHubAPIRequest() <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    NSURLConnection  *_connection;
    NSMutableData    *_responseData;
    NSString         *_lastRequest;
    GitHubRequestType _reqType;
}

@end

@implementation GitHubAPIRequest

#pragma mark - Public
- (void)submitRequest:(NSURLRequest *)req forDataType:(GitHubRequestType)requestType
{
    _reqType = requestType;
    _connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [_connection start];
}

#pragma mark - Private
- (void)processData:(NSData *)data
{
    GitHubResponseProcessor *proc = [[GitHubResponseProcessor alloc] init];
    
    id processedData = [proc processData:data
                           forReqestType:_reqType];
    
    [self.delegate handleData:processedData
                  forDataType:_reqType
              fromLastRequest:_lastRequest];
}

- (void)cleanup
{
    [_connection cancel];
    _connection   = nil;
    _responseData = nil;
    _lastRequest  = nil;
}

#pragma mark - Connection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSDictionary *headers = [httpResponse allHeaderFields];
    NSInteger status = [httpResponse statusCode];
    
#ifdef DEBUG
    /** Log the response headers when debugging. */
    for (id key in headers)
        NSLog(@"%@: %@", [key description], [headers objectForKey:key]);
#endif
    
    /** Keep track of remaing api calls for the user */
    NSString *apiCalls = [headers objectForKey:@"X-RateLimit-Remaining"];
    NSString *remainingApiCallsStr = @"Remaining api calls: ";
    
    if (apiCalls)
        remainingApiCallsStr = [remainingApiCallsStr stringByAppendingString:apiCalls];
    
    [self.delegate processRemainingApiCalls:remainingApiCallsStr];
    
    switch (status) {
        case 200:
            // success
            break;
        case 201:
            // success posting data
            break;
        case 204:
            // delete success
            if (_reqType == GitHubRequestTypeDeleteGist) {
                
                NSString *success = @"success";
                
                [self.delegate handleData:success
                              forDataType:_reqType
                          fromLastRequest:_lastRequest];
                
                [self cleanup];
            }
            break;
        case 304:
            // use cache
            [self cleanup];
            break;
        case 400:
            // use cache
            [self cleanup];
            break;
            
        default:
            break;
    }
    
    /** Save the date so we can use it for chaed responses */
    _lastRequest = [headers objectForKey:@"Date"];
    
    if (!_responseData)
        _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSData *data = _responseData;
    [self processData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    /** Not sure how I want to handle this yet. */
    
    /*
    NSAlert *alert = [NSAlert alertWithMessageText:@"No response from GitHub"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"Check your Internet connection to make sure you're connected."];
    [alert runModal];
     */
}

@end
