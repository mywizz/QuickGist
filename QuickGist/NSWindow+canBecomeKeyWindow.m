//
//  NSWindow+canBecomeKeyWindow.m
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

#import "NSWindow+canBecomeKeyWindow.h"

@implementation NSWindow (canBecomeKeyWindow)


/** This is to fix a bug with 10.7 where an NSPopover with a
 text field cannot be edited if its parent window won't become key.
 
 The pragma statements disable the corresponding warning for overriding
 an already-implemented method. 
 
 Original parts from @bobesh at:
 http://stackoverflow.com/questions/7214273/nstextfield-on-nspopover
 
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (BOOL)canBecomeKeyWindow
{
    /** This works pretty well, but feels so wrong. Doing deep
     introspection to get the status of the NSPopover from
     the AppController. */
    
    /** Let's bring the process forward when making the window key */
    
    ProcessSerialNumber psn;
    if (noErr == GetCurrentProcess(&psn))
        SetFrontProcess(&psn);
    
    
    if ([self class] == NSClassFromString(@"NSStatusBarWindow"))
    {
        /** The StatusItem's view delegate is the CDAppController which
         has a popoverIsShown BOOL property. */
        
        BOOL popoverIsShown = (BOOL)[[[self contentView] delegate]
                                     performSelector:@selector(popoverIsShown)];
        return popoverIsShown;
    }
    
    return YES;
}

#pragma clang diagnostic pop

@end
