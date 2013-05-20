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
#import "GitHub.h"
#import "CDStatusView.h"
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

@interface CDAppController() <NSUserNotificationCenterDelegate, StatusViewDelegate, GitHubAPIDelegate> {
    NSPasteboard *_pboard;
    NSString     *_url;
    Gist         *_gist;
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
@property (weak) IBOutlet NSImageView *avatarImageView;
@property (weak) IBOutlet NSToolbar *toolbar;
@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSTextField *apiCallsCount;

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
    
    
    /** Let the system know we have a service. */
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
    
    /** Set selected tab */
    self.toolbar.selectedItemIdentifier = @"Account";
    self.prefsWindow.title = @"GitHub Account";
    
    /** Remove the last check on launch so we can do a fresh ckeck
     for authed users gists. */
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastRequest];
    
    /** Update views and prefs */
    [self update];
    
    
    /** If we have an authenticated user, download all Gists on app
     startup. This will hit the api rate pretty hard if the user has
     a lot of gists and gist files, but it's only at app startup,
     and if the user logs out and back in during the app runtime. */
    
    if (self.options.user)
        [self.github requestDataForType:GitHubRequestTypeGetAllGists
                               withData:nil
                         cachedResponse:NO];
}




#pragma mark - Private
/** ------------------------------------------------------------------------- */
- (void)cleanup
{
    /** Clear the popover text fields. */
    self.filenameTF.stringValue = @"";
    self.descriptionTF.stringValue = @"";
    
    /** cleanup instance vars */
    _pboard = nil;
    _gist   = nil;
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
     array, we need to wipe out the sub-menu so we can re-populate
     with updated info.
     */
    
    if ([[submenu itemArray] count])
        [submenu removeAllItems];
    
    if ([self.options.gists count] || [self.options.anonGists count])
    {
        /**
         If we have an authorized user, let's create
         a menu item that opens the users GitHub gists page.
         */
        
        if (self.options.user)
        {
            /** Using our sub-classed NSMenuItem to provide a few
             extra properties. */
            CDMenuItem *item = [[CDMenuItem alloc] initWithTitle:self.options.user.login
                                                          action:nil
                                                   keyEquivalent:@""];
            NSString *url = [NSString stringWithFormat:@"https://gist.github.com/%@",
                             self.options.user.login];
            NSImage *avatar = [[NSImage alloc] initWithData:self.options.user.avatar];
            NSSize avatarSize;
            avatarSize.width = 18.00;
            avatarSize.height = 18.00;
            [avatar setSize:avatarSize];
            
            [item setImage:avatar];
            [item setUrl:url];
            [item setAction:@selector(openURL:)];
            [item setTarget:self];
            [submenu addItem:item];
        }
        
        /** If not, let's add an NSMenuItem that the user can login
         to GitHub with. */
        else [submenu addItem:loginItem];
        
        /** To make it pretty, we'll want a seperator. */
        [submenu addItem:[NSMenuItem separatorItem]];
    }
    else if (![[submenu itemArray] count] && !self.options.user)
        [submenu addItem:loginItem];
    
    
    /** This block sets the menu items. */
    __block BOOL auth = NO;
    
    void(^setMenuItems)(NSArray *) = ^(NSArray *gists)
    {
        [gists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Gist *gist = (Gist *)[gists objectAtIndex:idx];
            CDMenuItem *item = [[CDMenuItem alloc] init];
            
            
            NSString *dateStr = [NSString stringWithFormat:@"%@", gist.created_at];
            NSRange range = [dateStr rangeOfString:@"T"];
            
            if (range.location != NSNotFound)
                dateStr = [dateStr substringToIndex:range.location];
            
            NSImage *image = [NSImage imageNamed:NSImageNameLockLockedTemplate];
            __block NSString *tooltip = [NSString stringWithFormat:@"Private\nCreated: %@\nFiles:\n", dateStr];
            
            if (gist.pub) {
                image = [NSImage imageNamed:NSImageNameLockUnlockedTemplate];
                tooltip = [NSString stringWithFormat:@"Public\nCreated: %@\nFiles:\n", dateStr];
            }

            
            [gist.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GistFile *file = (GistFile *)[gist.files objectAtIndex:idx];
                NSString *filename = [NSString stringWithFormat:@"%@", file.filename];
                
                if (idx == 0)
                    tooltip = [tooltip stringByAppendingString:filename];
                else
                    tooltip = [tooltip stringByAppendingString:[NSString stringWithFormat:@"\n%@", filename]];
            }];
            
            [item setTitle:gist.description];
            [item setUrl:gist.html_url];
            [item setGistId:gist.gistId];
            [item setAuthedUser:auth];
            [item setToolTip:tooltip];
            [item setImage:image];
            [item setAction:@selector(openURL:)];
            [item setTarget:self];
            [submenu addItem:item];
        }];
        
        
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
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"anonymous gists"
                                                      action:nil
                                               keyEquivalent:@""];
        
        if ([self.options.gists count])
            [submenu addItem:[NSMenuItem separatorItem]];
        
        [submenu addItem:item];
        setMenuItems(self.options.anonGists);
    }
}

