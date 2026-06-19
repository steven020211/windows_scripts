Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
name = fso.GetBaseName(WScript.ScriptFullName)
src = fso.GetParentFolderName(WScript.ScriptFullName) & "\" & name & ".ps1"
dst = shell.ExpandEnvironmentStrings("%TEMP%") & "\" & name & ".ps1"
fso.CreateTextFile(dst, True).Write fso.OpenTextFile(src).ReadAll
CreateObject("Shell.Application").ShellExecute "powershell.exe", "-NoExit -ExecutionPolicy Bypass -File """ & dst & """", "", "runas", 1
