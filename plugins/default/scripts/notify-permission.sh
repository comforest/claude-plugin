#!/bin/bash
command -v powershell.exe &>/dev/null || exit 0

powershell.exe -NoProfile -NonInteractive -Command "
  Add-Type -AssemblyName System.Windows.Forms
  \$n = New-Object System.Windows.Forms.NotifyIcon
  \$n.Icon = [System.Drawing.SystemIcons]::Warning
  \$n.Visible = \$true
  \$n.ShowBalloonTip(4000, 'Claude Code', '권한 확인이 필요합니다', [System.Windows.Forms.ToolTipIcon]::Warning)
  Start-Sleep -Seconds 4
  \$n.Dispose()
" &>/dev/null || true