- (void)createGist
{
    if (_gist)
    {
        Gist *gist = _gist;
        
        /** grab the filename and description from the user prompt. */
        NSString *filename = self.filenameTF.stringValue;
        NSString *description = self.descriptionTF.stringValue;
        
        /** Let's give some defalt values incase the user didn't provide any. */
        if ([filename isEqualToString:@""])
            filename = @"gistfile1";
            
        if ([description isEqualToString:@""]) {
            
            NSString *comma = @", ";
            NSRange range = [filename rangeOfString:comma];
            
            if (range.location != NSNotFound)
                description = @"Multiple files";
            else
                description = filename;
        }
        
        /** The user may have not named the gist filename. In this case, we've already
         set the filename above, but now we need to apply it the the GistFile. */
        if ([gist.files count] == 1)
        {
            GistFile *gistFile = (GistFile*)[gist.files objectAtIndex:0];
            gistFile.filename = filename;
        }
        gist.description = description;
        
        [self.github requestDataForType:GitHubRequestTypeCreateGist
                               withData:gist
                         cachedResponse:NO];
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

- (Gist *)processGistForMultipleFiles:(NSArray *)files
{
    __block Gist *gist;
    
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        id item = [files objectAtIndex:idx];
        if ([item isKindOfClass:[NSURL class]])
        {
            NSString *filename = [[item path] lastPathComponent];
            NSData *data = [[NSData alloc] initWithContentsOfURL:item];
            NSString *content = [StringCleaner cleanGistContentString:
                                 [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding]];
            
            /** Only add the files if they have content */
            if (content) {
                if (!gist) {
                    gist = [[Gist alloc] init];
                    gist.files = [[NSMutableArray alloc] init];
                }
                GistFile *gistFile = [[GistFile alloc] init];
                gistFile.filename = filename;
                gistFile.content = content;
                [gist.files addObject:gistFile];
            }
            else {
                [self invalidFileTypeAlert];
                *stop = YES;
            }
        }
    }];
    
    return gist;
}

- (void)deleteGistId:(NSString *)gistId
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Gist delete confirmation"
                                     defaultButton:@"Delete"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Are you sure you want to delete this Gist and all of its files?"];
    
    NSInteger result = [alert runModal];
    [self handleResult:alert withResult:result forGistId:gistId];
}

-(void)handleResult:(NSAlert *)alert withResult:(NSInteger)result
          forGistId:(NSString *)gistId
{
    switch(result)
    {
        case NSAlertDefaultReturn:
            [self.github requestDataForType:GitHubRequestTypeDeleteGist
                                   withData:gistId
                             cachedResponse:NO];
            break;
            
        case NSAlertAlternateReturn:
            // nothing to do.
            break;
            
        default:
            break;
    }
}


- (void)invalidFileTypeAlert
{
    NSString *title = @"Invalid file type";
    NSString *subtitle = @"QuickGist only supports text based files.";
    [self postUserNotification:title subtitle:subtitle];
}




#pragma mark - GitHub API Delegate
/** ------------------------------------------------------------------------- */
- (void)update
{
    /** Update runtime options and view elements. */
    [self.options update];
    
    /** If the user is authenticated with GitHub... */
    if (self.options.user)
    {
        /** Close the auth window if we're coming back from
         an authorization request. */
        if ([self.authWindow isVisible])
        {
            [self.authWindow close];
            
            [self postUserNotification:@"QuickGist authorized"
                              subtitle:@"QuickGist is now authorized with your GitHub account!"];
            
            /** Set the users initial option to post gists to the users account. */
            self.options.user.useAccount = YES;
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.options.user];
            [[NSUserDefaults standardUserDefaults] setValue:data forKey:kGitHubUser];
        }
        
        [self.githubLoginBtn setTitle:@"Logout"];
        [self.loginDescriptionTextField setStringValue:self.options.user.login];
        
        if (!self.options.user.avatar) {
            [self.github requestDataForType:GitHubRequestTypeGetUserAvatar
                                   withData:nil
                             cachedResponse:NO];
            
            [self performSelector:@selector(downloadGists)
                       withObject:nil
                       afterDelay:0.5];
        }
        else if (self.options.user.avatar)
        {
            NSImage *image = [[NSImage alloc] initWithData:self.options.user.avatar];
            [self.avatarImageView setImage:image];
            [self.avatarImageView setNeedsDisplay];
        }
    }
    else if (self.options.token && !self.options.user)
    {
        [self.github requestDataForType:GitHubRequestTypeGetUser
                               withData:nil
                         cachedResponse:NO];
    }
    else
    {
        [self.githubLoginBtn setTitle:@"Login"];
        [self.loginDescriptionTextField setStringValue:@"Login to GitHub:"];
    }
    
    /** Update our buttons and switches and blinking lights. */
    self.launchAtLoginSegCell.selectedSegment      = self.options.login;
    self.notificationCenterSegCell.selectedSegment = self.options.notice;
    self.openURLSegCell.selectedSegment            = self.options.openURL;
    self.anonymousCheckBox.state                   = self.options.user.useAccount;
    self.anonymousCheckBox.hidden                  = !self.options.user;
    self.secretCheckBox.state                      = !self.options.secret;
    
    [self setGistHistoryMenu];
    [self updateApiCallsLabel];
}

