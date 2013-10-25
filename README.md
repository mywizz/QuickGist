## QuickGist for OS X


## Description

Use QuickGist to post and manage your GitHub Gists. QuickGist runs in your Mac menubar and allows you to drag and drop text or text files right onto the menubar icon to quickly create a GitHub Gist!

## Important build notes

Before you can succesfully build QuickGist, you need to comment out or remove the '#import "Config.h"' in CDAppController.m. This is for my build setup to add the clientId and clientSecret whithout accidently pushing it to GitHub.

You also need to add your client id and secret.

## Support QuickGist Development

QuickGist is available on the Mac App Store for .99¢. If you find it useful then buy a copy to encourage me to continue development on it for public use.

## Features 

• Use completely anonymous, or with your GitHub account

• Drag and drop text or text files to menubar icon

• Create gists from your clipboard contents 

• Maintained gists history menu

• Maintains separate gists history for anonymous gists

• Hover over menu items to see gist description

• System service to create gists from selected text (assign a keyboard shortcut in System Preferences)

• Command + a to toggle anonymous when naming your gist

• Command + s to toggle secret when naming your gist

• Hold option key when clicking on a gist in the history menu to edit gist

• Hold command key when clicking on a gist in the history menu to delete gist

• Notification center notice after gist creation and deletion



## History

This is not the first codebase. This was complete rewrite with the intention to make the source public.

