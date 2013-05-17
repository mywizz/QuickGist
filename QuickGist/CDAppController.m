//
//  CDAppController.m
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

#import "CDAppController.h"
#import "CDStatusView.h"
#import "GitHub.h"
#import "LaunchAtLogin.h"
#import <WebKit/WebKit.h>
#import <WebKit/WebFrame.h>
#import <WebKit/WebPolicyDelegate.h>

#import "Config.h" /** COMMENT OUT OR REMOVE THIS LINE. */

/** ------------------------------------------------------------------------- */
#ifndef CONFIG
@interface Config : NSObject
+ (NSString *)clientId;
+ (NSString *)clientSecret;
@end

@implementation Config
#error - Define you app id and secret
+ (NSString *)clientId { return @"<YOUR GITHUB APP ID>"; }
+ (NSString *)clientSecret { return @"<YOUR GITHUB APP SECRET>"; }
@end
#endif
/** ------------------------------------------------------------------------- */

@interface CDAppController() <NSUserNotificationCenterDelegate,
                              StatusViewDelegate, GitHubAPIDelegate> {
    NSPasteboard *_pboard;
    NSString     *_filename;
    NSString     *_description;
    NSString     *_content;
}

/** Outlets */

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSPopover *popover;

/** Popover  */
@property (weak) IBOutlet NSTextField *filenameTF;
@property (weak) IBOutlet NSTextField *descriptionTF;
@property (weak) IBOutlet NSButton *secretCheckBox;
@property (weak) IBOutlet NSButton *anonymousCheckBox;

/** Prefs window */
@property (unsafe_unretained) IBOutlet NSWindow *prefsWindow;
@property (weak) IBOutlet NSSegmentedControl *launchAtLoginSegCell;
@property (weak) IBOutlet NSSegmentedControl *openURLSegCell;
@property (weak) IBOutlet NSSegmentedControl *notificationCenterSegCell;
@property (weak) IBOutlet NSButton *githubLoginBtn;
@property (weak) IBOutlet NSTextField *loginDescriptionTextField;

/** Auth Window */
@property (unsafe_unretained) IBOutlet NSWindow *authWindow;
@property (weak) IBOutlet WebView *webview;
@property (weak) IBOutlet NSTextField *loactionLabel;

/** Custom */
@property (nonatomic, strong) CDStatusView *statusView;
@property (nonatomic, strong) Options *options;
@property (nonatomic, strong) GitHub *github;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic) BOOL popoverIsShown;

@end

@implementation CDAppController


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    /** Initialize the runtime options singleton */
    self.options = [Options sharedInstance];
    
    /** Our github object to handle api calls */
    self.github = [[GitHub alloc] init];
    [self.github setDelegate:self];
    self.github.clientId = [Config clientId];
    self.github.clientSecret = [Config clientSecret];
    
    /** Let's update our services and let the seystem know we
     have a service. */
    [NSApp setServicesProvider: self];
    NSUpdateDynamicServices();
    
    /** Setup the menubar status item */
    self.statusItem = [[NSStatusBar systemStatusBar]
                       statusItemWithLength:NSSquareStatusItemLength];
    self.statusView = [[CDStatusView alloc] initWithStatusItem:self.statusItem];
    [self.statusView setDelegate:self];
    [self.statusView setImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setAlternateImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setMenu:self.menu];
    
    /** Update views and prefs */
    [self update];
}


#pragma mark - Private
/** ------------------------------------------------------------------------- */
- (void)update
{
    /** Update runtime options and view elements. */
    [self.options update];
    
    self.launchAtLoginSegCell.selectedSegment = self.options.login;
    self.notificationCenterSegCell.selectedSegment = self.options.notice;
    self.openURLSegCell.selectedSegment = self.options.openURL;
    
    self.anonymousCheckBox.state = self.options.anonymous;
    self.secretCheckBox.state = self.options.secret;
    
    /** If the user is authenticated with GitHub. */
    if (self.options.auth) {
        [self.githubLoginBtn setTitle:@"Logout"];
        if (self.options.user.login)
            [self.loginDescriptionTextField setStringValue:self.options.user.login];
        else
            [self.loginDescriptionTextField setStringValue:@"Logout of GitHub:"];
    }
    else {
        [self.githubLoginBtn setTitle:@"Login"];
        [self.loginDescriptionTextField setStringValue:@"Login to GitHub:"];
    }
}

- (void)cleanup
{
    /** cleanup instance vars */
    _pboard = nil;
    _filename = nil;
    _description = nil;
    _content = nil;
}

- (id)item
{
    id _item;
    
    NSPasteboard *pboard = _pboard;
    if (!pboard)
        pboard = [NSPasteboard generalPasteboard];
    
    NSArray *allowedClasses = @[ [NSString class], [NSURL class] ];
    NSArray *copiedItems = [pboard readObjectsForClasses:allowedClasses
                                                 options:nil];
    
    if ([copiedItems count])
        _item = [copiedItems objectAtIndex:0];
    
    return _item;
}

- (void)createGist
{
    if ([self.filenameTF.stringValue isEqualToString:@""])
        _filename = @"gistfile1";
    
    if ([self.descriptionTF.stringValue isEqualToString:@""])
    {
        /** If the user doesn't add a description, let's give him one 
         based on the filename and date. */
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        _description = [NSString stringWithFormat:@"%@ %@", _filename, dateString];
    }
    
    if (_content)
    {
        NSDictionary *gist = @{@"filename": _filename,
                               @"description": _description,
                               @"content": _content};
        
        [self.github requestDataForType:GitHubRequestTypeCreateGist
                               withData:gist];
    }
    [self cleanup];
}