- (void)updateApiCallsLabel
{
    /** Update remaining api calls for the user. */
    NSString *apiCalls = self.options.remainingAPICalls;
    if (apiCalls) {
        if (self.options.user)
            apiCalls = [apiCalls stringByAppendingString:@"/5000"];
        else
            apiCalls = [apiCalls stringByAppendingString:@"/60"];
        
        /** Set the label string value */
        self.apiCallsCount.stringValue = apiCalls;
    }
}

- (void)postUserNotification:(NSString *)title subtitle:(NSString *)subtitle
{
    if (self.options.notice)
    {
        NSUserNotification *notice = [[NSUserNotification alloc] init];
        notice.title = title;
        notice.subtitle = subtitle;
        
        NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
        [nc setDelegate:self];
        [nc deliverNotification:notice];
    }
    
    if (self.options.openURL)
    {
        NSURL *url = [NSURL URLWithString:subtitle];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}


#pragma mark - User Notification Delegate
/** ------------------------------------------------------------------------- */
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
    NSString *http = @"http";
    NSRange range = [notification.subtitle rangeOfString:http];
    
    if (range.location != NSNotFound)
    {
        _url = notification.subtitle;
        [self openURL:self];
    }
}




#pragma mark - StatusView Delegate
/** ------------------------------------------------------------------------- */
- (void)downloadGists
{
    /** Close the popover if it's shown */
    if (self.popoverIsShown)
        [self.popover close];
    
    /** Download the gists when status menu item clicked */
    if (self.options.user)
    {
        if (![self.options.gists count])
        {
            /** Remove the last check on launch so we can do a fresh ckeck
             for authed users gists. */
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastRequest];
            
            /** Update views and prefs */
            [self update];
        }
        [self.github requestDataForType:GitHubRequestTypeGetAllGists
                               withData:nil
                         cachedResponse:([self.options.gists count])];
    }
}

- (void)createGistFromDrop:(NSPasteboard *)pboard
{
    _pboard = pboard;
    [self showPopover:self];
}




#pragma mark - Tabview Delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([tabView.selectedTabViewItem.label isEqualToString:@"Account"])
        self.prefsWindow.title = @"GitHub Account";
    else
        self.prefsWindow.title = tabView.selectedTabViewItem.label;
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
                               withData:code
                         cachedResponse:NO];
    }
    
    [listener use];
}




#pragma mark - WebView Frame Load Delegate
/** ------------------------------------------------------------------------- */
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title
       forFrame:(WebFrame *)frame
{
    /** Show the web URL at the bottom of the Auth window */
    self.loactionLabel.stringValue = frame.dataSource.request.URL.absoluteString;
}




