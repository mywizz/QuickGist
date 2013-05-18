//
//  CDStatusView.m
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

#import "CDStatusView.h"

@interface CDStatusView() <NSMenuDelegate>
@property (nonatomic, readonly) NSStatusItem *statusItem;
@property (nonatomic, setter = setHighlighted:) BOOL isHighlighted;
@property (nonatomic) SEL action;
@property (nonatomic, assign) id target;
@property (nonatomic, strong) NSArray *types;

@end

@implementation CDStatusView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.types = @[ NSStringPboardType, NSRTFPboardType, NSFilenamesPboardType ];
        [self registerForDraggedTypes:self.types];
    }
    
    return self;
}


- (id)initWithStatusItem:(NSStatusItem *)statusItem
{
    CGFloat itemWidth = [statusItem length];
    CGFloat itemHeight = [[NSStatusBar systemStatusBar] thickness];
    NSRect  itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
    self = [self initWithFrame:itemRect];
    
    if (self != nil) {
        _statusItem = statusItem;
        _statusItem.view = self;
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
	[self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:self.isHighlighted];
    
    NSImage *icon = self.isHighlighted ? self.alternateImage : self.image;
    NSSize iconSize = [icon size];
    NSRect bounds = self.bounds;
    CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    NSPoint iconPoint = NSMakePoint(iconX, iconY);
    [icon drawAtPoint:iconPoint fromRect:self.bounds operation:NSCompositeSourceOver fraction:iconX];
}


- (void)setMenu:(NSMenu *)menu
{
    [menu setDelegate:self];
    [super setMenu:menu];
}


#pragma mark - Mouse tracking
- (void)mouseDown:(NSEvent *)theEvent
{
    NSMenu *menu = [super menu];
    [_statusItem popUpStatusItemMenu:menu];
    [NSApp sendAction:self.action to:self.target from:self];
}


- (void)menuWillOpen:(NSMenu *)menu
{
    [self.delegate downloadGists];
    [self setHighlighted:YES];
    [self setNeedsDisplay:YES];
}



- (void)menuDidClose:(NSMenu *)menu
{
    [self setHighlighted:NO];
    [self setNeedsDisplay:YES];
}


#pragma mark - Accessors
- (void)setHighlighted:(BOOL)newFlag
{
    if (_isHighlighted == newFlag) return;
    _isHighlighted = newFlag;
    [self setNeedsDisplay:YES];
}


#pragma mark -
- (void)setImage:(NSImage *)newImage
{
    _image = newImage;
    [self setNeedsDisplay:YES];
}


- (void)setAlternateImage:(NSImage *)newImage
{
    _alternateImage = newImage;
    if (self.isHighlighted)
        [self setNeedsDisplay:YES];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if ([[sender draggingPasteboard] availableTypeFromArray:self.types])
        return NSDragOperationCopy;
    
    return NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if( ![[pboard pasteboardItems] count] )
        return NO;
    
    if ([[sender draggingPasteboard] availableTypeFromArray:self.types]) {
        [self.delegate createGistFromDrop:pboard];
        return YES;
    }
    
    return NO;
}

@end
