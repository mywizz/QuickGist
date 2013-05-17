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
#import "CDMenuItem.h"
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
    
    /** If the user is authenticated with GitHub... */
    if (self.options.auth) {
        
        if ([self.authWindow isKeyWindow])
        {
            /** Close the auth window if we're coming back from
             an authorization request. */
            [self.authWindow close];
            
            /** At this point we're doing some assumption that we have
             a valid token. It will be chaged later. */
            
            NSAlert *alert = [NSAlert alertWithMessageText:@"QuickGist authorized with GitHub"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"You can now post Gists to your GitHub account!"];
            [alert runModal];
        }
        
        
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
    
    /** Update our buttons and switches and blinking lights. */
    self.launchAtLoginSegCell.selectedSegment      = self.options.login;
    self.notificationCenterSegCell.selectedSegment = self.options.notice;
    self.openURLSegCell.selectedSegment            = self.options.openURL;
    self.anonymousCheckBox.state                   = self.options.anonymous;
    self.secretCheckBox.state                      = self.options.secret;
    
    [self setGistHistoryMenu];
}

- (void)cleanup
{
    /** Clear the popover text fields. */
    self.filenameTF.stringValue = @"";
    self.descriptionTF.stringValue = @"";
    
    /** cleanup instance vars */
    _pboard      = nil;
    _filename    = nil;
    _description = nil;
    _content     = nil;
}

- (void)setGistHistoryMenu
{
    /**
     This needs to be cleaned up a bit. Setting the gist history
     menu actually reads from two seperate arays. An array for an
     authenticated user, and an array for anonymous gists.
     
     It's ugly, but it works pretty well right now.
     */
    
    NSMenuItem *yourGists = [[self.menu itemArray] objectAtIndex:1];
    NSMenu     *submenu   = [yourGists submenu];
    NSMenuItem *loginItem = [[NSMenuItem alloc] initWithTitle:@"Login to GitHub"
                                                       action:@selector(toggleGitHubLogin:)
                                                keyEquivalent:@""];
    [loginItem setTarget:self];
    
    /**
     If there are any objects in the history or anonymous history
     array, we need to wipe out the menu so we can re-populate
     with updated info.
     */
    
    if ([[submenu itemArray] count]) [submenu removeAllItems];
    
    
    if ([self.options.gists count] || [self.options.anonGists count])
    {
        /**
         If we have an authorized user and a username, let's create
         a menu item that opens the users GitHub gists page.
         */
        
        if (self.options.auth) {
            CDMenuItem *item = [[CDMenuItem alloc] init];
            NSString *url = [NSString stringWithFormat:@"https://gist.github.com/%@", self.options.user.login];
            [item setTitle:@"Open GitHub Gists"];
            [item setUrl:url];
            [item setAction:@selector(openURL:)];
            [item setTarget:self];
            [submenu addItem:item];
        }
        else [submenu addItem:loginItem];
        
        [submenu addItem:[NSMenuItem separatorItem]];
    }
    else if (![[submenu itemArray] count] && !self.options.auth)
        [submenu addItem:loginItem];
    
    
    /** This block sets the menu items. */
    BOOL __block auth = NO;
    
    void(^setMenuItems)(NSArray *) = ^(NSArray *gists) {
        for (int i=0; i<[gists count]; i++) {
            Gist *gist = (Gist *)[gists objectAtIndex:i];
            CDMenuItem *item = [[CDMenuItem alloc] init];
            NSImage *image = [NSImage imageNamed:NSImageNameLockLockedTemplate];
            if (gist.pub) image = [NSImage imageNamed:NSImageNameLockUnlockedTemplate];
            
            [item setTitle:gist.description];
            [item setUrl:gist.url];
            [item setGID:gist.gistId];
            [item setAuthedUser:auth];
            [item setToolTip:gist.description];
            [item setImage:image];
            [item setAction:@selector(openURL:)];
            [item setTarget:self];
            [submenu addItem:item];
        }
    };
    
    /** Set the menu items for the logged in user. */
    if ([self.options.gists count]) {
        auth = YES;
        setMenuItems(self.options.gists);
    }
    
    
    /** Set the menu items for anonymous gist history. */
    if ([self.options.anonGists count])
    {
        auth = NO;
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:kAnonymous
                                                      action:nil
                                               keyEquivalent:@""];
        
        if ([self.options.gists count])
            [submenu addItem:[NSMenuItem separatorItem]];
        
        [submenu addItem:item];
        setMenuItems(self.options.anonGists);
    }
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
        NSString *public = @"true";
        if (self.options.secret) public = @"false";
        
        NSDictionary *gist = @{ @"filename":    _filename,
                                @"description": _description,
                                @"content":     _content,
                                @"public":      public };
        
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

- (BOOL)popoverIsShown
{
    return [self.popover isShown];
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
        [self toggleGitHubLogin:self];
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
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url];
        [[self.webview mainFrame] loadRequest:req];
        [self.authWindow makeKeyAndOrderFront:self];
    }
    else {
        /** Process the token for user defaults */
        NSData *data = [kAnonymous dataUsingEncoding:NSUTF8StringEncoding];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:kOAuthToken];
        [self update];
    }
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
    
    if (range.location != NSNotFound)
    {
        NSString *code = [url substringFromIndex:range.location];
        code = [code stringByReplacingOccurrencesOfString:codeSearch withString:@""];
        
        [self.github requestDataForType:GitHubRequestTypeAccessToken
                               withData:code];
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




@end
