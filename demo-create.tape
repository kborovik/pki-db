Output demo-create.mp4

Set Shell "bash"
Set FontSize 24
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

Sleep 1
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

# Ctrl+L
# Type "Show configuration"
# Sleep 6
# Ctrl+U
# Type "make"
# Sleep 4
# Enter
# Sleep 4

# Ctrl+L
# Type "Set COMMON_NAME"
# Sleep 6
# Ctrl+U
# Type "export COMMON_NAME=db.lab5.ca"
# Enter
# Sleep 4
# Type "Generate certificate bundle"
# Sleep 6
# Ctrl+U
# Type "make"
# Sleep 4
# Enter
# Sleep 4
# Type "yes"
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4

# Ctrl+L
# Type "List generated certificates"
# Sleep 6
# Ctrl+U
# Type "tree certs/"
# Enter
# Sleep 6

# Ctrl+L
# Type "Show PEM certificate"
# Sleep 6
# Ctrl+U
# Type "make show-crt | less"
# Sleep 4
# Enter
# Sleep 4
# Space
# Sleep 4
# Type "q"
# Sleep 4

# Ctrl+L
# Type "Show P12 certificate"
# Sleep 6
# Ctrl+U
# Type "make show-p12 | less"
# Sleep 4
# Enter
# Sleep 4
# Space
# Sleep 4
# Type "q"
# Sleep 4
