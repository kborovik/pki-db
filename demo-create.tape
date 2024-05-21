Output demo-create.gif

Set Shell "bash"
Set FontSize 42
Set Width 3000
Set Height 1500
Set LetterSpacing 1
Set LineHeight 1.0
Set Theme "Catppuccin Mocha"
Set Padding 50
Set Framerate 60
Set PlaybackSpeed 0.5
Set TypingSpeed 0.2
Set CursorBlink true

Sleep 8
Type "Remove old PKI data"
Sleep 8
Ctrl+u
Type "make clean"
Enter 1
Sleep 8
Type "yes"
Enter 1
Sleep 8

Enter 1
Type "List repo files"
Sleep 8
Ctrl+u
Type "tree --dirsfirst"
Enter 1
Sleep 16

# Ctrl+L
# Type 'Create Root and Signing certificates'
# Sleep 6
# Ctrl+u
# Type "make"
# Sleep 4
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4
# Type "y"
# Enter
# Sleep 4

# Ctrl+L
# Type "Show configuration"
# Sleep 6
# Ctrl+u
# Type "make"
# Sleep 4
# Enter
# Sleep 4

# Ctrl+L
# Type "Set COMMON_NAME"
# Sleep 6
# Ctrl+u
# Type "export COMMON_NAME=db.lab5.ca"
# Enter
# Sleep 4
# Type "Generate certificate bundle"
# Sleep 6
# Ctrl+u
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
# Ctrl+u
# Type "tree certs/"
# Enter
# Sleep 6

# Ctrl+L
# Type "Show PEM certificate"
# Sleep 6
# Ctrl+u
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
# Ctrl+u
# Type "make show-p12 | less"
# Sleep 4
# Enter
# Sleep 4
# Space
# Sleep 4
# Type "q"
# Sleep 4
