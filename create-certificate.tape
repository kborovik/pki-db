Output create-certificate.mp4

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

Type "Show current configuration"
Sleep 3
Ctrl+U
Type "make"
Sleep 3
Enter
Sleep 5

Enter 2
Type "Set certificate Common Name"
Sleep 3
Ctrl+U
Type "export COMMON_NAME=db.lab5.ca"
Enter
Sleep 5

Enter 2
Type "Generate certificate bundle"
Sleep 3
Ctrl+U
Type "make"
Sleep 5
Enter
Sleep 3
Type "yes"
Sleep 2
Enter
Sleep 3
Type "y"
Sleep 2
Enter
Sleep 3
Type "y"
Sleep 2
Enter
Sleep 5

Ctrl+L
Type "List generated certificates"
Sleep 3
Ctrl+U
Type "tree certs/"
Enter
Sleep 5

Ctrl+L
Type "Show PEM certificate"
Sleep 3
Ctrl+U
Type "make show-crt | less"
Sleep 4
Enter
Sleep 4
Space
Sleep 4
Type "q"

Ctrl+L
Type "Certificate secret keys encrypted with a password. Show unencrypted certificate secret key"
Sleep 3
Ctrl+U
Type "make show-key"
Enter
Sleep 4

Ctrl+L
Type "Show certificate password"
Sleep 3
Ctrl+U
Type "make show-pass"
Enter 2
Sleep 4

Ctrl+L
Type "Show P12 certificate"
Sleep 3
Ctrl+U
Type "make show-p12 | less"
Sleep 4
Enter
Sleep 4
Space
Sleep 4
Type "q"
Sleep 4
