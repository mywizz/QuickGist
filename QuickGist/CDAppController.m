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

@interface CDAppController() <StatusViewDelegate, GitHubAPIDelegate> {
    NSPasteboard *_pboard;
}

/** Outlets */
@property (unsafe_unretained) IBOutlet NSWindow *prefsWindow;

@property (nonatomic, weak) IBOutlet NSMenu *menu;
@property (nonatomic, weak) IBOutlet NSPopover *popover;

@property (nonatomic, weak) IBOutlet NSTextField *filenameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *descriptionTextField;
@property (nonatomic, weak) IBOutlet NSButton *secretCheckBox;
@property (nonatomic, weak) IBOutlet NSButton *anonymousCheckBox;


/** Custom */
@property (nonatomic, strong) CDStatusView *statusView;
@property (nonatomic, strong) Options *options;
@property (nonatomic, strong) GitHub *github;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic) BOOL popoverIsShown;

@end

@implementation CDAppController

#pragma mark - Super Class
- (void)awakeFromNib
{
    [super awakeFromNib];
    
    /** Runtime options singleton */
    self.options = [Options sharedInstance];
    
    /** Our github object to handle api calls */
    self.github = [[GitHub alloc] init];
    [self.github setDelegate:self];
    
    /** Let's update our services and let the seystem know we
     have a service. */
    
    [NSApp setServicesProvider: self];
    NSUpdateDynamicServices();
    
    /** bring the process fwd */
    [self bringForward];
    
    /** Setup the status item */
    self.statusItem = [[NSStatusBar systemStatusBar]
                       statusItemWithLength:NSSquareStatusItemLength];
    self.statusView = [[CDStatusView alloc] initWithStatusItem:self.statusItem];
    [self.statusView setDelegate:self];
    [self.statusView setImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setAlternateImage:[NSImage imageNamed:@"menu-icon"]];
    [self.statusView setMenu:self.menu];
}


#pragma mark - Private
/** --------------------------------------------------------------------------------- */
- (void)update
{
    [self.options update];
}

- (void)bringForward
{
    /** Bring the window (proccess) forward */
    ProcessSerialNumber psn;
    if (noErr == GetCurrentProcess(&psn))
        SetFrontProcess(&psn);
}

- (id)content
{
    NSPasteboard *pboard;
    if (_pboard)
        pboard = _pboard;
    else
        pboard = [NSPasteboard generalPasteboard];
    
    NSArray *classes      = @[ [NSString class], [NSURL class] ];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems  = [pboard readObjectsForClasses:classes options:options];
    
    id item;
    
    if ([copiedItems count])
        item = [copiedItems objectAtIndex:0];
    
    return item;
}

- (void)createGist:(NSPasteboard *)pboard userData:(NSString *)userData
             error:(NSString **)error
{
    /** This is our system service method */
    
    /** Let's set our _pboard instance variable to
     the pasteboard that was passed in. */
    _pboard = pboard;
    
    /** For now we are always prompting the user
     to name the file. */
    [self showPopover:self];
}

- (void)createGistWithName:(NSString *)filename
            andDescription:(NSString *)description
{
    /** We need to get the content of the gist now
     incase the user cop/pastes something else. */
    NSString *content = [self content];
    
    if (content != nil) {
        
        /** Set default values if the user didn't set any. */
        if ([filename isEqualToString:@""])
            filename = @"gistfile1";
        
        if ([description isEqualToString:@""])
            description = @"Created with QuickGist for OS X";
        
        /** Create a gist */
        [self.github createGist:content
                       withName:filename
                 andDescription:description];
    }
    
    /** cleanup */
    _pboard = nil;
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
    /** Close the popover window if shown */
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
    [self bringForward];
    
    if (self.popoverIsShown)
        [self.popover close];
    
    
    [self.popover showRelativeToRect:[self.statusView bounds]
                              ofView:self.statusView
                       preferredEdge:NSMaxYEdge];
    
}

- (IBAction)createGist:(id)sender
{
    if ([self.popover isShown])
        [self.popover close];
 
    NSString* (^processField)(NSTextFieldCell *) = ^(NSTextFieldCell *cell) {
        NSString *str = cell.title;
        cell.title = @"";
        return str;
    };
    
    NSString *filename = processField([self.filenameTextField cell]);
    NSString *description = processField([self.descriptionTextField cell]);
    [self createGistWithName:filename andDescription:description];
}

- (IBAction)cancelGist:(id)sender
{
    if ([self.popover isShown])
        [self.popover close];
    
    _pboard = nil;
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
        [self.popover close];
        // [self toggleGitHubLogin:sender];
    }
    else
        [[NSUserDefaults standardUserDefaults]
         setBool:!self.options.anonymous forKey:kAnonymous];
    
    [self update];
}

@end
