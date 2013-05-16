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

#import "Config.h" /** =========== REMOVE THIS LINE =========== */

/** ----------------------------------------------------------------------- */
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
/** ----------------------------------------------------------------------- */

@interface CDAppController() <StatusViewDelegate, GitHubAPIDelegate> {
    NSPasteboard *_pboard;
    NSString     *_filename;
    NSString     *_description;
    NSString     *_content;
}

/** Outlets */
@property (unsafe_unretained) IBOutlet NSWindow *prefsWindow;

@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSPopover *popover;

@property (weak) IBOutlet NSTextField *filenameTF;
@property (weak) IBOutlet NSTextField *descriptionTF;

@property (weak) IBOutlet NSButton *secretCheckBox;
@property (weak) IBOutlet NSButton *anonymousCheckBox;

@property (weak) IBOutlet NSSegmentedControl *launchAtLoginSegCell;
@property (weak) IBOutlet NSSegmentedControl *openURLSegCell;
@property (weak) IBOutlet NSSegmentedControl *notificationCenterSegCell;
@property (weak) IBOutlet NSButton *githubLoginBtn;

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
    [self setupTheStatusItem];
    [self update];
}


#pragma mark - Private
/** --------------------------------------------------------------------------------- */
- (void)update
{
    /** Update runtime options and view elements. */
    [self.options update];
    
    self.launchAtLoginSegCell.selectedSegment = self.options.login;
    self.notificationCenterSegCell.selectedSegment = self.options.notice;
    self.openURLSegCell.selectedSegment = self.options.openURL;
    
    self.anonymousCheckBox.state = self.options.anonymous;
    self.secretCheckBox.state = self.options.secret;
}

- (void)cleanup
{
    /** cleanup instance vars*/
    _pboard = nil;
    _filename = nil;
    _description = nil;
    _content = nil;
}

- (void)setupTheStatusItem
{
    /** Setup the status item */
    self.statusItem = [[NSStatusBar systemStatusBar]
                       statusItemWithLength:NSSquareStatusItemLength];
    self.statusView = [[CDStatusView alloc] initWithStatusItem:self.statusItem];
    [self.statusView setDelegate:self];
    [self.statusView setImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setAlternateImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setMenu:self.menu];
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
        _filename = @"gistFile1";
    
    if ([self.descriptionTF.stringValue isEqualToString:@""])
        _description = @"Created with QuickGist for OS X";
    
    if (_content)
    {
        [self.github createGist:_content
                       withName:_filename
                 andDescription:_description];
    }
    [self cleanup];
}

- (void)createGist:(NSPasteboard *)pboard userData:(NSString *)userData
             error:(NSString **)error
{
    /** This is the OS X service method */
    
    /** Let's set our _pboard instance variable to
     the pasteboard that was passed in. */
    _pboard = pboard;
    
    /** For now we are always prompting the user
     to name the file. */
    [self showPopover:self];
}


#pragma mark - Getters
/** --------------------------------------------------------------------------------- */
- (BOOL)popoverIsShown
{
    return [self.popover isShown];
}


#pragma mark - StatusView Delegate
/** --------------------------------------------------------------------------------- */
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


#pragma mark - Sent Actions
/** --------------------------------------------------------------------------------- */
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
            _content = [StringCleaner cleanGistContentString:[[NSString alloc] initWithData:data
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

@end