#pragma mark - Sent Actions
/** ------------------------------------------------------------------------- */
- (IBAction)showPopover:(id)sender
{
    /** Make sure the filename section is enabled before we start. */
    [self.filenameTF setEnabled:YES];
    
    if (!_pboard)
        _pboard = [NSPasteboard generalPasteboard];
    NSArray *allowedClasses = @[ [NSString class], [NSURL class] ];
    NSArray *items = [_pboard readObjectsForClasses:allowedClasses
                                                 options:nil];
    
    if ([items count])
    {
        Gist *gist;
        
        /** Close the popover if it's shown */
        if (self.popoverIsShown)
            [self.popover close];
        
        /** Bring the app process forward */
        ProcessSerialNumber psn;
        if (noErr == GetCurrentProcess(&psn))
            SetFrontProcess(&psn);
        
        
        /** Multiple files to be processed. */
        if ([items count] > 1) {
            if (!gist) gist = [[Gist alloc] init];
            gist = [self processGistForMultipleFiles:items];
        }
        
        if ([items count] == 1)
        {
            id item = [items objectAtIndex:0];
            NSString *filename;
            NSString *content;
            
            if ([item isKindOfClass:[NSString class]])
                content = [StringCleaner cleanGistContentString:item];
            
            else if ([item isKindOfClass:[NSURL class]])
            {
                filename = [[item path] lastPathComponent];
                NSData *data = [[NSData alloc] initWithContentsOfURL:item];
                content = [StringCleaner cleanGistContentString:
                           [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding]];
            }
            if (content)
            {
                GistFile *gistFile = [[GistFile alloc] init];
                if (!gist) {
                    gist = [[Gist alloc] init];
                    gist.files = [[NSMutableArray alloc] init];
                }
                
                gistFile.filename = filename;
                gistFile.content = content;
                [gist.files addObject:gistFile];
                if (filename)
                    self.filenameTF.stringValue = filename;
            }
            else [self invalidFileTypeAlert];
        }
        
        if ([gist.files count])
        {
            if ([gist.files count] > 1)
            {
                __block NSString *filename = @"";
                [gist.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    GistFile *gistfile = (GistFile*)[gist.files objectAtIndex:idx];
                    
                    /** Only add comma and filename if there are more than 1 files. */
                    if (idx > 0 )
                        filename = [filename stringByAppendingString:[NSString stringWithFormat:@", %@", gistfile.filename]];
                    else filename = gistfile.filename;
                }];
                
                /** set multiple filenames and disable user input. */
                self.filenameTF.stringValue = filename;
                [self.filenameTF setEnabled:NO];
            }
            
            _gist = gist;
            [self.popover showRelativeToRect:[self.statusView bounds]
                                      ofView:self.statusView
                               preferredEdge:NSMaxYEdge];
        }
        else [self cleanup];
    }
}

- (IBAction)createGist:(id)sender
{
    /** Close the popover if it's shown */
    if ([self.popover isShown])
        [self.popover close];
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
    if (!self.options.user) {
        
        /** Close the popover if it's shown */
        if ([self.popover isShown])
            [self.popover close];
        [self toggleGitHubLogin:self];
    }
    else {
        self.options.user.useAccount = !self.options.user.useAccount;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.options.user];
        [[NSUserDefaults standardUserDefaults] setValue:data forKey:kGitHubUser];
    }
    
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
    if (!self.options.user)
    {
        NSURL *url = [NSURL URLWithString:self.github.apiTokenRequestURL];
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url];
        [[self.webview mainFrame] loadRequest:req];
        [self.authWindow makeKeyAndOrderFront:self];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOAuthToken];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kHistory];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGitHubUser];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastRequest];
        
        self.avatarImageView.image = [NSImage imageNamed:NSImageNameUser];
        self.options.remainingAPICalls = @"Remaining api calls: 60";
        
        [self update];
        [self postUserNotification:@"QuickGist de-authorized"
                          subtitle:@"QuickGist has been de-authorized from your GitHub account."];
    }
}

- (IBAction)openURL:(id)sender
{
    BOOL delete = NO;
    BOOL edit   = NO;
    CDMenuItem *item;
    
    if (NSAlternateKeyMask & [NSEvent modifierFlags]) edit = YES;
    if (NSCommandKeyMask & [NSEvent modifierFlags]) delete = YES;
    
    
    if ([sender isKindOfClass:[CDMenuItem class]]) {
        item = (CDMenuItem *)sender;
        _url = item.url;
        
        if (item.authedUser)
        {
            if (edit)
            {
                NSString *match = @"https://gist.github.com/";
                NSString *chg = [NSString stringWithFormat:@"https://gist.github.com/%@/",
                                 self.options.user.login];
                _url = [_url stringByReplacingOccurrencesOfString:match withString:chg];
                _url = [_url stringByAppendingString:@"/edit"];
            }
            
            if (delete) {
                [self.options.gists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    Gist *gist = (Gist*)[self.options.gists objectAtIndex:idx];
                    
                    if ([gist.gistId isEqualToString:item.gistId])
                    {
                        [self deleteGistId:item.gistId];
                        [self.options.gists removeObjectAtIndex:idx];
                        NSData *gistsData = [NSKeyedArchiver archivedDataWithRootObject:self.options.gists];
                        [[NSUserDefaults standardUserDefaults] setObject:gistsData forKey:kHistory];
                        *stop = YES;
                    }
                }];
            }
        }
    }
    else if ([sender isKindOfClass:[NSTextField class]])
        _url = @"http://developer.github.com/v3/#rate-limiting";
    
    if (_url && !delete) {
        NSURL *url = [NSURL URLWithString:_url];
        [[NSWorkspace sharedWorkspace] openURL:url];
        _url = nil;
    }
}




@end