- (void)createGistFromSystemService:(NSPasteboard *)pboard
                           userData:(NSString *)userData
                              error:(NSString **)error
{
    /** Let's set our _pboard instance variable to
     the pasteboard that was passed in. */
    _pboard = pboard;
    
    /** For now we are always prompting the user
     to name the file. */
    [self showPopover:self];
}


#pragma mark - Getters
/** ------------------------------------------------------------------------- */
- (BOOL)popoverIsShown
{
    return [self.popover isShown];
}


#pragma mark - StatusView Delegate
/** ------------------------------------------------------------------------- */
- (void)downloadGists
{
    /** Close the popover if it's shown */
    if (self.popoverIsShown)
        [self.popover close];
}

- (void)createGistFromDrop:(NSPasteboard *)pboard
{
    _pboard = pboard;
    [self showPopover:self];
}

#pragma mark - WebView Policy Delegate
/** ------------------------------------------------------------------------- */
- (void)webView:(WebView *)sender
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)listener
{
    /** We're going to catch the request url to check for "?code=" which
     is the code that is sent back from GitHub to the callback url.
     
     Once the code is found in the string range, we initiate a token
     request, and wait for the response which should contain
     the token string */
    
    NSString *url = [[request URL] absoluteString];
    NSString *codeSearch = @"?code=";
    NSRange range = [url rangeOfString:codeSearch];
    
    if (range.location!=NSNotFound)
    {
        NSString *code = [url substringFromIndex:range.location];
        code = [code stringByReplacingOccurrencesOfString:codeSearch withString:@""];
        /** Initiate token request */
    }
    
    [listener use];
}


#pragma mark - WebView Frame Load Delegate
/** ------------------------------------------------------------------------- */
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title
       forFrame:(WebFrame *)frame
{
    self.loactionLabel.stringValue = frame.dataSource.request.URL.absoluteString;
}


#pragma mark - Sent Actions
/** ------------------------------------------------------------------------- */
- (IBAction)showPopover:(id)sender
{
    /** Close the popover if it's shown */
    if (self.popoverIsShown)
        [self.popover close];
    
    /** We need to get the content of the gist now
     incase the user copy/pastes something else. */
    id item = [self item];
    
    if (item != nil)
    {    
        if ([item isKindOfClass:[NSString class]])
            _content = [StringCleaner cleanGistContentString:item];
        
        else if ([item isKindOfClass:[NSURL class]])
        {
            _filename = [[item path] lastPathComponent];
            NSData *data = [[NSData alloc] initWithContentsOfURL:item];
            
            _content = [StringCleaner cleanGistContentString:
                        [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding]];
        }
        
        if (!_content) {
            [self cleanup];
            NSAlert *alert = [NSAlert alertWithMessageText:@"No text detected"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"There doesn't appear to be any text in this file."];
            [alert runModal];
        }
        else {
            if (_filename)
                self.filenameTF.stringValue = _filename;
            
            if (_description)
                self.descriptionTF.stringValue = _description;
            
            [self.popover showRelativeToRect:[self.statusView bounds]
                                      ofView:self.statusView
                               preferredEdge:NSMaxYEdge];
        }
    }
    else [self cleanup];
}

- (IBAction)createGist:(id)sender
{
    /** Close the popover if it's shown */
    if ([self.popover isShown])
        [self.popover close];
    
    _filename = self.filenameTF.stringValue;
    _description = self.descriptionTF.stringValue;
    
    [self createGist];
}

- (IBAction)cancelGist:(id)sender
{
    /** Clear the text fields if there is any text. */
    self.filenameTF.stringValue = @"";
    self.descriptionTF.stringValue = @"";
    
    /** Close the popover if it's shown */
    if ([self.popover isShown])
        [self.popover close];
    
    [self cleanup];
}

- (IBAction)toggleLaunchAtLogin:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
     setBool:[sender selectedSegment] forKey:kLogin];
    [LaunchAtLogin toggleLaunchAtLogin:[sender selectedSegment]];
    [self update];
}

- (IBAction)toggleShowInNotificationCenter:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
     setBool:[sender selectedSegment] forKey:kNotification];
    [self update];
}

- (IBAction)toggleOpenURLAfterPost:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
     setBool:[sender selectedSegment] forKey:kOpenURL];
    [self update];
}

- (IBAction)toggleAnonymousGists:(id)sender
{
    if (self.options.anonymous && !self.options.auth) {
        
        /** Close the popover if it's shown */
        if ([self.popover isShown])
            [self.popover close];
        
        /** Prompt the user to authenticate if they are not
         authenticated. */
    }
    else
        [[NSUserDefaults standardUserDefaults]
         setBool:!self.options.anonymous forKey:kAnonymous];
    
    [self update];
}

- (IBAction)toggleSecretGists:(id)sender
{
    [[NSUserDefaults standardUserDefaults]
     setBool:!self.options.secret forKey:kPublic];
    [self update];
}

- (IBAction)toggleGitHubLogin:(id)sender
{
    if (!self.options.auth)
    {
        NSURL *url = [NSURL URLWithString:self.github.apiTokenRequestURL];
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc]
                                        initWithURL:url];
        
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [self.webview setApplicationNameForUserAgent:self.options.useragent];
        [[self.webview mainFrame] loadRequest:request];
        [self.authWindow makeKeyAndOrderFront:self];
    }
    /*
    else {
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:kLastCheck];
        self.options.token = kAnonymous;
        self.options.auth = NO;
    }
    
    NSData *tokenData = [self.options.token dataUsingEncoding:NSUTF8StringEncoding];
    [[NSUserDefaults standardUserDefaults] setValue:tokenData forKey:kOAuthToken];
    [self update];
     */
}

@end
