Output create-ca-authority.mp4

Set Shell "bash"
Set FontSize 30
Set Width 1920
Set Height 1080
Set LetterSpacing 1
Set LineHeight 1.0
Set Theme "Catppuccin Mocha"
Set Padding 50
Set Framerate 30
Set PlaybackSpeed 1.0
Set TypingSpeed 0.1
Set CursorBlink true

Type "Remove old PKI data"
Sleep 3
Ctrl+U
Type "make clean"
Sleep 3
Enter 1
Sleep 3
Type "yes"
Enter 1
Sleep 3

Enter 1
Type "List Certificate Authority files"
Sleep 3
Ctrl+U
Type "tree --dirsfirst ca/"
Sleep 3
Enter 1
Sleep 3

Ctrl+L
Type 'Create Root and Signing certificates'
Sleep 3
Ctrl+U
Type "make"
Sleep 3
Enter 1
Sleep 3
Type "y"
Sleep 2
Enter 1
Sleep 3
Type "y"
Sleep 2
Enter 1
Sleep 3
Type "y"
Sleep 2
Enter 1
Sleep 3
Type "y"
Sleep 2
Enter 1
Sleep 3

Ctrl+L
Type "List Certificate Authority files"
Sleep 3
Ctrl+U
Type "tree --dirsfirst ca/"
Sleep 3
Enter 1
Sleep 5
