# Bespoke installer for Genentech

This is an unattended (i.e. no user interaction required other than perhaps starting it) install of Jalview on
Windows.

There are three additional steps to the install (other than running the normal installer with `-q`).

1. An smb share is added (this isn't intrinsic to the install, although root certs etc could be found there).

1. The unattended install of Jalview (`-q`) adds in a GUI progress bar with alerts if something goes wrong (`-splash -alerts`).  It still requires no user intervention.

1. The organisation's CA certificates are downloaded from their web page and inserted into the certificate store in the JRE that is bundled with Jalview.  This is potentially very useful for other organisations.

1. A customised .jalview_properties is put in place for the user.

## some notes

* Using `Start-Process -Wait` instead of `Invoke-Expression` because obviously the install has to complete before the certificates can be added.  Doing this for the keytool operation makes capturing the output a bit rubbish, and so it has to go via a temporary file.  Only the first line of output is reported to the user which will signify the certificate was added, or was already there.

* The `.bat` file is a super generic DOS script that uses various DOS incantations and stirring of giblets to find the powershell executable and then run the powershell script of the same name (but with a `.ps1` extension instead of `.bat`) that is sitting next to it in the same folder.  It will also pass on any args it gets so is very useful for user command line usage (since a `.bat` is "executable".  Even better if the folder is in the user's PATH).
