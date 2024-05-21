Output demo.webm

Set Shell "bash"
Set FontSize 22
Set Width 1920
Set Height 1080
Set LetterSpacing 1
Set LineHeight 1.2
Set Theme "Catppuccin Mocha"
Set Padding 50
Set Framerate 60
Set PlaybackSpeed 0.9
Set TypingSpeed 0.2
Set CursorBlink false

Sleep 2
Type "Remove old PKI data"
Sleep 6
Ctrl+u
Type "make clean"
Enter
Sleep 4
Type "yes"
Enter
Sleep 4

Ctrl+L
Type "List repo files"
Sleep 6
Ctrl+u
Type "tree"
Enter
Sleep 6

Ctrl+L
Type 'Create Root and Signing certificate'
Sleep 6
Ctrl+u
Type "make"
Sleep 4
Enter
Sleep 4
Type "y"
Enter
Sleep 4
Type "y"
Enter
Sleep 4
Type "y"
Enter
Sleep 4
Type "y"
Enter
Sleep 4

Ctrl+L
Type "Show configuration"
Sleep 6
Ctrl+u
Type "make"
Sleep 4
Enter
Sleep 4

Ctrl+L
Type "Set COMMON_NAME"
Sleep 6
Ctrl+u
Type "export COMMON_NAME=db.lab5.ca"
Sleep 4
Enter
Sleep 4
Type "Generate certificate bundle"
Sleep 6
Ctrl+u
Type "make"
Sleep 4
Enter
Sleep 4
Type "yes"
Enter
Sleep 4
Type "y"
Enter
Sleep 4
Type "y"
Enter
Sleep 4

Ctrl+L
Type "List generated certificates"
Sleep 6
Ctrl+u
Type "tree certs/"
Sleep 4
Enter
Sleep 6

Ctrl+L
Type "Show PEM certificate"
Sleep 6
Ctrl+u
Type "make show-crt | less"
Sleep 4
Enter
Sleep 4
Space
Sleep 4
Type "q"
Sleep 4

Ctrl+L
Type "Show P12 certificate"
Sleep 6
Ctrl+u
Type "make show-p12 | less"
Sleep 4
Enter
Sleep 4
Space
Sleep 4
Type "q"
Sleep 4
