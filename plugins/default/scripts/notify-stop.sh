#!/bin/bash
powershell.exe -NoProfile -NonInteractive -Command "
  Add-Type -AssemblyName System.Windows.Forms
  \$n = New-Object System.Windows.Forms.NotifyIcon
  \$n.Icon = [System.Drawing.SystemIcons]::Information
  \$n.Visible = \$true
  \$n.ShowBalloonTip(4000, 'Claude Code', '작업이 완료되었습니다', [System.Windows.Forms.ToolTipIcon]::Info)
  Start-Sleep -Seconds 4
  \$n.Dispose()
" &
