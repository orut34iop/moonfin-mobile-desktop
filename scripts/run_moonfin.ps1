$proc = Start-Process -FilePath "C:\Users\wiz\Desktop\moonfin_build\moonfin.exe" -NoNewWindow -Wait -PassThru -RedirectStandardError "C:\Users\wiz\Desktop\moon_err.txt" -RedirectStandardOutput "C:\Users\wiz\Desktop\moon_out.txt"
Write-Host "Exit code: $($proc.ExitCode)"
Write-Host "--- STDERR ---"
Get-Content "C:\Users\wiz\Desktop\moon_err.txt" -ErrorAction SilentlyContinue
Write-Host "--- STDOUT ---"
Get-Content "C:\Users\wiz\Desktop\moon_out.txt" -ErrorAction SilentlyContinue
