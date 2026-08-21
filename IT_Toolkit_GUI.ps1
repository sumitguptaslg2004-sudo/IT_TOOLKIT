# ============================================================
#  IT TECHNICIAN TOOLKIT - GUI Edition (PowerShell WinForms)
#  Run via Launch_IT_Toolkit_GUI.bat, or:
#    powershell -NoProfile -ExecutionPolicy Bypass -File .\IT_Toolkit_GUI.ps1
#  Or remotely (once hosted - see setup notes at the bottom of this file):
#    irm https://raw.githubusercontent.com/YOURNAME/YOURREPO/main/IT_Toolkit_GUI.ps1 | iex
# ============================================================

# Fill this in once you host the script (see hosting notes at the end of this
# file). Needed so self-elevation can relaunch itself correctly when the
# script was run via "irm <url> | iex" instead of from a saved .ps1 file.
$script:RemoteUrl = "https://raw.githubusercontent.com/sumitguptaslg2004-sudo/IT_TOOLKIT/refs/heads/main/IT_Toolkit_GUI.ps1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# --- Self-elevate to Administrator ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        # Running from a real saved .ps1 file (double-clicked launcher, etc.)
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } elseif ($script:RemoteUrl) {
        # Running via "irm <url> | iex" - there's no local file to re-launch,
        # so re-run the same remote command in a new elevated session instead.
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"irm $script:RemoteUrl | iex`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("This needs to run as Administrator, but couldn't auto-elevate (no file path and no RemoteUrl configured). Right-click PowerShell and 'Run as administrator', then try again.", "Elevation Needed") | Out-Null
    }
    exit
}
[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
#  HELPER FUNCTIONS
# ============================================================

function Get-TextInput {
    param($Prompt, $Title, $Default = "")
    return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt, $Title, $Default)
}

function Confirm-Action {
    param($Message, $Title = "Confirm")
    $result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, `
        [System.Windows.Forms.MessageBoxButtons]::YesNo, `
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Show-AddUserDialog {
    # Full local-user creation dialog: username, masked password + confirm,
    # admin/standard privilege choice, additional group memberships, and
    # common account policy options. Returns a hashtable, or $null if cancelled.
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Add Local User"
    $f.Size = New-Object System.Drawing.Size(380, 500)
    $f.StartPosition = "CenterParent"
    $f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.MaximizeBox = $false
    $f.MinimizeBox = $false

    $y = 15
    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text = "Username:"
    $lblUser.Location = New-Object System.Drawing.Point(15, $y)
    $lblUser.AutoSize = $true
    $f.Controls.Add($lblUser)
    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Location = New-Object System.Drawing.Point(150, ($y - 3))
    $txtUser.Size = New-Object System.Drawing.Size(190, 22)
    $f.Controls.Add($txtUser)

    $y += 35
    $lblPass = New-Object System.Windows.Forms.Label
    $lblPass.Text = "Password:"
    $lblPass.Location = New-Object System.Drawing.Point(15, $y)
    $lblPass.AutoSize = $true
    $f.Controls.Add($lblPass)
    $txtPass = New-Object System.Windows.Forms.TextBox
    $txtPass.Location = New-Object System.Drawing.Point(150, ($y - 3))
    $txtPass.Size = New-Object System.Drawing.Size(190, 22)
    $txtPass.UseSystemPasswordChar = $true
    $f.Controls.Add($txtPass)

    $y += 35
    $lblPass2 = New-Object System.Windows.Forms.Label
    $lblPass2.Text = "Confirm Password:"
    $lblPass2.Location = New-Object System.Drawing.Point(15, $y)
    $lblPass2.AutoSize = $true
    $f.Controls.Add($lblPass2)
    $txtPass2 = New-Object System.Windows.Forms.TextBox
    $txtPass2.Location = New-Object System.Drawing.Point(150, ($y - 3))
    $txtPass2.Size = New-Object System.Drawing.Size(190, 22)
    $txtPass2.UseSystemPasswordChar = $true
    $f.Controls.Add($txtPass2)

    $y += 40
    $grp = New-Object System.Windows.Forms.GroupBox
    $grp.Text = "Account Type"
    $grp.Location = New-Object System.Drawing.Point(15, $y)
    $grp.Size = New-Object System.Drawing.Size(325, 55)
    $f.Controls.Add($grp)
    $radStd = New-Object System.Windows.Forms.RadioButton
    $radStd.Text = "Standard User"
    $radStd.Location = New-Object System.Drawing.Point(15, 22)
    $radStd.AutoSize = $true
    $radStd.Checked = $true
    $grp.Controls.Add($radStd)
    $radAdmin = New-Object System.Windows.Forms.RadioButton
    $radAdmin.Text = "Administrator"
    $radAdmin.Location = New-Object System.Drawing.Point(160, 22)
    $radAdmin.AutoSize = $true
    $grp.Controls.Add($radAdmin)

    $y += 65
    $grpPriv = New-Object System.Windows.Forms.GroupBox
    $grpPriv.Text = "Additional Privileges (optional)"
    $grpPriv.Location = New-Object System.Drawing.Point(15, $y)
    $grpPriv.Size = New-Object System.Drawing.Size(325, 95)
    $f.Controls.Add($grpPriv)
    $chkRemoteDesktop = New-Object System.Windows.Forms.CheckBox
    $chkRemoteDesktop.Text = "Remote Desktop Users (allow RDP login)"
    $chkRemoteDesktop.Location = New-Object System.Drawing.Point(15, 22)
    $chkRemoteDesktop.AutoSize = $true
    $grpPriv.Controls.Add($chkRemoteDesktop)
    $chkBackupOp = New-Object System.Windows.Forms.CheckBox
    $chkBackupOp.Text = "Backup Operators"
    $chkBackupOp.Location = New-Object System.Drawing.Point(15, 46)
    $chkBackupOp.AutoSize = $true
    $grpPriv.Controls.Add($chkBackupOp)
    $chkPowerUser = New-Object System.Windows.Forms.CheckBox
    $chkPowerUser.Text = "Power Users (legacy compatibility)"
    $chkPowerUser.Location = New-Object System.Drawing.Point(15, 70)
    $chkPowerUser.AutoSize = $true
    $grpPriv.Controls.Add($chkPowerUser)

    $y += 105
    $chkMustChange = New-Object System.Windows.Forms.CheckBox
    $chkMustChange.Text = "Require password change at next logon"
    $chkMustChange.Location = New-Object System.Drawing.Point(15, $y)
    $chkMustChange.AutoSize = $true
    $chkMustChange.Checked = $true
    $f.Controls.Add($chkMustChange)

    $y += 28
    $chkNeverExpires = New-Object System.Windows.Forms.CheckBox
    $chkNeverExpires.Text = "Password never expires"
    $chkNeverExpires.Location = New-Object System.Drawing.Point(15, $y)
    $chkNeverExpires.AutoSize = $true
    $f.Controls.Add($chkNeverExpires)

    $y += 35
    $lblError = New-Object System.Windows.Forms.Label
    $lblError.Location = New-Object System.Drawing.Point(15, $y)
    $lblError.Size = New-Object System.Drawing.Size(325, 20)
    $lblError.ForeColor = [System.Drawing.Color]::Red
    $f.Controls.Add($lblError)

    $y += 25
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Create User"
    $btnOk.Location = New-Object System.Drawing.Point(150, $y)
    $btnOk.Size = New-Object System.Drawing.Size(110, 30)
    $f.Controls.Add($btnOk)
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(265, $y)
    $btnCancel.Size = New-Object System.Drawing.Size(75, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $f.Controls.Add($btnCancel)
    $f.CancelButton = $btnCancel

    $btnOk.Add_Click({
        if ($txtUser.Text.Trim() -eq "") { $lblError.Text = "Username is required."; return }
        if ($txtPass.Text -eq "") { $lblError.Text = "Password is required."; return }
        if ($txtPass.Text -ne $txtPass2.Text) { $lblError.Text = "Passwords do not match."; return }
        $f.Tag = "OK"
        $f.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    $result = $f.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    return @{
        Username        = $txtUser.Text.Trim()
        Password        = $txtPass.Text
        IsAdmin         = $radAdmin.Checked
        RemoteDesktop   = $chkRemoteDesktop.Checked
        BackupOperator  = $chkBackupOp.Checked
        PowerUser       = $chkPowerUser.Checked
        MustChange      = $chkMustChange.Checked
        NeverExpires    = $chkNeverExpires.Checked
    }
}

function Show-RobocopyDialog {
    # Robocopy wrapper dialog: source/destination folder pickers + mode choice.
    # Returns a hashtable, or $null if cancelled.
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Robocopy - File/Folder Copy"
    $f.Size = New-Object System.Drawing.Size(480, 520)
    $f.StartPosition = "CenterParent"
    $f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.MaximizeBox = $false
    $f.MinimizeBox = $false

    $y = 15
    $lblSrc = New-Object System.Windows.Forms.Label
    $lblSrc.Text = "Source folder:"
    $lblSrc.Location = New-Object System.Drawing.Point(15, $y)
    $lblSrc.AutoSize = $true
    $f.Controls.Add($lblSrc)
    $y += 20
    $txtSrc = New-Object System.Windows.Forms.TextBox
    $txtSrc.Location = New-Object System.Drawing.Point(15, $y)
    $txtSrc.Size = New-Object System.Drawing.Size(340, 22)
    $txtSrc.ReadOnly = $true
    $f.Controls.Add($txtSrc)
    $btnBrowseSrc = New-Object System.Windows.Forms.Button
    $btnBrowseSrc.Text = "Browse..."
    $btnBrowseSrc.Location = New-Object System.Drawing.Point(365, ($y - 1))
    $btnBrowseSrc.Size = New-Object System.Drawing.Size(85, 24)
    $f.Controls.Add($btnBrowseSrc)
    $btnBrowseSrc.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtSrc.Text = $fbd.SelectedPath }
    })

    $y += 40
    $lblDst = New-Object System.Windows.Forms.Label
    $lblDst.Text = "Destination folder:"
    $lblDst.Location = New-Object System.Drawing.Point(15, $y)
    $lblDst.AutoSize = $true
    $f.Controls.Add($lblDst)
    $y += 20
    $txtDst = New-Object System.Windows.Forms.TextBox
    $txtDst.Location = New-Object System.Drawing.Point(15, $y)
    $txtDst.Size = New-Object System.Drawing.Size(340, 22)
    $txtDst.ReadOnly = $true
    $f.Controls.Add($txtDst)
    $btnBrowseDst = New-Object System.Windows.Forms.Button
    $btnBrowseDst.Text = "Browse..."
    $btnBrowseDst.Location = New-Object System.Drawing.Point(365, ($y - 1))
    $btnBrowseDst.Size = New-Object System.Drawing.Size(85, 24)
    $f.Controls.Add($btnBrowseDst)
    $btnBrowseDst.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtDst.Text = $fbd.SelectedPath }
    })

    $y += 40
    $chkSubfolder = New-Object System.Windows.Forms.CheckBox
    $chkSubfolder.Text = "Copy INTO a new subfolder named after the source (recommended)"
    $chkSubfolder.Location = New-Object System.Drawing.Point(15, $y)
    $chkSubfolder.AutoSize = $true
    $chkSubfolder.Checked = $true
    $f.Controls.Add($chkSubfolder)
    $lblSubfolderHint = New-Object System.Windows.Forms.Label
    $lblSubfolderHint.Text = "Unchecked: Robocopy dumps the CONTENTS of the source directly into the destination folder (this is standard Robocopy behavior and a common surprise - e.g. copying into your Desktop this way scatters loose files instead of keeping them in one folder)."
    $lblSubfolderHint.Location = New-Object System.Drawing.Point(15, ($y + 20))
    $lblSubfolderHint.Size = New-Object System.Drawing.Size(435, 45)
    $lblSubfolderHint.ForeColor = [System.Drawing.Color]::Gray
    $lblSubfolderHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $f.Controls.Add($lblSubfolderHint)

    $y += 75
    $grpMode = New-Object System.Windows.Forms.GroupBox
    $grpMode.Text = "Mode"
    $grpMode.Location = New-Object System.Drawing.Point(15, $y)
    $grpMode.Size = New-Object System.Drawing.Size(435, 95)
    $f.Controls.Add($grpMode)
    $radCopy = New-Object System.Windows.Forms.RadioButton
    $radCopy.Text = "Copy (add new / update changed files, keeps extras in destination)"
    $radCopy.Location = New-Object System.Drawing.Point(15, 20)
    $radCopy.AutoSize = $true
    $radCopy.Checked = $true
    $grpMode.Controls.Add($radCopy)
    $radMirror = New-Object System.Windows.Forms.RadioButton
    $radMirror.Text = "Mirror (exact copy - DELETES files in destination not in source)"
    $radMirror.Location = New-Object System.Drawing.Point(15, 44)
    $radMirror.AutoSize = $true
    $grpMode.Controls.Add($radMirror)
    $radMove = New-Object System.Windows.Forms.RadioButton
    $radMove.Text = "Move (copy then DELETE the source files)"
    $radMove.Location = New-Object System.Drawing.Point(15, 68)
    $radMove.AutoSize = $true
    $grpMode.Controls.Add($radMove)

    $y += 105
    $chkMultiThread = New-Object System.Windows.Forms.CheckBox
    $chkMultiThread.Text = "Multi-threaded (/MT:8) - faster for many small files"
    $chkMultiThread.Location = New-Object System.Drawing.Point(15, $y)
    $chkMultiThread.AutoSize = $true
    $chkMultiThread.Checked = $true
    $f.Controls.Add($chkMultiThread)

    $y += 28
    $chkVerbose = New-Object System.Windows.Forms.CheckBox
    $chkVerbose.Text = "Verbose logging (list every file processed)"
    $chkVerbose.Location = New-Object System.Drawing.Point(15, $y)
    $chkVerbose.AutoSize = $true
    $f.Controls.Add($chkVerbose)

    $y += 35
    $lblError = New-Object System.Windows.Forms.Label
    $lblError.Location = New-Object System.Drawing.Point(15, $y)
    $lblError.Size = New-Object System.Drawing.Size(435, 40)
    $lblError.ForeColor = [System.Drawing.Color]::Red
    $f.Controls.Add($lblError)

    $y += 45
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Run Robocopy"
    $btnOk.Location = New-Object System.Drawing.Point(255, $y)
    $btnOk.Size = New-Object System.Drawing.Size(110, 30)
    $f.Controls.Add($btnOk)
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(370, $y)
    $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $f.Controls.Add($btnCancel)
    $f.CancelButton = $btnCancel

    $btnOk.Add_Click({
        if ($txtSrc.Text.Trim() -eq "") { $lblError.Text = "Choose a source folder."; return }
        if ($txtDst.Text.Trim() -eq "") { $lblError.Text = "Choose a destination folder."; return }
        if ($txtSrc.Text.Trim() -ieq $txtDst.Text.Trim()) { $lblError.Text = "Source and destination can't be the same folder."; return }
        $f.Tag = "OK"
        $f.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    $result = $f.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $mode = if ($radMirror.Checked) { "Mirror" } elseif ($radMove.Checked) { "Move" } else { "Copy" }
    $effectiveDest = $txtDst.Text.Trim()
    if ($chkSubfolder.Checked) {
        $sourceFolderName = Split-Path -Path $txtSrc.Text.Trim() -Leaf
        # If the source is a drive root (e.g. "C:\"), Split-Path -Leaf returns
        # an empty string - fall back to a sensible name instead of silently
        # skipping the subfolder or building a broken destination path.
        if ([string]::IsNullOrWhiteSpace($sourceFolderName)) {
            $driveLetter = ($txtSrc.Text.Trim() -replace '[:\\]', '')
            $sourceFolderName = "$($driveLetter)_Drive"
        }
        $effectiveDest = Join-Path $txtDst.Text.Trim() $sourceFolderName
    }
    return @{
        Source          = $txtSrc.Text.Trim()
        Destination     = $effectiveDest
        DestinationRoot = $txtDst.Text.Trim()
        UsedSubfolder   = $chkSubfolder.Checked
        Mode            = $mode
        MultiThread     = $chkMultiThread.Checked
        Verbose         = $chkVerbose.Checked
    }
}

function Show-DevicePicker {
    # Small picker dialog listing devices from the last network scan.
    # Returns a MAC address string, "MANUAL" (user wants to type one), or $null (cancelled).
    param($Devices)
    $pickForm = New-Object System.Windows.Forms.Form
    $pickForm.Text = "Select a Device to Wake"
    $pickForm.Size = New-Object System.Drawing.Size(560, 400)
    $pickForm.StartPosition = "CenterParent"
    $pickForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $pickForm.MaximizeBox = $false
    $pickForm.MinimizeBox = $false

    $lv = New-Object System.Windows.Forms.ListView
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.Dock = [System.Windows.Forms.DockStyle]::Top
    $lv.Height = 290
    $lv.Columns.Add("IP", 110) | Out-Null
    $lv.Columns.Add("Hostname", 150) | Out-Null
    $lv.Columns.Add("MAC", 130) | Out-Null
    $lv.Columns.Add("Vendor", 110) | Out-Null
    foreach ($d in $Devices) {
        $item = New-Object System.Windows.Forms.ListViewItem($d."IP Address")
        $item.SubItems.Add([string]$d.Hostname) | Out-Null
        $item.SubItems.Add([string]$d."MAC Address") | Out-Null
        $item.SubItems.Add([string]$d.Vendor) | Out-Null
        $lv.Items.Add($item) | Out-Null
    }
    $pickForm.Controls.Add($lv)

    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $btnPanel.Height = 50
    $pickForm.Controls.Add($btnPanel)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Wake Selected"
    $btnOk.Location = New-Object System.Drawing.Point(20, 10)
    $btnOk.Size = New-Object System.Drawing.Size(120, 30)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnPanel.Controls.Add($btnOk)

    $btnManual = New-Object System.Windows.Forms.Button
    $btnManual.Text = "Enter MAC Manually"
    $btnManual.Location = New-Object System.Drawing.Point(150, 10)
    $btnManual.Size = New-Object System.Drawing.Size(150, 30)
    $btnManual.DialogResult = [System.Windows.Forms.DialogResult]::Retry
    $btnPanel.Controls.Add($btnManual)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(310, 10)
    $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btnPanel.Controls.Add($btnCancel)

    $pickForm.AcceptButton = $btnOk
    $pickForm.CancelButton = $btnCancel

    $result = $pickForm.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($lv.SelectedItems.Count -gt 0) { return $lv.SelectedItems[0].SubItems[2].Text }
        return $null
    } elseif ($result -eq [System.Windows.Forms.DialogResult]::Retry) {
        return "MANUAL"
    }
    return $null
}

function Send-WakeOnLan {
    param([string]$Mac)
    $macClean = ($Mac -replace '[:\-\s]', '').ToUpper()
    if ($macClean.Length -ne 12 -or $macClean -notmatch '^[0-9A-F]{12}$') {
        throw "Invalid MAC address format. Expected something like AA:BB:CC:DD:EE:FF."
    }
    $macBytes = for ($i = 0; $i -lt 12; $i += 2) { [Convert]::ToByte($macClean.Substring($i,2), 16) }
    $packet = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i -lt 6; $i++) { $packet.Add(0xFF) }
    for ($i = 0; $i -lt 16; $i++) { $packet.AddRange([byte[]]$macBytes) }
    $bytes = $packet.ToArray()

    $udp = New-Object System.Net.Sockets.UdpClient
    try {
        $udp.EnableBroadcast = $true
        $udp.Connect(([System.Net.IPAddress]::Broadcast), 9)
        $udp.Send($bytes, $bytes.Length) | Out-Null
    } finally {
        $udp.Close()
    }
}

$script:LogColorDefault = [System.Drawing.Color]::FromArgb(140,230,140)
$script:LogColorError   = [System.Drawing.Color]::FromArgb(255,90,90)
$script:LogColorWarn    = [System.Drawing.Color]::FromArgb(255,180,60)
$script:LogColorHeader  = [System.Drawing.Color]::FromArgb(100,180,255)
$script:LogColorSuccess = [System.Drawing.Color]::FromArgb(120,230,150)

# --- Persistent session logging: every log line is also auto-saved to disk,
#     not just when the user manually clicks "Save Log" ---
$script:LogsDir = Join-Path ([Environment]::GetFolderPath("Desktop")) "IT Toolkit Logs"
$script:LogFileWriter = $null
try {
    if (-not (Test-Path -LiteralPath $script:LogsDir)) { New-Item -Path $script:LogsDir -ItemType Directory -Force | Out-Null }
    $script:LogFilePath = Join-Path $script:LogsDir "Session_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    $script:LogFileWriter = New-Object System.IO.StreamWriter($script:LogFilePath, $true)
    $script:LogFileWriter.AutoFlush = $true
} catch {
    # If the Desktop folder can't be created/written (e.g. redirected Desktop, permissions),
    # the app still works fine - it just won't have a persistent log file for this session.
    $script:LogFilePath = $null
}

function Write-Log {
    param([string]$Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $Text`r`n"

    $color = $script:LogColorDefault
    if ($Text -match '(?i)error|failed|exception|denied|cannot|could not') {
        $color = $script:LogColorError
    } elseif ($Text -match '(?i)warning|warn\b|caution') {
        $color = $script:LogColorWarn
    } elseif ($Text -match '^===.*===$') {
        $color = $script:LogColorHeader
    } elseif ($Text -match '(?i)complete|success|applied|enabled|launched|saved|finished|ready') {
        $color = $script:LogColorSuccess
    }

    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = $color
    $logBox.AppendText($line)
    $logBox.SelectionColor = $script:LogColorDefault
    $logBox.ScrollToCaret()

    if ($script:LogFileWriter) {
        try { $script:LogFileWriter.WriteLine("[$timestamp] $Text") } catch {}
    }
}

$script:AllButtons = New-Object System.Collections.Generic.List[System.Windows.Forms.Button]
$script:AllTabPanels = New-Object System.Collections.Generic.List[System.Windows.Forms.FlowLayoutPanel]
$script:IsDarkTheme = $false
$script:ConsoleCwd = $env:USERPROFILE
$script:CmdHistory = New-Object System.Collections.Generic.List[string]
$script:CmdHistoryIndex = 0

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    foreach ($b in $script:AllButtons) { $b.Enabled = $Enabled }
    if ($cmdInput) { $cmdInput.Enabled = $Enabled }
}

$script:CurrentJob = $null
$script:JobTimer = New-Object System.Windows.Forms.Timer
$script:JobTimer.Interval = 400
$script:JobTimer.Add_Tick({
    if ($script:CurrentJob) {
        # Drain any new output as it's produced (live streaming)
        $output = Receive-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue
        if ($output) {
            foreach ($item in $output) {
                $lineStr = [string]$item
                if ($lineStr -like "###CWD###*") {
                    # Interactive console commands report their final directory this way
                    # so 'cd' feels persistent even though each command runs in a fresh job.
                    $script:ConsoleCwd = $lineStr.Substring(9)
                    if ($cmdPromptLabel) { $cmdPromptLabel.Text = "PS $script:ConsoleCwd> " }
                } else {
                    Write-Log $lineStr
                }
            }
        }
        if ($script:CurrentJob.State -in @('Completed','Failed','Stopped')) {
            $script:JobTimer.Stop()
            if ($script:CurrentJob.State -eq 'Failed') {
                Write-Log "Task reported an error. Check output above."
            }
            Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
            Write-Log "=== Finished: $($script:JobTimer.Tag) ==="
            $script:CurrentJob = $null

            if ($script:TaskQueue.Count -gt 0) {
                $next = $script:TaskQueue.Dequeue()
                Start-JobInternal -Name $next.Name -Script $next.Script -ArgumentList $next.ArgumentList
            } else {
                $statusLabel.Text = "Ready"
                Set-ButtonsEnabled $true
            }
        }
    }
})

$script:TaskQueue = New-Object System.Collections.Generic.Queue[object]

function Start-JobInternal {
    # Actually starts a job. Used both for the first task and for auto-starting
    # the next queued follow-up task once the current one finishes.
    param($Name, [scriptblock]$Script, $ArgumentList)
    Write-Log "=== Starting: $Name ==="
    $queueNote = if ($script:TaskQueue.Count -gt 0) { "  ($($script:TaskQueue.Count) more queued)" } else { "" }
    $statusLabel.Text = "Running: $Name...$queueNote"
    Set-ButtonsEnabled $false
    $script:CurrentJob = Start-Job -ScriptBlock $Script -ArgumentList $ArgumentList
    $script:JobTimer.Tag = $Name
    $script:JobTimer.Start()
}

function Start-ToolJob {
    param($Name, [scriptblock]$Script, $ArgumentList = @())
    if ($script:CurrentJob) {
        # Something's already running - queue this as a follow-up task instead
        # of blocking with a "busy" popup. It'll run automatically once the
        # current (and any earlier-queued) tasks finish.
        $script:TaskQueue.Enqueue([PSCustomObject]@{ Name = $Name; Script = $Script; ArgumentList = $ArgumentList })
        Write-Log "Queued as follow-up task: $Name  (position $($script:TaskQueue.Count) in queue)"
        $statusLabel.Text = "Running: $($script:JobTimer.Tag)  |  $($script:TaskQueue.Count) queued"
        return
    }
    Start-JobInternal -Name $Name -Script $Script -ArgumentList $ArgumentList
}

function Invoke-Launch {
    # For GUI tools that open their own window (no output to capture)
    param($Name, $FilePath, $Arguments = "")
    try {
        Write-Log "Launching $Name from: $FilePath"
        # Many portable apps need their own folder as the working directory to
        # find their config/data files - launching with the wrong cwd is a
        # common reason a portable tool silently fails to open.
        $workDir = Split-Path -Path $FilePath -Parent
        $spParams = @{ FilePath = $FilePath }
        if ($workDir -and (Test-Path -LiteralPath $workDir)) { $spParams["WorkingDirectory"] = $workDir }
        if ($Arguments -ne "") { $spParams["ArgumentList"] = $Arguments }
        Start-Process @spParams
        Write-Log "Launched: $Name"
    } catch {
        Write-Log "ERROR launching $Name : $($_.Exception.Message)"
    }
}

$script:AppToolTip = New-Object System.Windows.Forms.ToolTip
$script:AppToolTip.AutoPopDelay = 15000
$script:AppToolTip.InitialDelay = 400
$script:AppToolTip.ReshowDelay = 200
$script:AppToolTip.ShowAlways = $true

function New-ToolButton {
    param($Parent, $Text, [scriptblock]$OnClick, [string]$Tooltip = "")
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.AutoSize = $false
    $btn.Width = 260
    $btn.Height = 36
    $btn.Margin = New-Object System.Windows.Forms.Padding(6)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200,200,200)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(245,245,248)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $btn.Padding = New-Object System.Windows.Forms.Padding(8,0,0,0)
    $btn.Add_Click($OnClick)
    if ($Tooltip) { $script:AppToolTip.SetToolTip($btn, $Tooltip) }
    $Parent.Controls.Add($btn)
    $script:AllButtons.Add($btn)
    return $btn
}

function New-Tab {
    param($TabControlRef, $Title)
    $tabPage = New-Object System.Windows.Forms.TabPage
    $tabPage.Text = $Title
    $tabPage.Padding = New-Object System.Windows.Forms.Padding(10)
    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = [System.Windows.Forms.DockStyle]::Fill
    $flow.AutoScroll = $true
    $flow.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
    $flow.WrapContents = $true
    $tabPage.Controls.Add($flow)
    $TabControlRef.TabPages.Add($tabPage)
    $script:AllTabPanels.Add($flow)
    return $flow
}

# ============================================================
#  MAIN FORM
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "IT Technician Toolkit"
$form.Size = New-Object System.Drawing.Size(1120, 720)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(1110, 560)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$form.BackColor = [System.Drawing.Color]::White

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = [System.Windows.Forms.DockStyle]::Fill
$split.Orientation = [System.Windows.Forms.Orientation]::Horizontal
$split.SplitterWidth = 6
$form.Controls.Add($split)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabs.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$split.Panel1.Controls.Add($tabs)

# --- Bottom log panel ---
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$split.Panel2.Controls.Add($logPanel)

$logToolbar = New-Object System.Windows.Forms.Panel
$logToolbar.Dock = [System.Windows.Forms.DockStyle]::Top
$logToolbar.Height = 32
$logPanel.Controls.Add($logToolbar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(8, 8)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(30,120,30)
$logToolbar.Controls.Add($statusLabel)

$btnStopTask = New-Object System.Windows.Forms.Button
$btnStopTask.Text = "Stop Task"
$btnStopTask.Size = New-Object System.Drawing.Size(90, 24)
$btnStopTask.Location = New-Object System.Drawing.Point(660, 4)
$btnStopTask.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnStopTask.BackColor = [System.Drawing.Color]::FromArgb(255,235,235)
$btnStopTask.Add_Click({
    if ($script:CurrentJob -or $script:TaskQueue.Count -gt 0) {
        $script:JobTimer.Stop()
        if ($script:CurrentJob) {
            Stop-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue
            $output = Receive-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue
            if ($output) { $output | ForEach-Object { Write-Log ([string]$_) } }
            Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
        }
        $queuedCount = $script:TaskQueue.Count
        $script:TaskQueue.Clear()
        if ($queuedCount -gt 0) {
            Write-Log "=== Task stopped by user (also cleared $queuedCount queued follow-up task(s)) ==="
        } else {
            Write-Log "=== Task stopped by user ==="
        }
        $statusLabel.Text = "Ready"
        $script:CurrentJob = $null
        Set-ButtonsEnabled $true
    } else {
        [System.Windows.Forms.MessageBox]::Show("No task is currently running.", "Nothing to stop") | Out-Null
    }
})
$logToolbar.Controls.Add($btnStopTask)

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "Clear Log"
$btnClearLog.Size = New-Object System.Drawing.Size(90, 24)
$btnClearLog.Location = New-Object System.Drawing.Point(760, 4)
$btnClearLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnClearLog.Add_Click({ $logBox.Clear() })
$logToolbar.Controls.Add($btnClearLog)

$btnSaveLog = New-Object System.Windows.Forms.Button
$btnSaveLog.Text = "Save Log..."
$btnSaveLog.Size = New-Object System.Drawing.Size(90, 24)
$btnSaveLog.Location = New-Object System.Drawing.Point(860, 4)
$btnSaveLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnSaveLog.Add_Click({
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "Text Log|*.txt"
    $sfd.FileName = "IT-Toolkit-Log.txt"
    if ($script:LogsDir -and (Test-Path -LiteralPath $script:LogsDir)) { $sfd.InitialDirectory = $script:LogsDir }
    if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $logBox.Text | Out-File -FilePath $sfd.FileName -Encoding UTF8
    }
})
$logToolbar.Controls.Add($btnSaveLog)

$btnOpenLogsFolder = New-Object System.Windows.Forms.Button
$btnOpenLogsFolder.Text = "Logs Folder"
$btnOpenLogsFolder.Size = New-Object System.Drawing.Size(90, 24)
$btnOpenLogsFolder.Location = New-Object System.Drawing.Point(960, 4)
$btnOpenLogsFolder.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnOpenLogsFolder.Add_Click({
    if ($script:LogsDir -and (Test-Path -LiteralPath $script:LogsDir)) {
        Start-Process explorer.exe -ArgumentList "`"$script:LogsDir`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("The logs folder could not be created on this PC (check Desktop permissions).", "Logs Folder Unavailable") | Out-Null
    }
})
$logToolbar.Controls.Add($btnOpenLogsFolder)

$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = "Dark Mode"
$btnTheme.Size = New-Object System.Drawing.Size(90, 24)
$btnTheme.Location = New-Object System.Drawing.Point(560, 4)
$btnTheme.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$logToolbar.Controls.Add($btnTheme)

function Set-Theme {
    param([bool]$Dark)
    if ($Dark) {
        $bgMain    = [System.Drawing.Color]::FromArgb(32,32,36)
        $bgPanel   = [System.Drawing.Color]::FromArgb(40,40,44)
        $bgButton  = [System.Drawing.Color]::FromArgb(58,58,64)
        $fgButton  = [System.Drawing.Color]::FromArgb(235,235,235)
        $borderClr = [System.Drawing.Color]::FromArgb(80,80,86)
        $logBg     = [System.Drawing.Color]::FromArgb(18,18,20)
        $logFg     = [System.Drawing.Color]::FromArgb(140,230,140)
        $statusFg  = [System.Drawing.Color]::FromArgb(120,220,120)
        $btnTheme.Text = "Light Mode"
    } else {
        $bgMain    = [System.Drawing.Color]::White
        $bgPanel   = [System.Drawing.Color]::White
        $bgButton  = [System.Drawing.Color]::FromArgb(245,245,248)
        $fgButton  = [System.Drawing.Color]::Black
        $borderClr = [System.Drawing.Color]::FromArgb(200,200,200)
        $logBg     = [System.Drawing.Color]::FromArgb(18,18,20)
        $logFg     = [System.Drawing.Color]::FromArgb(140,230,140)
        $statusFg  = [System.Drawing.Color]::FromArgb(30,120,30)
        $btnTheme.Text = "Dark Mode"
    }

    $form.BackColor = $bgMain
    $tabs.BackColor = $bgMain
    foreach ($panel in $script:AllTabPanels) { $panel.BackColor = $bgPanel }
    foreach ($b in $script:AllButtons) {
        $b.BackColor = $bgButton
        $b.ForeColor = $fgButton
        $b.FlatAppearance.BorderColor = $borderClr
    }
    foreach ($b in @($btnStopTask, $btnClearLog, $btnSaveLog, $btnOpenLogsFolder, $btnTheme)) {
        $b.BackColor = $bgButton
        $b.ForeColor = $fgButton
    }
    $logPanel.BackColor = $bgMain
    $logToolbar.BackColor = $bgMain
    $logBox.BackColor = $logBg
    $logBox.ForeColor = $logFg
    $statusLabel.ForeColor = $statusFg
    $script:IsDarkTheme = $Dark
}
$btnTheme.Add_Click({ Set-Theme -Dark (-not $script:IsDarkTheme) })

# --- Interactive command bar - type a command and press Enter, like a console ---
$cmdBar = New-Object System.Windows.Forms.Panel
$cmdBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
$cmdBar.Height = 30
$cmdBar.BackColor = [System.Drawing.Color]::FromArgb(20,20,24)
$logPanel.Controls.Add($cmdBar)

$cmdPromptLabel = New-Object System.Windows.Forms.Label
$cmdPromptLabel.Text = "PS $script:ConsoleCwd> "
$cmdPromptLabel.AutoSize = $false
$cmdPromptLabel.Dock = [System.Windows.Forms.DockStyle]::Left
$cmdPromptLabel.Width = 260
$cmdPromptLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$cmdPromptLabel.ForeColor = [System.Drawing.Color]::FromArgb(140,230,140)
$cmdPromptLabel.BackColor = [System.Drawing.Color]::FromArgb(20,20,24)
$cmdPromptLabel.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$cmdBar.Controls.Add($cmdPromptLabel)

$cmdInput = New-Object System.Windows.Forms.TextBox
$cmdInput.Dock = [System.Windows.Forms.DockStyle]::Fill
$cmdInput.BackColor = [System.Drawing.Color]::FromArgb(20,20,24)
$cmdInput.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
$cmdInput.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$cmdInput.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$cmdBar.Controls.Add($cmdInput)
$cmdPromptLabel.BringToFront()

function Invoke-ConsoleCommand {
    param([string]$CmdText)
    if (-not $CmdText -or $CmdText.Trim() -eq "") { return }
    $CmdText = $CmdText.Trim()
    $script:CmdHistory.Add($CmdText)
    $script:CmdHistoryIndex = $script:CmdHistory.Count
    $cmdInput.Text = ""

    if ($CmdText -in @("cls","clear")) { $logBox.Clear(); return }

    Start-ToolJob "$($cmdPromptLabel.Text)$CmdText" {
        param($cmdText, $cwd)
        try { if (Test-Path -LiteralPath $cwd) { Set-Location -LiteralPath $cwd } } catch {}
        try {
            Invoke-Expression $cmdText 2>&1 | Out-String -Stream
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
        "###CWD###$((Get-Location).Path)"
    } -ArgumentList $CmdText, $script:ConsoleCwd
}

$cmdInput.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $e.SuppressKeyPress = $true
        Invoke-ConsoleCommand -CmdText $cmdInput.Text
    } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Up) {
        $e.SuppressKeyPress = $true
        if ($script:CmdHistory.Count -gt 0 -and $script:CmdHistoryIndex -gt 0) {
            $script:CmdHistoryIndex--
            $cmdInput.Text = $script:CmdHistory[$script:CmdHistoryIndex]
            $cmdInput.SelectionStart = $cmdInput.Text.Length
        }
    } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Down) {
        $e.SuppressKeyPress = $true
        if ($script:CmdHistory.Count -gt 0 -and $script:CmdHistoryIndex -lt ($script:CmdHistory.Count - 1)) {
            $script:CmdHistoryIndex++
            $cmdInput.Text = $script:CmdHistory[$script:CmdHistoryIndex]
            $cmdInput.SelectionStart = $cmdInput.Text.Length
        } else {
            $script:CmdHistoryIndex = $script:CmdHistory.Count
            $cmdInput.Text = ""
        }
    }
})

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::FromArgb(20,20,24)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(140,230,140)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$logPanel.Controls.Add($logBox)
$logBox.BringToFront()

$form.Add_Shown({ $split.SplitterDistance = [int]($form.Height * 0.62) })

# ============================================================
#  TAB 1: REPAIR
# ============================================================
$tabRepair = New-Tab $tabs "Repair"

New-ToolButton $tabRepair "SFC Scan (sfc /scannow)" {
    Start-ToolJob "SFC Scan" { & sfc.exe /scannow 2>&1 | Out-String -Stream }
} -Tooltip "Checks and repairs corrupted Windows system files. Safe to run; can take 10-20 minutes."
New-ToolButton $tabRepair "DISM Restore Health" {
    Start-ToolJob "DISM Restore Health" { & DISM.exe /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String -Stream }
} -Tooltip "Repairs the underlying Windows system image. Run this if SFC reports errors it can't fix."
New-ToolButton $tabRepair "CHKDSK" {
    $drive = Get-TextInput "Drive letter to check (e.g. C: or D:):" "CHKDSK" "C:"
    if ($drive) {
        if ($drive -notmatch ':$') { $drive = "$drive`:" }
        $isSystemDrive = ($drive.TrimEnd(':') -ieq $env:SystemDrive.TrimEnd(':'))
        if ($isSystemDrive) {
            if (Confirm-Action "$drive is the system drive - Windows can't check it while it's in use, so this schedules a check at next restart. Continue?") {
                Start-ToolJob "CHKDSK $drive (scheduled at restart)" { param($d) "Y" | & chkdsk.exe $d /f /r 2>&1 | Out-String -Stream } -ArgumentList $drive
            }
        } else {
            if (Confirm-Action "$drive is not the system drive, so this can run immediately (no restart needed) - it will briefly dismount the drive, so close any open files on it first. Continue?") {
                Start-ToolJob "CHKDSK $drive (immediate)" { param($d) & chkdsk.exe $d /f /r /x 2>&1 | Out-String -Stream } -ArgumentList $drive
            }
        }
    }
} -Tooltip "Checks/repairs a drive. The system drive requires a restart; other drives run immediately."
New-ToolButton $tabRepair "Open DiskPart" {
    if (Confirm-Action "This will open the DiskPart utility in a new window. Be extremely careful, as modifying partitions can cause data loss. Continue?") {
        Invoke-Launch "DiskPart" "diskpart.exe"
    }
} -Tooltip "Opens the disk partitioning tool. Advanced - incorrect commands can cause data loss."
# ============================================================
#  TAB 2: NETWORK
# ============================================================
$tabNet = New-Tab $tabs "Network"

New-ToolButton $tabNet "Scan Local Network Devices (Advanced)" {
    $subnetInput = Get-TextInput "Subnet to scan (first 3 octets, e.g. 192.168.1). Leave blank to auto-detect:" "Advanced Network Scan" ""
    Start-ToolJob "Advanced Network Scan" {
        param($subnetOverride, $logsDir)

        function Get-MacVendor {
            # Small embedded OUI table covering common home/office/IoT vendors -
            # works fully offline, no external API dependency.
            param($mac)
            $oui = ($mac -replace '[:-]','').ToUpper()
            if ($oui.Length -lt 6) { return "Unknown" }
            $oui = $oui.Substring(0,6)
            $vendors = @{
                "B827EB"="Raspberry Pi Fdn"; "DCA632"="Raspberry Pi Fdn"; "E45F01"="Raspberry Pi Fdn"
                "F0272D"="Apple"; "AC87A3"="Apple"; "F0DBF8"="Apple"; "3C0754"="Apple"; "88664A"="Apple"; "A4C361"="Apple"; "D8BB2C"="Apple"; "001EC2"="Apple"
                "B03495"="Sonos"; "5CAAFD"="Sonos"; "000E58"="Sonos"
                "FCEC9C"="TP-Link"; "50C7BF"="TP-Link"; "AC84C6"="TP-Link"; "F4F26D"="TP-Link"
                "A0A8CD"="Netgear"; "204E7F"="Netgear"; "84D6D0"="Netgear"
                "F09FC2"="Ubiquiti"; "DC9FDB"="Ubiquiti"; "245A4C"="Ubiquiti"; "78452E"="Ubiquiti"
                "001C42"="Amazon"; "68372C"="Amazon"; "F0272D2"="Amazon"
                "0050F2"="Microsoft"; "0003FF"="Microsoft"; "7C1E52"="Microsoft"; "60455C"="Microsoft"
                "F8DB88"="Samsung"; "C0BDD1"="Samsung"; "88329E"="Samsung"; "0C71C2"="Samsung"
                "3417EB"="Intel"; "A434D9"="Intel"; "001517"="Intel"; "0026C6"="Intel"
                "B4B676"="Huawei"; "005A13"="Huawei"; "247F3C"="Huawei"
                "3C7C3F"="Xiaomi"; "F8A45F"="Xiaomi"; "AC61EA"="Xiaomi"
                "70B3D5"="Espressif (IoT)"; "24A160"="Espressif (IoT)"; "3C71BF"="Espressif (IoT)"; "A020A6"="Espressif (IoT)"
                "005056"="VMware"; "000C29"="VMware"; "001C14"="VMware"
                "0021B9"="Dell"; "B8AC6F"="Dell"; "D067E5"="Dell"; "F8B156"="Dell"
                "3C4A92"="HP"; "9C8E99"="HP"; "A0481C"="HP"
                "0016B9"="Cisco"; "001A2F"="Cisco"; "000142"="Cisco"
                "001132"="Synology"; "90099D"="Synology"
                "24A43C"="QNAP"; "001B2F"="QNAP"
            }
            if ($vendors.ContainsKey($oui)) { return $vendors[$oui] }
            return "Unknown"
        }

        function Test-CommonPorts {
            # Fast, bounded check of a handful of ports that reveal what a device is
            param($ip)
            $ports = [ordered]@{80="HTTP";443="HTTPS";22="SSH";3389="RDP";445="SMB";9100="Printer"}
            $open = @()
            foreach ($port in $ports.Keys) {
                try {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    $iar = $tcp.BeginConnect($ip, $port, $null, $null)
                    if ($iar.AsyncWaitHandle.WaitOne(300) -and $tcp.Connected) { $open += $ports[$port] }
                    $tcp.Close()
                } catch {}
            }
            return ($open -join ", ")
        }

        "=== Advanced Network Scan ==="

        if ($subnetOverride -and $subnetOverride.Trim() -ne "") {
            $subnet = $subnetOverride.Trim().TrimEnd('.')
            "Using manual subnet: $subnet.0/24"
        } else {
            "Detecting active network adapter..."
            $localIP = $null
            try {
                $defaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop | Sort-Object RouteMetric | Select-Object -First 1
                if ($defaultRoute) {
                    $localIP = (Get-NetIPAddress -InterfaceIndex $defaultRoute.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
                } else {
                    $localIP = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                        Where-Object { $_.IPAddress -notmatch "^127\." -and $_.IPAddress -notmatch "^169\.254\." -and $_.InterfaceOperationalStatus -eq "Up" }).IPAddress
                }
            } catch {
                # NetTCPIP module unavailable (older Windows) - fall back to parsing ipconfig,
                # which works on every Windows version.
                "(NetTCPIP cmdlets unavailable - falling back to ipconfig parsing)"
                $ipconfigOut = & ipconfig.exe
                $ipLines = $ipconfigOut | Select-String "IPv4 Address" | ForEach-Object {
                    ($_ -split ':')[-1].Trim()
                }
                $localIP = $ipLines | Where-Object { $_ -notmatch "^169\.254\." } | Select-Object -First 1
            }
            if ($localIP -is [array]) { $localIP = $localIP[0] }
            if (-not $localIP) { "ERROR: Unable to detect a valid active IPv4 network connection. Try entering a subnet manually."; return }
            $subnet = $localIP.Substring(0, $localIP.LastIndexOf('.'))
            "Local IP: $localIP"
        }
        "(Assumes a /24 network - use the manual subnet field for other ranges.)"
        "Actively sweeping $subnet.1 - $subnet.254 (parallel ping)..."
        "----------------------------------------------------------------------------------"

        # Active parallel ping sweep - finds devices even if they weren't already
        # in the ARP cache, unlike a single broadcast ping.
        $ips = 1..254 | ForEach-Object { "$subnet.$_" }
        $pings = @{}
        foreach ($ip in $ips) {
            $p = New-Object System.Net.NetworkInformation.Ping
            $pings[$ip] = @{ Task = $p.SendPingAsync($ip, 400) }
        }
        [Threading.Tasks.Task[]]$tasks = $pings.Values | ForEach-Object { $_.Task }
        [System.Threading.Tasks.Task]::WaitAll($tasks, 6000) | Out-Null

        $aliveIPs = $pings.Keys | Where-Object {
            try { $pings[$_].Task.IsCompleted -and $pings[$_].Task.Result.Status -eq 'Success' } catch { $false }
        }

        if (-not $aliveIPs -or $aliveIPs.Count -eq 0) {
            "No responding devices found on $subnet.0/24."
            return
        }
        "Found $($aliveIPs.Count) responding device(s). Resolving hostnames, MAC vendors, and open ports..."
        "(This part is sequential per device, so it may take a bit longer on busy networks.)"

        Start-Sleep -Milliseconds 300  # let the ARP cache settle after the sweep
        $arpOutput = & arp.exe -a 2>&1
        $arpMap = @{}
        foreach ($line in $arpOutput) {
            if ($line -match "^\s*($([regex]::Escape($subnet))\.\d+)\s+([0-9a-fA-F-]+)\s+(\w+)") {
                $arpMap[$matches[1]] = @{ MAC = $matches[2]; Type = $matches[3] }
            }
        }

        $deviceList = New-Object System.Collections.Generic.List[PSObject]
        foreach ($ip in $aliveIPs) {
            $mac = "N/A"
            if ($arpMap.ContainsKey($ip)) { $mac = $arpMap[$ip].MAC.ToUpper() }

            $hostname = "Unknown"
            try {
                $iar = [System.Net.Dns]::BeginGetHostEntry($ip, $null, $null)
                if ($iar.AsyncWaitHandle.WaitOne(500)) {
                    $he = [System.Net.Dns]::EndGetHostEntry($iar)
                    if ($he.HostName) { $hostname = $he.HostName }
                }
            } catch {}

            $latency = "N/A"
            try { if ($pings[$ip].Task.Result.Status -eq 'Success') { $latency = "$($pings[$ip].Task.Result.RoundtripTime) ms" } } catch {}

            $vendor = if ($mac -ne "N/A") { Get-MacVendor $mac } else { "Unknown" }
            $openPorts = Test-CommonPorts -ip $ip

            $guess = "Unknown"
            if ($openPorts -match "Printer") { $guess = "Printer" }
            elseif ($openPorts -match "RDP") { $guess = "Windows PC" }
            elseif ($hostname -match "(?i)nas|synology|qnap") { $guess = "NAS" }
            elseif ($hostname -match "(?i)router|gateway|^ap\b") { $guess = "Router/AP" }
            elseif ($vendor -eq "Espressif (IoT)") { $guess = "IoT Device" }
            elseif ($openPorts -match "SSH" -and $vendor -notmatch "Apple|Microsoft") { $guess = "Linux/Network Device" }
            elseif ($vendor -eq "Apple") { $guess = "Apple Device" }

            $deviceList.Add([PSCustomObject]@{
                "IP Address"  = $ip
                "Hostname"    = $hostname
                "MAC Address" = $mac
                "Vendor"      = $vendor
                "Latency"     = $latency
                "Open Ports"  = $openPorts
                "Guess"       = $guess
            })
        }

        $sorted = $deviceList | Sort-Object { [version]$_."IP Address" }
        "`r`nFound $($sorted.Count) device(s) on $subnet.0/24:`r`n"
        $sorted | Format-Table -AutoSize | Out-String -Width 220 -Stream

        # Compare against the last saved scan to flag new/unrecognized devices
        $cacheDir = "$env:LOCALAPPDATA\ITToolkit"
        if (-not (Test-Path $cacheDir)) { New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null }
        $cacheFile = Join-Path $cacheDir "last_network_scan.json"
        $previousMacs = @()
        if (Test-Path $cacheFile) {
            try {
                $prev = Get-Content $cacheFile -Raw | ConvertFrom-Json
                $previousMacs = @($prev | ForEach-Object { $_."MAC Address" })
            } catch {}
        }
        $newDevices = $sorted | Where-Object { $_."MAC Address" -ne "N/A" -and $previousMacs -notcontains $_."MAC Address" }

        if ($previousMacs.Count -gt 0 -and $newDevices) {
            "`r`n*** $($newDevices.Count) NEW device(s) since the last scan: ***"
            $newDevices | ForEach-Object { "  - $($_.'IP Address')  $($_.'MAC Address')  $($_.Hostname)  ($($_.Vendor))" }
        } elseif ($previousMacs.Count -gt 0) {
            "`r`nNo new devices since the last scan."
        } else {
            "`r`n(First scan - future scans will flag any new devices that appear.)"
        }

        $sorted | ConvertTo-Json | Out-File -FilePath $cacheFile -Encoding UTF8
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $reportPath = Join-Path $logsDir "NetworkScan_$(Get-Date -Format 'yyyy-MM-dd_HHmm').csv"
        $sorted | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
        "`r`nReport saved to: $reportPath"
    } -ArgumentList $subnetInput, $script:LogsDir
} -Tooltip "Actively scans the local subnet: IP, MAC, vendor, open ports, and a device-type guess."

New-ToolButton $tabNet "Flush DNS Cache" {
    Start-ToolJob "Flush DNS" { ipconfig /flushdns 2>&1 | Out-String -Stream }
} -Tooltip "Clears the local DNS resolver cache. Good first step for sites not resolving or showing stale IPs."
New-ToolButton $tabNet "Release / Renew IP" {
    Start-ToolJob "Release/Renew IP" {
        ipconfig /release 2>&1 | Out-String -Stream
        ipconfig /renew 2>&1 | Out-String -Stream
    }
} -Tooltip "Drops and reacquires the DHCP IP lease. Useful when a machine has no/wrong IP or lost network access."
New-ToolButton $tabNet "Reset Winsock Catalog" {
    Start-ToolJob "Winsock Reset" { netsh winsock reset 2>&1 | Out-String -Stream }
} -Tooltip "Resets the Windows network socket stack. Fixes some 'no internet despite connected' issues. Restart required."
New-ToolButton $tabNet "Reset TCP/IP Stack" {
    Start-ToolJob "TCP/IP Reset" { netsh int ip reset 2>&1 | Out-String -Stream }
} -Tooltip "Resets the TCP/IP stack to defaults. Use after Winsock reset if network issues persist. Restart required."
New-ToolButton $tabNet "Show IP Configuration" {
    Start-ToolJob "ipconfig /all" { ipconfig /all 2>&1 | Out-String -Stream }
} -Tooltip "Runs ipconfig /all - full adapter, IP, gateway, and DNS details."
New-ToolButton $tabNet "Ping Test" {
    $target = Get-TextInput "Host or IP to ping:" "Ping Test" "8.8.8.8"
    if ($target) { Start-ToolJob "Ping $target" { param($t) ping $t -n 4 2>&1 | Out-String -Stream } -ArgumentList $target }
} -Tooltip "Sends 4 pings to a host you specify to check basic connectivity and latency."
New-ToolButton $tabNet "Continuous Ping (-t)" {
    $target = Get-TextInput "Host or IP to continuously ping:`r`n(Use the 'Stop Task' button above to stop it)" "Continuous Ping" "8.8.8.8"
    if ($target) { Start-ToolJob "Continuous Ping: $target (use Stop Task to end)" { param($t) ping $t -t 2>&1 | Out-String -Stream } -ArgumentList $target }
} -Tooltip "Pings continuously until stopped. Use the Stop Task button above to end it."
New-ToolButton $tabNet "Ping Multiple Hosts" {
    $hostsInput = Get-TextInput "Enter hosts separated by commas:" "Ping Multiple Hosts" "8.8.8.8, 1.1.1.1, google.com"
    if ($hostsInput) {
        $hostList = $hostsInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        if ($hostList.Count -gt 0) {
            Start-ToolJob "Ping Multiple Hosts" {
                param($hosts)
                foreach ($h in $hosts) {
                    "--- Pinging $h ---"
                    ping $h -n 4 2>&1 | Out-String -Stream
                }
            } -ArgumentList (,$hostList)
        }
    }
} -Tooltip "Pings several hosts one after another - handy for checking multiple servers/sites at once."
New-ToolButton $tabNet "Wake-on-LAN" {
    $cacheFile = "$env:LOCALAPPDATA\ITToolkit\last_network_scan.json"
    $devices = @()
    if (Test-Path -LiteralPath $cacheFile) {
        try {
            $devices = @(Get-Content $cacheFile -Raw | ConvertFrom-Json | Where-Object { $_."MAC Address" -and $_."MAC Address" -ne "N/A" })
        } catch { $devices = @() }
    }

    $mac = $null
    if ($devices.Count -gt 0) {
        $pick = Show-DevicePicker -Devices $devices
        if ($pick -eq "MANUAL") {
            $mac = Get-TextInput "Enter MAC address (e.g. AA:BB:CC:DD:EE:FF):" "Wake-on-LAN"
        } elseif ($pick) {
            $mac = $pick
        } else {
            return  # user cancelled
        }
    } else {
        Write-Log "No saved network scan found - run 'Scan Local Network Devices (Advanced)' first to pick from a list, or enter a MAC manually now."
        $mac = Get-TextInput "Enter MAC address (e.g. AA:BB:CC:DD:EE:FF):" "Wake-on-LAN"
    }

    if ($mac) {
        try {
            Send-WakeOnLan -Mac $mac
            Write-Log "Wake-on-LAN magic packet sent to $mac"
        } catch {
            Write-Log "ERROR sending Wake-on-LAN packet: $($_.Exception.Message)"
        }
    }
} -Tooltip "Sends a Wake-on-LAN magic packet to power on a sleeping/off PC. Pick from your last network scan or enter a MAC manually. Target device must have WoL enabled in BIOS/OS."
New-ToolButton $tabNet "Detect DHCP Servers (Rogue Check)" {
    Start-ToolJob "DHCP Server Detection" {
        "=== DHCP Server Detection ==="
        "Broadcasting a DHCPDISCOVER and listening ~4s for offers..."
        "(Normally there should be exactly ONE DHCP server on your subnet - more than one usually means a rogue/unauthorized DHCP server.)"

        $socket = $null
        try {
            $socket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork, [System.Net.Sockets.SocketType]::Dgram, [System.Net.Sockets.ProtocolType]::Udp)
            $socket.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::Broadcast, $true)
            $socket.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress, $true)
            $socket.Bind((New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 68)))

            # Build a minimal DHCPDISCOVER packet (BOOTP/DHCP format)
            [byte[]]$packet = New-Object byte[] 240
            $packet[0] = 1; $packet[1] = 1; $packet[2] = 6; $packet[3] = 0   # op, htype, hlen, hops
            $rnd = New-Object System.Random
            $xid = New-Object byte[] 4
            $rnd.NextBytes($xid)
            [Array]::Copy($xid, 0, $packet, 4, 4)
            $packet[10] = 0x80; $packet[11] = 0x00                          # flags: broadcast
            $fakeMac = [byte[]](0x02,0x1A,0x2B,0x3C,0x4D,0x5E)              # locally-administered placeholder MAC (discover-only, no lease used)
            [Array]::Copy($fakeMac, 0, $packet, 28, 6)
            $packet[236]=99; $packet[237]=130; $packet[238]=83; $packet[239]=99  # magic cookie
            $options = [byte[]](53,1,1, 255)                                # option 53=DHCP Message Type, 1=Discover; End
            $fullPacket = $packet + $options

            $destEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Broadcast, 67)
            $socket.SendTo($fullPacket, $destEP) | Out-Null

            $foundServers = New-Object System.Collections.Generic.HashSet[string]
            $deadline = (Get-Date).AddSeconds(4)
            $buffer = New-Object byte[] 1024
            $remoteEPRef = [ref]([System.Net.EndPoint](New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)))

            while ((Get-Date) -lt $deadline) {
                $msLeft = [Math]::Max(200, [int](($deadline - (Get-Date)).TotalMilliseconds))
                $socket.ReceiveTimeout = $msLeft
                try {
                    $len = $socket.ReceiveFrom($buffer, $remoteEPRef)
                    $srcIP = ([System.Net.IPEndPoint]$remoteEPRef.Value).Address.ToString()
                    $serverIP = $srcIP
                    if ($len -gt 240) {
                        $i = 240
                        while ($i -lt $len -and $buffer[$i] -ne 255) {
                            $opt = $buffer[$i]
                            if ($opt -eq 0) { $i++; continue }
                            $optLen = $buffer[$i+1]
                            if ($opt -eq 54 -and $optLen -eq 4) {
                                $serverIP = "$($buffer[$i+2]).$($buffer[$i+3]).$($buffer[$i+4]).$($buffer[$i+5])"
                            }
                            $i += 2 + $optLen
                        }
                    }
                    if ($foundServers.Add($serverIP)) { "DHCP offer received from: $serverIP" }
                } catch [System.Net.Sockets.SocketException] {
                    break
                }
            }

            "`r`n--- Result ---"
            if ($foundServers.Count -eq 0) {
                "No DHCP offers received. Either no DHCP server is present, broadcasts are being blocked, or the OS DHCP Client service intercepted the replies."
            } elseif ($foundServers.Count -eq 1) {
                "OK: exactly 1 DHCP server detected ($($foundServers | Select-Object -First 1)) - looks normal."
            } else {
                "WARNING: $($foundServers.Count) DIFFERENT DHCP servers responded: $($foundServers -join ', ')"
                "This can indicate a ROGUE/unauthorized DHCP server on this network segment - worth investigating."
            }
        } catch {
            "ERROR: $($_.Exception.Message)"
            "(Binding to UDP port 68 can fail if another process already holds it. This is a best-effort check, not a guarantee.)"
        } finally {
            if ($socket) { $socket.Close() }
        }
    }
} -Tooltip "Broadcasts a DHCP discovery and lists every server that responds. More than one responder can mean a rogue/unauthorized DHCP server on the network."
New-ToolButton $tabNet "Internet Speed Test" {
    Start-ToolJob "Internet Speed Test" {
        "=== Internet Speed Test ==="

        "`r`n--- Latency ---"
        foreach ($target in @("1.1.1.1","8.8.8.8")) {
            try {
                $p = New-Object System.Net.NetworkInformation.Ping
                $r = $p.Send($target, 1000)
                if ($r.Status -eq 'Success') { "$target : $($r.RoundtripTime) ms" }
                else { "$target : no reply" }
            } catch { "$target : error - $($_.Exception.Message)" }
        }

        "`r`n--- Download Speed ---"
        "(Using 3 parallel connections to a public test file - may take up to ~30-60s on slower connections)"
        try {
            Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            $testUrl = "https://proof.ovh.net/files/100Mb.dat"
            $connections = 3
            $httpClient = New-Object System.Net.Http.HttpClient
            $httpClient.Timeout = [TimeSpan]::FromSeconds(60)

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            [Threading.Tasks.Task[]]$tasks = 1..$connections | ForEach-Object { $httpClient.GetByteArrayAsync($testUrl) }
            [System.Threading.Tasks.Task]::WaitAll($tasks)
            $sw.Stop()

            $totalBytes = ($tasks | ForEach-Object { $_.Result.Length } | Measure-Object -Sum).Sum
            $seconds = $sw.Elapsed.TotalSeconds
            $mbps = [math]::Round((($totalBytes * 8) / 1000000) / $seconds, 2)
            $mbTotal = [math]::Round($totalBytes / 1MB, 1)

            "Downloaded $mbTotal MB across $connections parallel connections in $([math]::Round($seconds,1))s"
            "Estimated download speed: $mbps Mbps"
        } catch {
            "ERROR running download test: $($_.Exception.Message)"
            "(Test server may be temporarily unreachable - try again, or use the Speedtest CLI in the Hardware Diagnostics tab if you have it in PortableTools.)"
        }

        "`r`nNote: this is an approximate single-server test, not upload speed. For a more authoritative/official result, use the Speedtest CLI (Ookla) button in Hardware Diagnostics."
    }
} -Tooltip "Quick built-in internet speed test (latency + download) - no extra software needed. Runs entirely with PowerShell."
New-ToolButton $tabNet "Trace Route" {
    $target = Get-TextInput "Host or IP to trace:" "Trace Route" "google.com"
    if ($target) { Start-ToolJob "Tracert $target" { param($t) tracert $t 2>&1 | Out-String -Stream } -ArgumentList $target }
} -Tooltip "Shows the network path (hop by hop) to a host - useful for spotting where a connection is failing or slow."
New-ToolButton $tabNet "Show Active Connections" {
    Start-ToolJob "Netstat" { netstat -ano 2>&1 | Out-String -Stream }
} -Tooltip "Runs netstat -ano - lists active network connections and the process ID using each one."
New-ToolButton $tabNet "Show ARP Cache" {
    Start-ToolJob "ARP Cache" { arp -a 2>&1 | Out-String -Stream }
} -Tooltip "Lists the local ARP table (IP-to-MAC mappings) for devices this PC has recently talked to."
New-ToolButton $tabNet "Clear ARP Cache" {
    Start-ToolJob "Clear ARP Cache" { netsh interface ip delete arpcache 2>&1 | Out-String -Stream }
} -Tooltip "Clears cached IP-to-MAC mappings. Useful after swapping network hardware."
New-ToolButton $tabNet "FULL Network Reset (combo)" {
    if (Confirm-Action "Runs flush DNS + Winsock reset + TCP/IP reset + IP renew. A restart is recommended after. Continue?") {
        Start-ToolJob "Full Network Reset" {
            "--- Flush DNS ---"; ipconfig /flushdns 2>&1 | Out-String -Stream
            "--- Winsock Reset ---"; netsh winsock reset 2>&1 | Out-String -Stream
            "--- TCP/IP Reset ---"; netsh int ip reset 2>&1 | Out-String -Stream
            "--- Release ---"; ipconfig /release 2>&1 | Out-String -Stream
            "--- Renew ---"; ipconfig /renew 2>&1 | Out-String -Stream
            "Full reset complete. RESTART THE COMPUTER to fully apply."
        }
    }
} -Tooltip "Flushes DNS, resets Winsock/TCP-IP, and renews the IP. Fixes most 'no internet' issues."

# ============================================================
#  TAB 3: SYSTEM INFO
# ============================================================
$tabInfo = New-Tab $tabs "System Info"

New-ToolButton $tabInfo "*** Quick Health Check ***" {
    Start-ToolJob "Quick Health Check" {
        "############################################################"
        "  QUICK HEALTH CHECK"
        "############################################################"

        "`r`n=== 1/7: OS & Uptime ==="
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $uptime = (Get-Date) - $os.LastBootUpTime
            "OS: $($os.Caption) (Build $($os.BuildNumber))"
            "Last boot: $($os.LastBootUpTime)  |  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
        } catch { "Could not read OS info: $($_.Exception.Message)" }

        "`r`n=== 2/7: Disk Space ==="
        try {
            Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
                $freeGB = [math]::Round($_.FreeSpace / 1GB, 1)
                $totalGB = [math]::Round($_.Size / 1GB, 1)
                $pctFree = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 0) } else { 0 }
                $flag = if ($pctFree -lt 10) { "  <-- LOW SPACE" } else { "" }
                "$($_.DeviceID)  $freeGB GB free of $totalGB GB ($pctFree% free)$flag"
            }
        } catch { "Could not read disk info: $($_.Exception.Message)" }

        "`r`n=== 3/7: Memory ==="
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
            $usedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 0)
            "RAM: $freeGB GB free of $totalGB GB total ($usedPct% in use)"
        } catch { "Could not read memory info: $($_.Exception.Message)" }

        "`r`n=== 4/7: CPU Load ==="
        try {
            $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
            "CPU: $($cpu.Name.Trim())"
            "Current load: $($cpu.LoadPercentage)%"
        } catch { "Could not read CPU info: $($_.Exception.Message)" }

        "`r`n=== 5/7: Network Connectivity ==="
        try {
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction Stop
            $avgMs = [math]::Round(($ping | Measure-Object -Property ResponseTime -Average).Average, 0)
            "Internet reachable - avg latency $avgMs ms"
        } catch { "WARNING: Could not reach the internet (8.8.8.8). Check network connection." }

        "`r`n=== 6/7: Windows Update Status ==="
        try {
            $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
            if ($lastUpdate) { "Most recent update: $($lastUpdate.HotFixID) installed $($lastUpdate.InstalledOn)" }
            else { "No update history found via Get-HotFix." }
        } catch { "Could not read update history: $($_.Exception.Message)" }

        "`r`n=== 7/7: Recent System Errors (last 24h) ==="
        try {
            $since = (Get-Date).AddHours(-24)
            $errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=$since} -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($errors) {
                "Found $($errors.Count) error(s) in System log (last 24h):"
                $errors | ForEach-Object {
                    $msg = ($_.Message -replace "`r?`n", " ").Trim()
                    if ($msg.Length -gt 120) { $msg = $msg.Substring(0, 120) + "..." }
                    "  [$($_.TimeCreated)] $($_.ProviderName): $msg"
                }
            } else {
                "No System log errors in the last 24 hours."
            }
        } catch { "Could not read Event Log: $($_.Exception.Message)" }

        "`r`n############################################################"
        "  HEALTH CHECK COMPLETE"
        "############################################################"
    }
} -Tooltip "Runs a fast read-only checkup: OS/uptime, disk space, memory, CPU, internet, updates, and recent errors - all in one report."

New-ToolButton $tabInfo "System Information" {
    Start-ToolJob "System Info" { systeminfo 2>&1 | Out-String -Stream }
} -Tooltip "Runs systeminfo - OS version, install date, hotfixes, memory, and hardware summary."
New-ToolButton $tabInfo "List Installed Updates" {
    Start-ToolJob "Installed Updates" { Get-HotFix | Sort-Object InstalledOn -Descending | Format-Table -AutoSize | Out-String -Width 200 -Stream }
} -Tooltip "Lists installed Windows updates (hotfixes), most recent first."
New-ToolButton $tabInfo "Disk Cleanup" {
    Invoke-Launch "Disk Cleanup" "cleanmgr.exe"
} -Tooltip "Opens the built-in Windows Disk Cleanup utility."
New-ToolButton $tabInfo "List Running Services" {
    Start-ToolJob "Running Services" { Get-Service | Where-Object Status -eq 'Running' | Sort-Object DisplayName | Format-Table -AutoSize | Out-String -Width 200 -Stream }
} -Tooltip "Lists all currently running Windows services."
New-ToolButton $tabInfo "List Startup Programs" {
    Start-ToolJob "Startup Programs" { Get-CimInstance Win32_StartupCommand | Format-Table Name,Command,Location -AutoSize | Out-String -Width 200 -Stream }
} -Tooltip "Lists programs configured to launch automatically at startup."
New-ToolButton $tabInfo "Restart Explorer.exe" {
    if (Confirm-Action "This will restart the Windows shell (Explorer). Continue?") {
        Start-ToolJob "Restart Explorer" {
            # Deliberately NOT using Start-Process to relaunch explorer.exe here -
            # since this toolkit runs elevated, manually starting explorer.exe
            # would make the whole shell run as Administrator, which breaks
            # drag-and-drop from non-elevated apps and bypasses UAC prompts for
            # anything opened from it. Just kill it - Windows (Winlogon) detects
            # the shell died and restarts it automatically under the correct
            # normal user token.
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            "Explorer stopped. Windows will automatically restart it under your normal user account in a few seconds."
        }
    }
} -Tooltip "Restarts the Windows shell (taskbar/desktop/file explorer). Fixes a frozen or glitchy taskbar."
New-ToolButton $tabInfo "Generate Battery Report" {
    Start-ToolJob "Battery Report" {
        param($logsDir)
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $path = Join-Path $logsDir "battery-report.html"
        powercfg /batteryreport /output $path 2>&1 | Out-String -Stream
        "Saved to $path"
    } -ArgumentList $script:LogsDir
} -Tooltip "Generates a laptop battery health report (capacity, wear, usage history) and saves it to the IT Toolkit Logs folder."
New-ToolButton $tabInfo "Open Event Viewer" {
    Invoke-Launch "Event Viewer" "eventvwr.msc"
} -Tooltip "Opens the Windows Event Viewer for browsing system/application error logs."
New-ToolButton $tabInfo "Open Computer Management" {
    Invoke-Launch "Computer Management" "compmgmt.msc"
} -Tooltip "Opens Computer Management - disk management, device manager, local users/groups, services, and event viewer all in one console."
New-ToolButton $tabInfo "Open System Configuration (msconfig)" {
    Invoke-Launch "System Configuration" "msconfig.exe"
} -Tooltip "Opens msconfig - manage startup items, boot options, and services. Useful for diagnosing slow-boot issues."
New-ToolButton $tabInfo "Open Control Panel" {
    Invoke-Launch "Control Panel" "control.exe"
} -Tooltip "Opens the classic Windows Control Panel."
New-ToolButton $tabInfo "Open Command Prompt (Admin)" {
    Invoke-Launch "Command Prompt (Admin)" "cmd.exe"
} -Tooltip "Opens an elevated Command Prompt. Already admin, since the toolkit itself runs elevated - no separate 'Run as administrator' prompt needed."
New-ToolButton $tabInfo "Export Full System Report" {
    Start-ToolJob "System Report Export" {
        param($logsDir)
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $path = Join-Path $logsDir "system-report.txt"
        & msinfo32.exe /report $path
        Start-Sleep -Seconds 2
        "Report saved to $path"
    } -ArgumentList $script:LogsDir
} -Tooltip "Runs msinfo32 to export a complete system report as a text file to the IT Toolkit Logs folder."

# ============================================================
#  TAB 4: ADVANCED
# ============================================================
$tabAdv = New-Tab $tabs "Advanced"

New-ToolButton $tabAdv "Create System Restore Point" {
    Start-ToolJob "System Restore Point" {
        try {
            Checkpoint-Computer -Description "IT Toolkit Restore Point" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            "Restore point created."
        } catch { "Could not create restore point: $($_.Exception.Message)" }
    }
} -Tooltip "Creates a restore point you can roll back to if a later change goes wrong."
New-ToolButton $tabAdv "Reset Windows Update Components" {
    if (Confirm-Action "This stops Windows Update services and renames the SoftwareDistribution/catroot2 folders. Continue?") {
        Start-ToolJob "Windows Update Reset" {
            net stop wuauserv 2>&1 | Out-String -Stream
            net stop cryptSvc 2>&1 | Out-String -Stream
            net stop bits 2>&1 | Out-String -Stream
            net stop msiserver 2>&1 | Out-String -Stream
            Rename-Item "$env:windir\SoftwareDistribution" "SoftwareDistribution.bak" -ErrorAction SilentlyContinue
            Rename-Item "$env:windir\System32\catroot2" "catroot2.bak" -ErrorAction SilentlyContinue
            net start wuauserv 2>&1 | Out-String -Stream
            net start cryptSvc 2>&1 | Out-String -Stream
            net start bits 2>&1 | Out-String -Stream
            net start msiserver 2>&1 | Out-String -Stream
            "Windows Update components reset."
        }
    }
} -Tooltip "Stops Windows Update, renames its cache folders, and restarts it. Fixes stuck updates."
New-ToolButton $tabAdv "Group Policy Update + Report" {
    Start-ToolJob "Group Policy Update" {
        param($logsDir)
        # Some Group Policy client-side extensions make gpupdate ask "Do you
        # want to log off now? (Y/N)" - since this runs in a non-interactive
        # background job with no console attached, that prompt can never be
        # answered and would hang forever until Stop Task is clicked. Piping
        # "N" in answers it automatically (declines the logoff/restart).
        cmd.exe /c "echo N | gpupdate /force" 2>&1 | Out-String -Stream
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $path = Join-Path $logsDir "gpresult-report.html"
        gpresult /h $path /f 2>&1 | Out-String -Stream
        "GP report saved to $path"
    } -ArgumentList $script:LogsDir
} -Tooltip "Reapplies Group Policy settings and saves an HTML report of applied policies to the IT Toolkit Logs folder."
New-ToolButton $tabAdv "Reset Windows Store Apps" {
    Invoke-Launch "Windows Store Reset" "wsreset.exe"
} -Tooltip "Resets the Microsoft Store cache. Fixes Store apps that won't open or update."
New-ToolButton $tabAdv "Repair/Install WebView2 Runtime" {
    if (Confirm-Action "This closes any running WebView2 processes and reinstalls the Microsoft Edge WebView2 Runtime (used by Teams, new Outlook, and many modern apps). Needs internet access. Continue?") {
        Start-ToolJob "WebView2 Repair" {
            Get-Process -Name "msedgewebview2" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            "Closed any running WebView2 processes."
            $installerPath = "$env:TEMP\MicrosoftEdgeWebview2Setup.exe"
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/p/?LinkId=2124703" -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                "Downloaded the official WebView2 Evergreen Bootstrapper from Microsoft."
                $proc = Start-Process -FilePath $installerPath -ArgumentList "/silent","/install" -Wait -PassThru
                "Installer exited with code $($proc.ExitCode)."
                if ($proc.ExitCode -eq 0) { "WebView2 Runtime installed/repaired successfully." }
                else { "Installer returned a non-zero exit code - may need a closer look." }
            } catch {
                "ERROR: $($_.Exception.Message)"
            } finally {
                Remove-Item -Path $installerPath -ErrorAction SilentlyContinue
            }
        }
    }
} -Tooltip "Closes WebView2 processes and reinstalls the Edge WebView2 Runtime - fixes many Teams/Outlook/modern-app launch failures. Downloads the official Microsoft installer; needs internet."
New-ToolButton $tabAdv "Enable Network Adapter" {
    try {
        (Get-NetAdapter | Format-Table Name,Status,InterfaceDescription -AutoSize | Out-String -Stream) | ForEach-Object { Write-Log $_ }
    } catch {
        Write-Log "(NetAdapter module unavailable - falling back to netsh)"
        (netsh interface show interface | Out-String -Stream) | ForEach-Object { Write-Log $_ }
    }
    $name = Get-TextInput "Exact adapter name to ENABLE:" "Enable Adapter"
    if ($name) { Start-ToolJob "Enable Adapter: $name" { param($n) netsh interface set interface name="$n" admin=enable 2>&1 | Out-String -Stream } -ArgumentList $name }
} -Tooltip "Lists adapters, then enables the one you name. Useful for resetting a disabled adapter."
New-ToolButton $tabAdv "Disable Network Adapter" {
    try {
        (Get-NetAdapter | Format-Table Name,Status,InterfaceDescription -AutoSize | Out-String -Stream) | ForEach-Object { Write-Log $_ }
    } catch {
        Write-Log "(NetAdapter module unavailable - falling back to netsh)"
        (netsh interface show interface | Out-String -Stream) | ForEach-Object { Write-Log $_ }
    }
    $name = Get-TextInput "Exact adapter name to DISABLE:" "Disable Adapter"
    if ($name -and (Confirm-Action "Disable adapter '$name'?")) {
        Start-ToolJob "Disable Adapter: $name" { param($n) netsh interface set interface name="$n" admin=disable 2>&1 | Out-String -Stream } -ArgumentList $name
    }
} -Tooltip "Lists adapters, then disables the one you name."
New-ToolButton $tabAdv "Windows Defender Quick Scan" {
    Start-ToolJob "Defender Quick Scan" {
        $mpPath = "$env:ProgramFiles\Windows Defender\MpCmdRun.exe"
        if (-not (Test-Path -LiteralPath $mpPath)) {
            # On many up-to-date machines the active copy lives under ProgramData
            # instead, since Defender platform updates land there.
            $platformDir = "$env:ProgramData\Microsoft\Windows Defender\Platform"
            if (Test-Path -LiteralPath $platformDir) {
                $latest = Get-ChildItem -Path $platformDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
                if ($latest) { $mpPath = Join-Path $latest.FullName "MpCmdRun.exe" }
            }
        }
        if (-not (Test-Path -LiteralPath $mpPath)) {
            "ERROR: Windows Defender (MpCmdRun.exe) not found on this PC. It may be disabled or replaced by third-party antivirus."
            return
        }
        & $mpPath -Scan -ScanType 1 2>&1 | Out-String -Stream
    }
} -Tooltip "Runs a quick malware scan using built-in Windows Defender."
New-ToolButton $tabAdv "Restart Print Spooler" {
    Start-ToolJob "Restart Print Spooler" {
        Restart-Service spooler -Force -ErrorAction Stop
        "Print Spooler restarted."
    }
} -Tooltip "Restarts the Print Spooler service. The classic fix for a stuck print queue."
New-ToolButton $tabAdv "Check Activation Status" {
    Start-ToolJob "Activation Status" {
        cscript //nologo "$env:windir\system32\slmgr.vbs" /xpr 2>&1 | Out-String -Stream
        cscript //nologo "$env:windir\system32\slmgr.vbs" /dli 2>&1 | Out-String -Stream
    }
} -Tooltip "Shows whether Windows is activated and current license details."
New-ToolButton $tabAdv "List All Installed Drivers" {
    Start-ToolJob "Driver List" {
        param($logsDir)
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $path = Join-Path $logsDir "driver-list.txt"
        driverquery /v /fo table 2>&1 | Out-File $path
        Get-Content $path | Out-String -Width 200 -Stream
        "Saved to $path"
    } -ArgumentList $script:LogsDir
} -Tooltip "Lists all installed device drivers and saves the list to the IT Toolkit Logs folder."
New-ToolButton $tabAdv "List Local User Accounts" {
    Start-ToolJob "Local Users" { net user 2>&1 | Out-String -Stream }
} -Tooltip "Lists all local user accounts on this PC."
New-ToolButton $tabAdv "Disable Password Expiration (All Local Accounts)" {
    if (Confirm-Action "WARNING: This disables password expiration for EVERY local account on this PC (Local Security Policy - Maximum password age = unlimited). This is a machine-wide account policy change. Continue?") {
        Start-ToolJob "Disable Password Expiration (All Accounts)" {
            try {
                net accounts /maxpwage:unlimited 2>&1 | Out-String -Stream
                "Password expiration disabled for all local accounts on this PC."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Disables password expiration for ALL local accounts on this PC - a machine-wide policy change, not specific to any one user."
New-ToolButton $tabAdv "Add Local User" {
    $info = Show-AddUserDialog
    if ($info) {
        $securePwd = ConvertTo-SecureString -String $info.Password -AsPlainText -Force
        Start-ToolJob "Add User: $($info.Username)" {
            param($n, $securePwd, $isAdmin, $remoteDesktop, $backupOp, $powerUser, $mustChange, $neverExpires)
            try {
                if (Get-Command New-LocalUser -ErrorAction SilentlyContinue) {
                    $params = @{
                        Name                 = $n
                        Password             = $securePwd
                        PasswordNeverExpires = [bool]$neverExpires
                        ErrorAction          = "Stop"
                    }
                    New-LocalUser @params | Out-Null
                    "User '$n' created."

                    if ($isAdmin) {
                        Add-LocalGroupMember -Group "Administrators" -Member $n -ErrorAction Stop
                        "Added '$n' to the Administrators group."
                    } else {
                        "'$n' is a standard user (Users group)."
                    }
                } else {
                    # Older Windows without the LocalAccounts module (pre-Win10/Server2016) -
                    # net user needs the password as a plain argument, unavoidable on these systems.
                    $plainPwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($securePwd))
                    net user $n $plainPwd /add 2>&1 | Out-String -Stream
                    if ($neverExpires) {
                        try {
                            $adsiUser = [ADSI]"WinNT://$env:COMPUTERNAME/$n,user"
                            $adsiUser.UserFlags = $adsiUser.UserFlags.Value -bor 0x10000  # UF_DONT_EXPIRE_PASSWD
                            $adsiUser.SetInfo()
                        } catch {}
                    }
                    if ($isAdmin) {
                        net localgroup Administrators $n /add 2>&1 | Out-String -Stream
                        "Added '$n' to the Administrators group."
                    } else {
                        "'$n' is a standard user."
                    }
                }

                # Additional group memberships (optional, on top of the base Standard/Admin type)
                if ($remoteDesktop) {
                    try {
                        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $n -ErrorAction Stop
                        "Added '$n' to Remote Desktop Users (can now log in via RDP)."
                    } catch {
                        if ($_.Exception.Message -match "was not found") {
                            "NOTE: 'Remote Desktop Users' group not found. This is expected on Windows Home edition (RDP hosting isn't supported there at all), or the group may have a localized name on non-English Windows."
                        } else {
                            "NOTE: could not add '$n' to Remote Desktop Users: $($_.Exception.Message)"
                        }
                    }
                }
                if ($backupOp) {
                    try {
                        Add-LocalGroupMember -Group "Backup Operators" -Member $n -ErrorAction Stop
                        "Added '$n' to Backup Operators."
                    } catch {
                        if ($_.Exception.Message -match "was not found") {
                            "NOTE: 'Backup Operators' group not found on this PC (may have a localized name on non-English Windows)."
                        } else {
                            "NOTE: could not add '$n' to Backup Operators: $($_.Exception.Message)"
                        }
                    }
                }
                if ($powerUser) {
                    try {
                        Add-LocalGroupMember -Group "Power Users" -Member $n -ErrorAction Stop
                        "Added '$n' to Power Users."
                    } catch {
                        if ($_.Exception.Message -match "was not found") {
                            "NOTE: 'Power Users' group not found on this PC (may have a localized name on non-English Windows)."
                        } else {
                            "NOTE: could not add '$n' to Power Users: $($_.Exception.Message)"
                        }
                    }
                }

                if ($mustChange -and -not $neverExpires) {
                    try {
                        $adsiUser = [ADSI]"WinNT://$env:COMPUTERNAME/$n,user"
                        $adsiUser.Put("PasswordExpired", 1)
                        $adsiUser.SetInfo()
                        "'$n' must change their password at next logon."
                    } catch {
                        "NOTE: user created, but could not set 'must change password at next logon': $($_.Exception.Message)"
                    }
                }
            } catch {
                "ERROR creating user '$n': $($_.Exception.Message)"
            }
        } -ArgumentList $info.Username, $securePwd, $info.IsAdmin, $info.RemoteDesktop, $info.BackupOperator, $info.PowerUser, $info.MustChange, $info.NeverExpires
    }
} -Tooltip "Opens a form to create a user with a masked password, admin/standard privilege choice, additional group memberships (Remote Desktop, Backup Operators, Power Users), and account policy options."
New-ToolButton $tabAdv "Disable Local User" {
    $name = Get-TextInput "Username to disable:" "Disable Local User"
    if ($name) { Start-ToolJob "Disable User: $name" { param($n) net user $n /active:no 2>&1 | Out-String -Stream } -ArgumentList $name }
} -Tooltip "Disables a local user account without deleting it (prompts for the username)."
New-ToolButton $tabAdv "Enable Local User" {
    $name = Get-TextInput "Username to enable:" "Enable Local User"
    if ($name) { Start-ToolJob "Enable User: $name" { param($n) net user $n /active:yes 2>&1 | Out-String -Stream } -ArgumentList $name }
} -Tooltip "Re-enables a previously disabled local user account (prompts for the username)."
New-ToolButton $tabAdv "Firewall Status" {
    Start-ToolJob "Firewall Status" { netsh advfirewall show allprofiles state 2>&1 | Out-String -Stream }
} -Tooltip "Shows whether Windows Firewall is on or off for each network profile."
New-ToolButton $tabAdv "Enable Firewall (All Profiles)" {
    Start-ToolJob "Enable Firewall" { netsh advfirewall set allprofiles state on 2>&1 | Out-String -Stream }
} -Tooltip "Turns Windows Firewall back on for all profiles."
New-ToolButton $tabAdv "Disable Firewall (All Profiles)" {
    if (Confirm-Action "WARNING: this turns off the Windows Firewall on ALL profiles, reducing protection. Continue?") {
        Start-ToolJob "Disable Firewall" { netsh advfirewall set allprofiles state off 2>&1 | Out-String -Stream }
    }
} -Tooltip "WARNING: turns off Windows Firewall on ALL profiles, reducing protection."
New-ToolButton $tabAdv "Run Memory Diagnostic" {
    if (Confirm-Action "This tool requires a restart to run the memory test. Continue?") {
        Invoke-Launch "Memory Diagnostic" "mdsched.exe"
    }
} -Tooltip "Tests RAM for errors. Requires a restart to run the test."
New-ToolButton $tabAdv "Backup Registry (HKLM/HKCU)" {
    Start-ToolJob "Registry Backup" {
        param($logsDir)
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $hklm = Join-Path $logsDir "registry-backup-HKLM.reg"
        $hkcu = Join-Path $logsDir "registry-backup-HKCU.reg"
        reg export HKLM $hklm /y 2>&1 | Out-String -Stream
        reg export HKCU $hkcu /y 2>&1 | Out-String -Stream
        "Backed up to: $hklm and $hkcu"
    } -ArgumentList $script:LogsDir
} -Tooltip "Exports HKLM and HKCU to the IT Toolkit Logs folder - good safety net before risky registry changes."
New-ToolButton $tabAdv "Open Hosts File" {
    Invoke-Launch "Hosts File" "notepad.exe" "$env:windir\System32\drivers\etc\hosts"
} -Tooltip "Opens the hosts file for manual editing (e.g. block a domain or redirect a hostname)."
New-ToolButton $tabAdv "Check BitLocker Status" {
    Start-ToolJob "BitLocker Status" { manage-bde -status 2>&1 | Out-String -Stream }
} -Tooltip "Shows BitLocker encryption status for all drives on this PC."
New-ToolButton $tabAdv "List Scheduled Tasks" {
    Start-ToolJob "Scheduled Tasks" { schtasks /query /fo table 2>&1 | Out-String -Stream }
} -Tooltip "Lists all tasks configured in Windows Task Scheduler."
New-ToolButton $tabAdv "Clear Windows Update Cache" {
    if (Confirm-Action "This stops Windows Update and deletes cached download files. Continue?") {
        Start-ToolJob "Clear WU Cache" {
            net stop wuauserv 2>&1 | Out-String -Stream
            Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            net start wuauserv 2>&1 | Out-String -Stream
            "Windows Update cache cleared."
        }
    }
} -Tooltip "WARNING: deletes downloaded update files. Windows will re-download them on next check."

# ============================================================
#  TAB 5: THIRD-PARTY UTILITIES
# ============================================================
$tabUtil = New-Tab $tabs "Utilities"

New-ToolButton $tabUtil "Chris Titus Tech - WinUtil" {
    if (Confirm-Action "This downloads and runs Chris Titus Tech's WinUtil (christitus.com/win) in a new PowerShell window - a well-known open-source tool for Windows debloat/tweaks/app installs. It will open its own GUI window separate from this toolkit. Continue?") {
        Start-Process powershell -ArgumentList '-NoProfile -Command "irm https://christitus.com/win | iex"'
        Write-Log "Launched Chris Titus Tech WinUtil in a new window."
    }
} -Tooltip "Well-known third-party tool for Windows debloat, tweaks, and app installs. Opens its own window."
New-ToolButton $tabUtil "Robocopy (File/Folder Copy)" {
    $info = Show-RobocopyDialog
    if ($info) {
        $proceed = Confirm-Action "About to run:`r`n`r`nSource: $($info.Source)`r`nDestination: $($info.Destination)`r`nMode: $($info.Mode)`r`n`r`nContinue?"
        if ($proceed -and $info.Mode -eq "Mirror") {
            $proceed = Confirm-Action "WARNING: Mirror mode will DELETE any files/folders in `"$($info.Destination)`" that don't exist in the source, to make it an exact copy. This can permanently delete data. Continue?"
        } elseif ($proceed -and $info.Mode -eq "Move") {
            $proceed = Confirm-Action "WARNING: Move mode will DELETE the source files in `"$($info.Source)`" after copying them successfully. Continue?"
        }
        if ($proceed) {
            Start-ToolJob "Robocopy: $($info.Mode) $($info.Source) -> $($info.Destination)" {
                param($src, $dst, $mode, $multiThread, $verbose)
                $roboArgs = @($src, $dst)
                switch ($mode) {
                    "Mirror" { $roboArgs += "/MIR" }
                    "Move"   { $roboArgs += "/E"; $roboArgs += "/MOVE" }
                    default  { $roboArgs += "/E" }
                }
                if ($multiThread) { $roboArgs += "/MT:8" }
                if ($verbose) { $roboArgs += "/V" } else { $roboArgs += "/NP" }
                $roboArgs += "/R:2"; $roboArgs += "/W:2"   # don't hang forever retrying locked files

                "=== Robocopy ($mode): $src -> $dst ==="
                & robocopy.exe @roboArgs 2>&1 | Out-String -Stream

                # Robocopy's exit code is a bitmask, NOT a normal 0=success/nonzero=fail code -
                # anything 0-7 means success (possibly with info like "extra files found"),
                # only 8+ means an actual failure occurred.
                $code = $LASTEXITCODE
                if ($code -ge 8) {
                    "`r`nRobocopy exit code $code : one or more errors occurred - check the output above."
                } else {
                    "`r`nRobocopy exit code $code : completed successfully."
                }
            } -ArgumentList $info.Source, $info.Destination, $info.Mode, $info.MultiThread, $info.Verbose
        }
    }
} -Tooltip "Reliable file/folder copy tool built into Windows. Choose source/destination folders and Copy, Mirror, or Move mode. Handles interrupted copies and locked files better than drag-and-drop."
New-ToolButton $tabUtil "Disable Windows Search Indexing" {
    if (Confirm-Action "This stops and disables the Windows Search service. Start Menu / File Explorer search will still work but be much slower (searches files directly instead of using the index). Can help reduce disk I/O on older/low-resource machines. Continue?") {
        Start-ToolJob "Disable Windows Search Indexing" {
            try {
                Stop-Service -Name WSearch -Force -ErrorAction Stop
                Set-Service -Name WSearch -StartupType Disabled -ErrorAction Stop
                "Windows Search indexing service stopped and disabled."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "Stops and disables the Windows Search indexing service. Reduces background disk I/O, but Explorer/Start Menu search becomes slower."
New-ToolButton $tabUtil "Enable Windows Search Indexing" {
    Start-ToolJob "Enable Windows Search Indexing" {
        try {
            & sc.exe config WSearch start= delayed-auto | Out-String -Stream
            Start-Service -Name WSearch -ErrorAction Stop
            "Windows Search indexing service re-enabled and started (delayed auto-start, matching Windows default)."
        } catch {
            "ERROR: $($_.Exception.Message)"
        }
    }
} -Tooltip "Re-enables the Windows Search indexing service, restoring normal fast Explorer/Start Menu search."
New-ToolButton $tabUtil "Microsoft Activation Scripts (MAS)" {
    if (Confirm-Action "This downloads and runs Microsoft Activation Scripts (MAS) from get.activated.win in a new PowerShell window. It will open its own interactive menu. Continue?") {
        Start-Process powershell -ArgumentList '-NoProfile -Command "irm https://get.activated.win | iex"'
        Write-Log "Launched MAS (get.activated.win) in a new window."
    }
} -Tooltip "Downloads and runs Microsoft Activation Scripts (MAS). Opens its own interactive command window."
# ============================================================
#  HELPER: find an installed third-party tool, or offer download
# ============================================================
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $null }
$PortableToolsDir = if ($ScriptDir) {
    Join-Path $ScriptDir "PortableTools"
} else {
    # No script file on disk (e.g. run via "irm <url> | iex") - fall back to a
    # fixed, predictable location next to the logs folder instead.
    Join-Path ([Environment]::GetFolderPath("Desktop")) "PortableTools"
}

function Find-ToolExe {
    param([string[]]$KnownPaths, [string]$ExeName)
    foreach ($p in $KnownPaths) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ -and (Test-Path $_) }
    foreach ($root in $roots) {
        $match = Get-ChildItem -Path $root -Filter $ExeName -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($match) { return $match.FullName }
    }
    return $null
}

function Find-InPortableTools {
    # Wildcard match by keyword - works regardless of the exact downloaded filename
    # (e.g. "cpu-z_2.15-en.exe" still matches keyword "cpuz")
    param([string]$Keyword)
    if (-not (Test-Path -LiteralPath $PortableToolsDir)) { return $null }
    $all = Get-ChildItem -Path $PortableToolsDir -Filter "*$Keyword*.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue
    if (-not $all) { return $null }
    # Exclude uninstallers, updaters, and other non-primary helper exes
    $preferred = $all | Where-Object { $_.Name -notmatch '(?i)(unins|uninstall|update|updater|patch|helper|report|crashhandler)' }
    if (-not $preferred) { $preferred = $all }
    # Tiebreaker: the main program exe is usually named more simply/shorter
    # than its helper tools (e.g. "HDSentinel.exe" vs "harddisksentinelupdate.exe")
    $best = $preferred | Sort-Object { $_.BaseName.Length } | Select-Object -First 1
    return $best.FullName
}

function Find-InPortableToolsArch {
    # Same keyword match, but prefers a path/filename that indicates the
    # requested bitness (e.g. folder "cpuz_x64" or file "DiskInfo64.exe")
    param([string]$Keyword, [string]$Arch)  # Arch = '64' or '32'
    if (-not (Test-Path -LiteralPath $PortableToolsDir)) { return $null }
    $all = Get-ChildItem -Path $PortableToolsDir -Filter "*$Keyword*.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '(?i)(unins|uninstall|update|updater|patch|helper|report|crashhandler)' }
    if (-not $all) { return $null }
    if ($Arch -eq '64') {
        $candidates = $all | Where-Object { $_.FullName -match '(?i)(x64|_64|\b64\b)' }
    } else {
        $candidates = $all | Where-Object { $_.FullName -match '(?i)(x32|x86|_32|\b32\b)' }
    }
    if (-not $candidates) { return $null }
    $best = $candidates | Sort-Object { $_.BaseName.Length } | Select-Object -First 1
    return $best.FullName
}

function Launch-OrDownload {
    param($Name, [string]$Keyword, [string[]]$KnownPaths, [string]$ExeName, [string]$Url)
    $statusLabel.Text = "Searching for $Name..."
    [System.Windows.Forms.Application]::DoEvents()

    # 1. PortableTools folder (portable exe OR setup installer - matched by keyword)
    $portablePath = Find-InPortableTools -Keyword $Keyword
    if ($portablePath) {
        $statusLabel.Text = "Ready"
        $label = if ($portablePath -match '(?i)setup|install') { "$Name (installer)" } else { $Name }
        Invoke-Launch $label $portablePath
        return
    }

    # 2. Common installed locations
    $installedPath = Find-ToolExe -KnownPaths $KnownPaths -ExeName $ExeName
    $statusLabel.Text = "Ready"
    if ($installedPath) {
        Invoke-Launch $Name $installedPath
        return
    }

    # 3. Not found anywhere - offer official download page
    Write-Log "$Name not found in PortableTools\ or installed on this PC."
    if (Confirm-Action "$Name doesn't appear to be in the PortableTools folder or installed. Open the official download page in your browser?") {
        Start-Process $Url
        Write-Log "Opened download page: $Url"
    }
}

function Launch-OrDownloadWithArch {
    # Like Launch-OrDownload, but if both a 32-bit and 64-bit copy are found
    # (in PortableTools or installed), asks which one to run.
    param($Name, [string]$Keyword, [string[]]$KnownPaths64, [string[]]$KnownPaths32, [string]$ExeName64, [string]$ExeName32, [string]$Url)
    $statusLabel.Text = "Searching for $Name..."
    [System.Windows.Forms.Application]::DoEvents()

    $path64 = Find-InPortableToolsArch -Keyword $Keyword -Arch '64'
    $path32 = Find-InPortableToolsArch -Keyword $Keyword -Arch '32'
    if (-not $path64) { $path64 = Find-ToolExe -KnownPaths $KnownPaths64 -ExeName $ExeName64 }
    if (-not $path32) { $path32 = Find-ToolExe -KnownPaths $KnownPaths32 -ExeName $ExeName32 }

    # Fall back to any keyword match in PortableTools if neither arch-specific search hit
    if (-not $path64 -and -not $path32) {
        $any = Find-InPortableTools -Keyword $Keyword
        if ($any) { $path64 = $any }
    }

    $statusLabel.Text = "Ready"

    if ($path64 -and $path32 -and ($path64 -ne $path32)) {
        if (Confirm-Action "Launch the 64-bit version of $Name? (Choose No for 32-bit)") {
            Invoke-Launch "$Name (64-bit)" $path64
        } else {
            Invoke-Launch "$Name (32-bit)" $path32
        }
        return
    }
    if ($path64) { Invoke-Launch "$Name (64-bit)" $path64; return }
    if ($path32) { Invoke-Launch "$Name (32-bit)" $path32; return }

    Write-Log "$Name not found in PortableTools\ or installed on this PC."
    if (Confirm-Action "$Name doesn't appear to be in the PortableTools folder or installed. Open the official download page in your browser?") {
        Start-Process $Url
        Write-Log "Opened download page: $Url"
    }
}

# ============================================================
#  TAB 6: HARDWARE DIAGNOSTICS (third-party tools)
# ============================================================
$tabDiag = New-Tab $tabs "Hardware Diagnostics"

New-ToolButton $tabDiag "HWiNFO" {
    Launch-OrDownloadWithArch "HWiNFO" "hwinfo" @(
        "$env:ProgramFiles\HWiNFO64\HWiNFO64.exe",
        "${env:ProgramFiles(x86)}\HWiNFO64\HWiNFO64.exe"
    ) @(
        "${env:ProgramFiles(x86)}\HWiNFO32\HWiNFO32.exe"
    ) "HWiNFO64.exe" "HWiNFO32.exe" "https://www.hwinfo.com/download/"
} -Tooltip "In-depth hardware sensor and monitoring tool (temps, voltages, clock speeds)."
New-ToolButton $tabDiag "Hard Disk Sentinel" {
    Launch-OrDownload "Hard Disk Sentinel" "hdsentinel" @(
        "$env:ProgramFiles\Hard Disk Sentinel\HDSentinel.exe",
        "${env:ProgramFiles(x86)}\Hard Disk Sentinel\HDSentinel.exe"
    ) "HDSentinel.exe" "https://www.hdsentinel.com/hard_disk_sentinel_windows.php"
} -Tooltip "Disk health monitoring and SMART diagnostics tool."
New-ToolButton $tabDiag "CrystalDiskInfo" {
    Launch-OrDownloadWithArch "CrystalDiskInfo" "diskinfo" @(
        "$env:ProgramFiles\CrystalDiskInfo\DiskInfo64.exe"
    ) @(
        "${env:ProgramFiles(x86)}\CrystalDiskInfo\DiskInfo32.exe"
    ) "DiskInfo64.exe" "DiskInfo32.exe" "https://crystalmark.info/en/software/crystaldiskinfo/"
} -Tooltip "Quick SMART-based disk health checker."
New-ToolButton $tabDiag "CrystalDiskMark" {
    Launch-OrDownloadWithArch "CrystalDiskMark" "diskmark" @(
        "$env:ProgramFiles\CrystalDiskMark\DiskMark64.exe"
    ) @(
        "${env:ProgramFiles(x86)}\CrystalDiskMark\DiskMark32.exe"
    ) "DiskMark64.exe" "DiskMark32.exe" "https://crystalmark.info/en/software/crystaldiskmark/"
} -Tooltip "Disk read/write speed benchmark tool."
New-ToolButton $tabDiag "Speccy" {
    Launch-OrDownloadWithArch "Speccy" "speccy" @(
        "$env:ProgramFiles\CCleaner\Speccy64.exe"
    ) @(
        "${env:ProgramFiles(x86)}\Speccy\Speccy.exe"
    ) "Speccy64.exe" "Speccy.exe" "https://www.ccleaner.com/speccy"
} -Tooltip "Full system specs overview tool (CPU, RAM, motherboard, storage, graphics)."
New-ToolButton $tabDiag "CPU-Z" {
    Launch-OrDownloadWithArch "CPU-Z" "cpuz" @(
        "$env:ProgramFiles\CPUID\CPU-Z\cpuz64.exe"
    ) @(
        "${env:ProgramFiles(x86)}\CPUZ\cpuz.exe"
    ) "cpuz64.exe" "cpuz.exe" "https://www.cpuid.com/softwares/cpu-z.html"
} -Tooltip "Shows detailed CPU, motherboard, and RAM information."
New-ToolButton $tabDiag "GPU-Z" {
    Launch-OrDownload "GPU-Z" "gpu-z" @(
        "$env:ProgramFiles\GPU-Z\GPU-Z.exe",
        "${env:ProgramFiles(x86)}\GPU-Z\GPU-Z.exe"
    ) "GPU-Z.exe" "https://www.techpowerup.com/gpuz/"
} -Tooltip "Shows detailed graphics card information."
New-ToolButton $tabDiag "AIDA64 Extreme" {
    Launch-OrDownload "AIDA64" "aida64" @(
        "$env:ProgramFiles\FinalWire\AIDA64\aida64.exe",
        "${env:ProgramFiles(x86)}\FinalWire\AIDA64\aida64.exe"
    ) "aida64.exe" "https://www.aida64.com/downloads"
} -Tooltip "Comprehensive system diagnostics and benchmarking suite."
New-ToolButton $tabDiag "BatteryInfoView" {
    Launch-OrDownloadWithArch "BatteryInfoView" "batteryinfoview" @() @() "BatteryInfoView.exe" "BatteryInfoView.exe" "https://www.nirsoft.net/utils/battery_information_view.html"
} -Tooltip "Shows laptop battery health, wear level, and charge cycle info."
New-ToolButton $tabDiag "BlueScreenView" {
    Launch-OrDownloadWithArch "BlueScreenView" "bluescreenview" @() @() "BlueScreenView.exe" "BlueScreenView.exe" "https://www.nirsoft.net/utils/blue_screen_view.html"
} -Tooltip "Analyzes Windows crash dump (BSOD) files to help find the cause."
New-ToolButton $tabDiag "USBDeview" {
    Launch-OrDownloadWithArch "USBDeview" "usbdeview" @() @() "USBDeview.exe" "USBDeview.exe" "https://www.nirsoft.net/utils/usb_devices_view.html"
} -Tooltip "Lists every USB device ever connected to this PC, current and historical - useful for tracking down unrecognized/faulty USB devices or auditing what's been plugged in."
New-ToolButton $tabDiag "WhatIsHang" {
    Launch-OrDownloadWithArch "WhatIsHang" "whatishang" @() @() "WhatIsHang.exe" "WhatIsHang.exe" "https://www.nirsoft.net/utils/what_is_hang.html"
} -Tooltip "Diagnoses why an application has frozen/stopped responding - shows the stack trace of the hung process."
New-ToolButton $tabDiag "Wireless Network Watcher" {
    Launch-OrDownload "Wireless Network Watcher" "wnetwatcher" @() "WNetWatcher.exe" "https://www.nirsoft.net/utils/wireless_network_watcher.html"
} -Tooltip "Scans and lists all devices currently connected to your Wi-Fi network - a lighter, faster alternative to the full network scan for a quick device count."
New-ToolButton $tabDiag "PstPassword" {
    Launch-OrDownload "PstPassword" "pstpassword" @() "PstPassword.exe" "https://www.nirsoft.net/utils/pst_password.html"
} -Tooltip "Recovers/finds the password for an Outlook PST data file. Legitimate NirSoft recovery tool for users who forgot their own Outlook file password."
New-ToolButton $tabDiag "OCCT (Stress Test)" {
    if (Confirm-Action "OCCT stress-tests CPU/GPU/PSU and can push hardware hard (heat, power draw). Make sure temps/cooling are OK before running a full test. Continue?") {
        Launch-OrDownload "OCCT" "occt" @(
            "$env:ProgramFiles\OCCT\OCCT.exe",
            "${env:ProgramFiles(x86)}\OCCT\OCCT.exe"
        ) "OCCT.exe" "https://www.ocbase.com/"
    }
} -Tooltip "Launches OCCT to stress-test CPU/GPU/PSU stability. Pushes hardware hard - watch temps."
New-ToolButton $tabDiag "Speedtest CLI (Ookla)" {
    $path = Find-InPortableTools -Keyword "speedtest"
    if ($path) {
        Start-ToolJob "Speedtest CLI" {
            param($exePath)
            & $exePath --accept-license --accept-gdpr 2>&1 | Out-String -Stream
        } -ArgumentList $path
    } else {
        Write-Log "Speedtest CLI not found in the PortableTools folder."
        if (Confirm-Action "Speedtest CLI (Ookla) doesn't appear to be in the PortableTools folder. Open the official download page in your browser?") {
            Start-Process "https://www.speedtest.net/apps/cli"
            Write-Log "Opened download page: https://www.speedtest.net/apps/cli"
        }
    }
} -Tooltip "Runs Ookla's official Speedtest CLI from PortableTools for an authoritative speed test (more accurate than the built-in one). Console tool - output streams into the log."
New-ToolButton $tabDiag "Run Built-in Memory Diagnostic" {
    if (Confirm-Action "This tool requires a restart to run the memory test. Continue?") {
        Invoke-Launch "Memory Diagnostic" "mdsched.exe"
    }
} -Tooltip "Runs the Windows Memory Diagnostic tool to check for faulty RAM. Requires a restart."
New-ToolButton $tabDiag "Run Built-in Disk Check (CHKDSK)" {
    $drive = Get-TextInput "Drive letter to check (e.g. C: or D:):" "CHKDSK" "C:"
    if ($drive) {
        if ($drive -notmatch ':$') { $drive = "$drive`:" }
        $isSystemDrive = ($drive.TrimEnd(':') -ieq $env:SystemDrive.TrimEnd(':'))
        if ($isSystemDrive) {
            if (Confirm-Action "$drive is the system drive - Windows can't check it while it's in use, so this schedules a check at next restart. Continue?") {
                Start-ToolJob "CHKDSK $drive (scheduled at restart)" { param($d) "Y" | & chkdsk.exe $d /f /r 2>&1 | Out-String -Stream } -ArgumentList $drive
            }
        } else {
            if (Confirm-Action "$drive is not the system drive, so this can run immediately (no restart needed) - it will briefly dismount the drive, so close any open files on it first. Continue?") {
                Start-ToolJob "CHKDSK $drive (immediate)" { param($d) & chkdsk.exe $d /f /r /x 2>&1 | Out-String -Stream } -ArgumentList $drive
            }
        }
    }
} -Tooltip "Checks/repairs a drive. The system drive requires a restart; other drives run immediately."

# ============================================================
#  TAB 7: SMB / NETWORK PRINTING FIXES
# ============================================================
$tabSmb = New-Tab $tabs "SMB / Printing Fixes"

New-ToolButton $tabSmb "*** Diagnose Sharing/Printer Problem (Run This First) ***" {
    Start-ToolJob "Sharing & Printer Diagnostic Checklist" {
        param($logsDir)
        $reportLines = & {
        "############################################################"
        "  NETWORK & PRINTER SHARING - DIAGNOSTIC CHECKLIST"
        "############################################################"
        "IMPORTANT: Sharing problems almost always involve TWO computers."
        "Run this same check on the OTHER PC too (client AND host/server)"
        "and compare both reports for the full picture."

        $findings = New-Object System.Collections.Generic.List[string]

        "`r`n=== 1/9: This Computer ==="
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $build = [int]$os.BuildNumber
            $ubr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name UBR -ErrorAction SilentlyContinue).UBR
            $fullBuild = if ($ubr) { "$build.$ubr" } else { "$build" }
            "Computer name: $env:COMPUTERNAME"
            "OS: $($os.Caption) - Build $fullBuild"
            if ($build -ge 26100) {
                "  --> This is Windows 11 24H2 or newer. SMB signing is REQUIRED by default and guest access is BLOCKED by default here - a common cause when something 'used to work' before an upgrade."
                $findings.Add("Windows 11 24H2+ detected - SMB signing/guest defaults are stricter than Windows 10 ever had.")
            }
        } catch { "Could not read OS info: $($_.Exception.Message)" }

        "`r`n=== 2/9: Network Profile ==="
        try {
            $profiles = Get-NetConnectionProfile -ErrorAction Stop
            foreach ($p in $profiles) {
                "Network '$($p.Name)': $($p.NetworkCategory)"
                if ($p.NetworkCategory -eq "Public") {
                    "  --> WARNING: Public profile blocks discovery and sharing by Windows default firewall rules."
                    $findings.Add("Network profile is Public on '$($p.Name)' - blocks discovery/sharing. Fix: 'Force Network Profile to Private' (trusted networks only).")
                }
            }
        } catch { "Could not read network profile: $($_.Exception.Message)" }

        "`r`n=== 3/9: SMB Signing Requirements ==="
        try {
            $clientSig = if (Get-Command Get-SmbClientConfiguration -ErrorAction SilentlyContinue) { (Get-SmbClientConfiguration).RequireSecuritySignature } else { (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name RequireSecuritySignature -ErrorAction SilentlyContinue).RequireSecuritySignature }
            $serverSig = if (Get-Command Get-SmbServerConfiguration -ErrorAction SilentlyContinue) { (Get-SmbServerConfiguration).RequireSecuritySignature } else { (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name RequireSecuritySignature -ErrorAction SilentlyContinue).RequireSecuritySignature }
            "Client (outgoing connections) signing required: $clientSig"
            "Server (incoming connections) signing required: $serverSig"
            if ($clientSig -or $serverSig) {
                "  --> If the OTHER PC is older (Windows 10, or an old NAS/router) and doesn't support/require signing the same way, this mismatch can block the connection."
                $findings.Add("SMB signing is required on this PC. If the other PC is older/incompatible, fix: 'Make Sharing Work Like Windows 10'.")
            }
        } catch { "Could not read SMB signing config: $($_.Exception.Message)" }

        "`r`n=== 4/9: Guest / Insecure Auth ==="
        try {
            $guestAuth = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name AllowInsecureGuestAuth -ErrorAction SilentlyContinue).AllowInsecureGuestAuth
            "AllowInsecureGuestAuth: $(if ($null -eq $guestAuth) { '0 (default - blocked)' } else { $guestAuth })"
            if (-not $guestAuth) {
                "  --> If you're connecting to an older device (NAS, printer) that only offers guest/anonymous access, this blocks it by default."
                $findings.Add("Guest/insecure auth is blocked (default). If connecting to an old NAS/device needing guest access, fix: 'Make Sharing Work Like Windows 10' or 'Allow Insecure Guest Connections (Outgoing)'.")
            }
        } catch { "Could not read guest auth setting: $($_.Exception.Message)" }

        "`r`n=== 5/9: SMB1 Protocol ==="
        try {
            $smb1 = if (Get-Command Get-SmbServerConfiguration -ErrorAction SilentlyContinue) { (Get-SmbServerConfiguration).EnableSMB1Protocol } else { (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name SMB1 -ErrorAction SilentlyContinue).SMB1 }
            "SMB1 enabled: $(if ($smb1) { 'Yes' } else { 'No (default - this is normal, not usually the problem)' })"
        } catch { "Could not read SMB1 status: $($_.Exception.Message)" }

        "`r`n=== 6/9: Required Services ==="
        $services = @("LanmanServer","LanmanWorkstation","FDResPub","FDPHOST","SSDPSRV","upnphost","Spooler")
        foreach ($svc in $services) {
            try {
                $s = Get-Service -Name $svc -ErrorAction Stop
                $startType = (Get-CimInstance Win32_Service -Filter "Name='$svc'" -ErrorAction SilentlyContinue).StartMode
                "$svc : Status=$($s.Status), StartType=$startType"
                if ($s.Status -ne 'Running' -or $startType -eq 'Disabled') {
                    $findings.Add("Service '$svc' is not running/enabled. Fix: 'Fix Network Path Not Found (0x80070035)'.")
                }
            } catch { "$svc : not found - $($_.Exception.Message)" }
        }

        "`r`n=== 7/9: Firewall Rules ==="
        foreach ($grp in @("Network Discovery","File and Printer Sharing")) {
            try {
                $rules = netsh advfirewall firewall show rule group="$grp" 2>&1 | Select-String "Enabled:"
                $anyEnabled = ($rules | Where-Object { $_ -match "Yes" }).Count -gt 0
                "'$grp' rule group: $(if ($anyEnabled) { 'At least one rule enabled' } else { 'No rules enabled' })"
                if (-not $anyEnabled) {
                    $findings.Add("Firewall group '$grp' has no rules enabled. Fix: 'Fix Network Path Not Found (0x80070035)' or 'Enable File and Printer Sharing (Firewall)'.")
                }
            } catch { "Could not check '$grp' firewall rules: $($_.Exception.Message)" }
        }

        "`r`n=== 8/9: Printer-Specific Settings ==="
        try {
            $rpcPriv = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name RpcAuthnLevelPrivacyEnabled -ErrorAction SilentlyContinue).RpcAuthnLevelPrivacyEnabled
            "RPC Authn Level Privacy Enabled: $(if ($null -eq $rpcPriv) { '1 (default)' } else { $rpcPriv })"
            if ($null -eq $rpcPriv -or $rpcPriv -eq 1) {
                "  --> If you're seeing error 0x0000011b connecting to a shared printer, this default setting is the usual cause."
                $findings.Add("RPC privacy enforcement is at default. If seeing printer error 0x0000011b, fix: 'Fix Printer Error 0x0000011b'.")
            }
            $pnpNoWarn = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" -Name NoWarningNoElevationOnInstall -ErrorAction SilentlyContinue).NoWarningNoElevationOnInstall
            "Point and Print elevation bypass: $(if ($pnpNoWarn -eq 1) { 'Relaxed' } else { 'Default (restricted)' })"
            if ($pnpNoWarn -ne 1) {
                "  --> If you're seeing error 0x00000709 connecting to a shared printer, this default restriction is the usual cause."
                $findings.Add("Point and Print is restricted (default). If seeing printer error 0x00000709, fix: 'Fix Printer Connection Error 0x00000709 (Point and Print)'.")
            }
            $spoolerStatus = (Get-Service -Name Spooler -ErrorAction SilentlyContinue).Status
            "Print Spooler service: $spoolerStatus"
        } catch { "Could not read printer-specific settings: $($_.Exception.Message)" }

        "`r`n=== 9/9: What This PC Is Currently Sharing ==="
        try {
            $shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Name -notmatch '\$$' }
            if ($shares) { $shares | ForEach-Object { "Share: $($_.Name) -> $($_.Path)" } }
            else { "No file shares currently hosted on this PC." }
        } catch { "Could not list shares: $($_.Exception.Message)" }
        try {
            $sharedPrinters = Get-Printer -ErrorAction Stop | Where-Object { $_.Shared }
            if ($sharedPrinters) { $sharedPrinters | ForEach-Object { "Shared printer: $($_.Name)" } }
            else { "No printers currently shared from this PC." }
        } catch { "Could not list printers: $($_.Exception.Message)" }

        "`r`n############################################################"
        "  DIAGNOSIS / RECOMMENDED FIXES"
        "############################################################"
        if ($findings.Count -eq 0) {
            "No obvious problems found on THIS PC's sharing configuration."
            "If you're still having trouble, the issue is most likely on the OTHER computer - run this same checklist there."
        } else {
            "Based on what was found on THIS PC, here's what's likely relevant:`r`n"
            $i = 1
            foreach ($f in $findings) {
                "$i. $f"
                $i++
            }
        }
        "`r`nRemember: run this checklist on the other PC too if the problem persists after applying a fix here."
        }

        # Stream every line to the live log, and also save the whole thing as its own
        # dedicated report file - easier to compare client vs. host than digging through
        # the big rolling session log.
        $reportLines | Out-String -Stream
        if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -Path $logsDir -ItemType Directory -Force | Out-Null }
        $reportPath = Join-Path $logsDir "SharingDiagnostic_$env:COMPUTERNAME`_$(Get-Date -Format 'yyyy-MM-dd_HHmm').txt"
        $reportLines | Out-File -FilePath $reportPath -Encoding UTF8
        "`r`nSaved as its own report file: $reportPath"
    } -ArgumentList $script:LogsDir
} -Tooltip "Run this FIRST when troubleshooting sharing/printer issues. Checks OS version, SMB signing, guest access, services, firewall, and printer-specific settings, then tells you exactly which fix button below to use."

New-ToolButton $tabSmb "*** Make Sharing Work Like Windows 10 ***" {
    if (Confirm-Action "Windows 11 (24H2+) added two changes beyond what Windows 10 ever had: SMB signing is now REQUIRED by default on all connections (both directions), and guest/anonymous access is blocked by default (even on Pro). This is almost always the real reason an old NAS, printer, or share that 'used to just work' stopped working after upgrading. This restores the Windows 10-style behavior. Only use on a trusted internal network. Continue?") {
        Start-ToolJob "Restore Windows 10-style Sharing" {
            "=== Restoring Windows 10-style file/printer sharing behavior ==="
            "(Reverting the SMB-signing-required and guest-blocked defaults Windows 11 24H2+ added)"

            "`r`n--- SMB Signing: Outgoing (this PC connecting to other shares) ---"
            $beforeClient = "Unknown"
            try {
                if (Get-Command Get-SmbClientConfiguration -ErrorAction SilentlyContinue) {
                    $beforeClient = (Get-SmbClientConfiguration).RequireSecuritySignature
                } else {
                    $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue).RequireSecuritySignature
                    $beforeClient = if ($null -eq $v) { $false } else { [bool]$v }
                }
            } catch {}
            "Before: signing required = $beforeClient"
            try {
                if (Get-Command Set-SmbClientConfiguration -ErrorAction SilentlyContinue) {
                    Set-SmbClientConfiguration -RequireSecuritySignature $false -Force -ErrorAction Stop
                    $afterClient = (Get-SmbClientConfiguration).RequireSecuritySignature
                } else {
                    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                    New-ItemProperty -Path $p -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                    $afterClient = $false
                }
                "After: signing required = $afterClient  -->  CHANGED" 
            } catch { "FAILED to change client signing requirement: $($_.Exception.Message)" }

            "`r`n--- SMB Signing: Incoming (other PCs connecting to shares on THIS PC) ---"
            $beforeServer = "Unknown"
            try {
                if (Get-Command Get-SmbServerConfiguration -ErrorAction SilentlyContinue) {
                    $beforeServer = (Get-SmbServerConfiguration).RequireSecuritySignature
                } else {
                    $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue).RequireSecuritySignature
                    $beforeServer = if ($null -eq $v) { $false } else { [bool]$v }
                }
            } catch {}
            "Before: signing required = $beforeServer"
            try {
                if (Get-Command Set-SmbServerConfiguration -ErrorAction SilentlyContinue) {
                    Set-SmbServerConfiguration -RequireSecuritySignature $false -Force -ErrorAction Stop
                    $afterServer = (Get-SmbServerConfiguration).RequireSecuritySignature
                } else {
                    $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
                    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                    New-ItemProperty -Path $p -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                    $afterServer = $false
                }
                "After: signing required = $afterServer  -->  CHANGED"
            } catch { "FAILED to change server signing requirement: $($_.Exception.Message)" }

            "`r`n--- Guest / Anonymous Access Fallback ---"
            $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
            $beforeGuest = (Get-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -ErrorAction SilentlyContinue).AllowInsecureGuestAuth
            "Before: AllowInsecureGuestAuth = $(if ($null -eq $beforeGuest) { '0 (not set / default)' } else { $beforeGuest })"
            try {
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                New-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "After: AllowInsecureGuestAuth = 1  -->  CHANGED"
            } catch { "FAILED to enable guest fallback: $($_.Exception.Message)" }

            "`r`n--- Network Discovery / File & Printer Sharing services ---"
            $services = @("LanmanServer","LanmanWorkstation","FDResPub","FDPHOST","SSDPSRV","upnphost")
            foreach ($svc in $services) {
                try {
                    $before = Get-Service -Name $svc -ErrorAction Stop
                    $beforeStartType = (Get-CimInstance Win32_Service -Filter "Name='$svc'" -ErrorAction SilentlyContinue).StartMode
                    "$svc - before: Status=$($before.Status), StartType=$beforeStartType"
                    Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop
                    Start-Service -Name $svc -ErrorAction SilentlyContinue
                    $after = Get-Service -Name $svc -ErrorAction Stop
                    "$svc - after:  Status=$($after.Status), StartType=Automatic"
                } catch {
                    "$svc : FAILED - $($_.Exception.Message)"
                }
            }

            "`r`n--- Firewall ---"
            $beforeFw = netsh advfirewall firewall show rule group="File and Printer Sharing" 2>&1 | Select-String "Enabled:" | Select-Object -First 1
            "Before (File and Printer Sharing rule group): $beforeFw"
            netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-String -Stream
            netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-String -Stream
            "After: File and Printer Sharing + Network Discovery firewall rule groups enabled."

            "`r`n=== SUMMARY ==="
            "Client SMB signing required: $beforeClient -> $afterClient"
            "Server SMB signing required: $beforeServer -> $afterServer"
            "Guest/insecure auth allowed: $(if ($beforeGuest -eq 1) {'Yes'} else {'No'}) -> Yes"
            "`r`nDone. RESTART THE COMPUTER (or at minimum restart the 'Server' and 'Workstation' services) for the signing changes to fully apply."
            "Note: SMB1 was intentionally NOT touched - that's a separate, more extreme legacy step (see 'Enable SMB1' below), only needed for very old devices, not standard Windows-10-style behavior."
        }
    }
} -Tooltip "The main fix for 'this used to work fine in Windows 10' sharing/printer problems. Reverts the SMB-signing-required and guest-blocked defaults added in Windows 11 24H2+. Reports exact before/after state for every change."
New-ToolButton $tabSmb "Restore Windows 11 Secure Defaults (Undo)" {
    if (Confirm-Action "This re-enables Windows 11's hardened defaults: requires SMB signing again (both directions) and disables insecure guest access. Use this to undo the compatibility fix above once you no longer need it. Continue?") {
        Start-ToolJob "Restore Windows 11 Secure Defaults" {
            "=== Restoring Windows 11 secure SMB defaults ==="

            "`r`n--- Client SMB Signing ---"
            try {
                $before = if (Get-Command Get-SmbClientConfiguration -ErrorAction SilentlyContinue) { (Get-SmbClientConfiguration).RequireSecuritySignature } else { "Unknown" }
                "Before: signing required = $before"
                if (Get-Command Set-SmbClientConfiguration -ErrorAction SilentlyContinue) {
                    Set-SmbClientConfiguration -RequireSecuritySignature $true -Force -ErrorAction Stop
                    $after = (Get-SmbClientConfiguration).RequireSecuritySignature
                } else {
                    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                    $after = $true
                }
                "After: signing required = $after  -->  CHANGED"
            } catch { "FAILED: $($_.Exception.Message)" }

            "`r`n--- Server SMB Signing ---"
            try {
                $before = if (Get-Command Get-SmbServerConfiguration -ErrorAction SilentlyContinue) { (Get-SmbServerConfiguration).RequireSecuritySignature } else { "Unknown" }
                "Before: signing required = $before"
                if (Get-Command Set-SmbServerConfiguration -ErrorAction SilentlyContinue) {
                    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force -ErrorAction Stop
                    $after = (Get-SmbServerConfiguration).RequireSecuritySignature
                } else {
                    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                    $after = $true
                }
                "After: signing required = $after  -->  CHANGED"
            } catch { "FAILED: $($_.Exception.Message)" }

            "`r`n--- Guest/Insecure Auth ---"
            try {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                $before = (Get-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -ErrorAction SilentlyContinue).AllowInsecureGuestAuth
                "Before: AllowInsecureGuestAuth = $(if ($null -eq $before) { 'not set' } else { $before })"
                New-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "After: AllowInsecureGuestAuth = 0  -->  CHANGED"
            } catch { "FAILED: $($_.Exception.Message)" }

            "`r`nDone. RESTART THE COMPUTER for changes to fully apply."
        }
    }
} -Tooltip "Undoes the Windows-10-compatibility fix above - re-enables required SMB signing and disables insecure guest access, restoring Windows 11's hardened defaults."

New-ToolButton $tabSmb "Fix 'Network Path Not Found' (0x80070035)" {
    Start-ToolJob "Fix Network Path Not Found" {
        "=== Fixing common causes of 'Network path not found' (0x80070035) ==="

        $services = @("LanmanServer","LanmanWorkstation","FDResPub","FDPHOST","SSDPSRV","upnphost")
        foreach ($svc in $services) {
            try {
                Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $svc -ErrorAction SilentlyContinue
                "Service '$svc' set to Automatic and started."
            } catch {
                "Could not configure service '$svc': $($_.Exception.Message)"
            }
        }

        "`r`nEnabling Network Discovery and File/Printer Sharing firewall rules..."
        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-String -Stream
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-String -Stream

        "`r`nDone. If this was for one specific remote share, also confirm the target PC is on and has sharing enabled too."
        "A restart is recommended if the problem persists."
    }
} -Tooltip "Fixes the most common causes of 'network path not found' - starts required services and enables Network Discovery / File and Printer Sharing firewall rules."
New-ToolButton $tabSmb "Enable File and Printer Sharing (Firewall)" {
    Start-ToolJob "Enable File/Printer Sharing Firewall Rule" {
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-String -Stream
        "Done. Other PCs on this network should now be able to see this PC's shares and printers."
    }
} -Tooltip "Enables the built-in 'File and Printer Sharing' firewall rule group - needed for others to see this PC's shares/printers."
New-ToolButton $tabSmb "Fix Printer Connection Error 0x00000709 (Point and Print)" {
    if (Confirm-Action "WARNING: this relaxes the Point and Print driver-installation policy (part of the security hardening added after the PrintNightmare vulnerability). Only do this on a trusted internal network with a trusted print server. Continue?") {
        Start-ToolJob "Point and Print Fix" {
            $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
            if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
            New-ItemProperty -Path $p -Name "NoWarningNoElevationOnInstall" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p -Name "UpdatePromptSettings" -Value 0 -PropertyType DWord -Force | Out-Null
            "Point and Print restrictions relaxed. Restart the Print Spooler (or reboot), then try connecting to the printer again."
        }
    }
} -Tooltip "WARNING: relaxes Point and Print driver-install restrictions to fix error 0x00000709 connecting to a shared printer. Reduces post-PrintNightmare protection - trusted networks only."
New-ToolButton $tabSmb "Reset Saved Network Credentials" {
    if (Confirm-Action "This clears saved network/share usernames and passwords from Credential Manager. You'll be prompted to re-enter them next time you connect to a share. Continue?") {
        Start-ToolJob "Reset Network Credentials" {
            $list = cmdkey /list 2>&1
            $targets = $list | Select-String "Target:\s*(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } | Where-Object { $_ -match "^Domain:target=|^LegacyGeneric:target=" }
            if (-not $targets -or $targets.Count -eq 0) {
                "No saved network credentials found."
            } else {
                foreach ($t in $targets) { cmdkey /delete:$t 2>&1 | Out-String -Stream }
                "Removed $($targets.Count) saved network credential(s)."
            }
        }
    }
} -Tooltip "Clears saved network share usernames/passwords - fixes repeated 'access denied' prompts caused by stale cached credentials."

New-ToolButton $tabSmb "Fix Printer Error 0x0000011b" {
    Start-ToolJob "Fix 0x0000011b" {
        # Disables RPC Authentication Privacy Enforcement for the print spooler
        if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print")) { New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Force | Out-Null }
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
        "Fix applied: RpcAuthnLevelPrivacyEnabled = 0. Restart the Print Spooler service or reboot to apply."
    }
} -Tooltip "Fixes a common 'Operation failed with error 0x0000011b' network printing error."
New-ToolButton $tabSmb "Enable Guest Access to Shares" {
    if (Confirm-Action "WARNING: This weakens SMB authentication by allowing anonymous/guest connections. Only use on trusted internal networks. Continue?") {
        Start-ToolJob "Enable Guest Access" {
            $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
            New-ItemProperty -Path $p -Name "RestrictAnonymous" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p -Name "EveryoneIncludesAnonymous" -Value 1 -PropertyType DWord -Force | Out-Null
            "Guest access enabled. Restart required."
        }
    }
} -Tooltip "WARNING: allows anonymous/guest SMB connections. Trusted internal networks only."
New-ToolButton $tabSmb "Enable Network Discovery" {
    Start-ToolJob "Enable Network Discovery" {
        foreach ($svc in @("FDResPub","LanmanWorkstation")) {
            $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
            if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
            New-ItemProperty -Path $p -Name "Start" -Value 2 -PropertyType DWord -Force | Out-Null
        }
        "Network discovery services set to auto-start. Reboot or restart the services to apply."
    }
} -Tooltip "Lets this PC see and be seen by other devices on the network."
New-ToolButton $tabSmb "Enable SMB1 (legacy devices)" {
    if (Confirm-Action "WARNING: SMB1 is an outdated, insecure protocol (e.g. EternalBlue). Only enable for legacy printers/NAS that require it, ideally isolated on their own network segment. Continue?") {
        Start-ToolJob "Enable SMB1" {
            $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
            if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
            New-ItemProperty -Path $p -Name "SMB1" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p -Name "EnableSecuritySignature" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force | Out-Null
            "SMB1 enabled. Restart required."
        }
    }
} -Tooltip "WARNING: enables an outdated, insecure protocol. Only for legacy printers/NAS that need it."
New-ToolButton $tabSmb "Improve SMB Network Speed" {
    Start-ToolJob "Improve SMB Speed" {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters"
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name "EnablePMTUDiscovery" -Value 1 -PropertyType DWord -Force | Out-Null
        "PMTU Discovery enabled for NetBT. Restart recommended."
    }
} -Tooltip "Enables PMTU discovery, which can improve file transfer speed on some networks."
New-ToolButton $tabSmb "Restart Print Spooler" {
    Start-ToolJob "Restart Print Spooler" {
        Restart-Service spooler -Force -ErrorAction Stop
        "Print Spooler service restarted."
    }
} -Tooltip "Restarts the Print Spooler service. The classic fix for a stuck print queue."
New-ToolButton $tabSmb "Force Print Spooler Auto-Start" {
    Start-ToolJob "Spooler Auto-Start" {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        New-ItemProperty -Path $p -Name "Start" -Value 2 -PropertyType DWord -Force | Out-Null
        Start-Service spooler -ErrorAction SilentlyContinue
        "Print Spooler set to auto-start and (re)started."
    }
} -Tooltip "Sets the Print Spooler service to start automatically with Windows."
New-ToolButton $tabSmb "Force Network Profile to Private" {
    if (Confirm-Action "WARNING: This sets ALL active network connections to 'Private', which uses much more permissive firewall rules (needed for sharing to work). Only do this on networks you trust - never on public/untrusted Wi-Fi. Continue?") {
        Start-ToolJob "Set Network Profile to Private" {
            try {
                $profiles = Get-NetConnectionProfile -ErrorAction Stop
                if (-not $profiles) { "No active network connections found."; return }
                foreach ($p in $profiles) {
                    try {
                        Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
                        "Set '$($p.Name)' to Private."
                    } catch {
                        "Could not change '$($p.Name)': $($_.Exception.Message)"
                    }
                }
            } catch {
                "ERROR: Could not read network connection profiles (NetTCPIP module may be unavailable): $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Sets all active network connections to 'Private' profile, which uses more permissive firewall rules. Only use on trusted networks."
New-ToolButton $tabSmb "Allow Insecure Guest Connections (Outgoing)" {
    if (Confirm-Action "WARNING: This allows THIS PC to connect OUT to other insecure/guest SMB shares (e.g. some older NAS devices) without normal authentication. Different from 'Enable Guest Access to Shares', which affects shares hosted ON this PC. Continue?") {
        Start-ToolJob "Allow Insecure Guest Auth (Client)" {
            try {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                New-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "AllowInsecureGuestAuth enabled. Restart required."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Lets this PC connect to insecure/legacy SMB shares (older NAS, etc). Client-side - different from the guest-access fix for shares hosted on this PC."
New-ToolButton $tabSmb "Disable SMB Signing Requirement (Outgoing)" {
    if (Confirm-Action "WARNING: This disables the requirement for SMB signing when THIS PC connects OUT to other shares, which protects against man-in-the-middle attacks. Only do this if required for compatibility with an old device. Continue?") {
        Start-ToolJob "Disable SMB Signing Requirement (Client)" {
            try {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                New-ItemProperty -Path $p -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "SMB signing requirement disabled for outgoing connections. Restart required."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Disables SMB signing requirement for outgoing connections (this PC to other shares). Reduces protection against man-in-the-middle attacks."
New-ToolButton $tabSmb "Enable Legacy Printer RPC (Named Pipes)" {
    if (Confirm-Action "WARNING: This reverts printer RPC communication to the older Named Pipes method, undoing part of the hardening Microsoft added after the PrintNightmare vulnerability (CVE-2021-34527). Only use this for a trusted internal print server having connection issues. Continue?") {
        Start-ToolJob "Legacy Printer RPC Fix" {
            try {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                New-ItemProperty -Path $p -Name "RpcUseNamedPipeProtocol" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path $p -Name "RpcProtocols" -Value 7 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "Legacy printer RPC (Named Pipes) enabled. Restart the Print Spooler or reboot to apply."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Reverts printer RPC communication to Named Pipes, undoing part of the post-PrintNightmare hardening. Trusted internal print servers only."
New-ToolButton $tabSmb "Allow Blank Password Network Logon" {
    if (Confirm-Action "WARNING: This allows local accounts with BLANK passwords to be used for network logon - normally blocked by default. Rarely needed, and reduces protection against lateral movement. Continue?") {
        Start-ToolJob "Allow Blank Password Network Logon" {
            try {
                New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "LimitBlankPasswordUse disabled. Restart required."
            } catch {
                "ERROR: $($_.Exception.Message)"
            }
        }
    }
} -Tooltip "WARNING: Allows blank-password local accounts to authenticate over the network. Rarely needed - reduces protection against lateral movement."
New-ToolButton $tabSmb "Windows 11 Legacy Sharing Compatibility (All-in-One)" {
    if (Confirm-Action "This applies a full legacy-compatibility bundle for Windows 11 file/printer sharing: sets network profile to Private, starts required services, opens firewall rules, allows insecure guest auth, disables SMB signing requirement, and reverts printer RPC to Named Pipes. Includes several real security trade-offs (see the individual buttons above). Only use on a trusted internal network. Continue?") {
        Start-ToolJob "Win11 Legacy Sharing Compatibility Bundle" {
            "=== Windows 11 Legacy Sharing Compatibility ==="

            "`r`n--- Network Profile ---"
            try {
                $profiles = Get-NetConnectionProfile -ErrorAction Stop
                foreach ($p in $profiles) {
                    try { Set-NetConnectionProfile -InterfaceIndex $p.InterfaceIndex -NetworkCategory Private -ErrorAction Stop; "Set '$($p.Name)' to Private." }
                    catch { "Could not change '$($p.Name)': $($_.Exception.Message)" }
                }
            } catch { "Could not read network profiles: $($_.Exception.Message)" }

            "`r`n--- Services ---"
            $services = @("fdPHost","FDResPub","SSDPSRV","upnphost","LanmanServer","LanmanWorkstation","lmhosts","Spooler")
            foreach ($svc in $services) {
                try {
                    Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop
                    Start-Service -Name $svc -ErrorAction SilentlyContinue
                    "Service '$svc': OK"
                } catch { "Service '$svc': FAILED - $($_.Exception.Message)" }
            }

            "`r`n--- Firewall ---"
            netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-String -Stream
            netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-String -Stream

            "`r`n--- Registry (compatibility + printer RPC) ---"
            try {
                $lw = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                if (-not (Test-Path $lw)) { New-Item $lw -Force | Out-Null }
                New-ItemProperty -Path $lw -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "AllowInsecureGuestAuth: OK"
            } catch { "AllowInsecureGuestAuth: FAILED - $($_.Exception.Message)" }
            try {
                $lw = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
                New-ItemProperty -Path $lw -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "RequireSecuritySignature (client): OK"
            } catch { "RequireSecuritySignature (client): FAILED - $($_.Exception.Message)" }
            try {
                $rpc = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
                if (-not (Test-Path $rpc)) { New-Item $rpc -Force | Out-Null }
                New-ItemProperty -Path $rpc -Name "RpcUseNamedPipeProtocol" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                New-ItemProperty -Path $rpc -Name "RpcProtocols" -Value 7 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "Printer RPC (Named Pipes): OK"
            } catch { "Printer RPC (Named Pipes): FAILED - $($_.Exception.Message)" }
            try {
                New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LimitBlankPasswordUse" -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
                "LimitBlankPasswordUse: OK"
            } catch { "LimitBlankPasswordUse: FAILED - $($_.Exception.Message)" }

            "`r`nDone. RESTART THE COMPUTER for everything to take full effect."
            "Note: local account password-expiration policy was intentionally left untouched here since it's unrelated to sharing - see 'Disable Password Expiration (All Local Accounts)' in the Advanced tab if you specifically want that too."
        }
    }
} -Tooltip "All-in-one legacy compatibility bundle for Windows 11 sharing. Several real security trade-offs - see the individual buttons above for details. Reports per-step success/failure."
New-ToolButton $tabSmb "Apply ALL SMB/Printing Fixes" {
    if (Confirm-Action "This applies all 6 fixes, including SMB1 and Guest Access (both reduce security). Only proceed on a trusted internal network. Continue?") {
        Start-ToolJob "Apply All SMB Fixes" {
            # 1. Fix 0x0000011b
            $p1 = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
            if (-not (Test-Path $p1)) { New-Item $p1 -Force | Out-Null }
            New-ItemProperty -Path $p1 -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
            "1/6 - RPC print privacy fix applied."

            # 2. Guest access
            $p2 = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
            if (-not (Test-Path $p2)) { New-Item $p2 -Force | Out-Null }
            New-ItemProperty -Path $p2 -Name "RestrictAnonymous" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p2 -Name "EveryoneIncludesAnonymous" -Value 1 -PropertyType DWord -Force | Out-Null
            "2/6 - Guest access enabled."

            # 3. Network discovery
            foreach ($svc in @("FDResPub","LanmanWorkstation")) {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                New-ItemProperty -Path $p -Name "Start" -Value 2 -PropertyType DWord -Force | Out-Null
            }
            "3/6 - Network discovery enabled."

            # 4. SMB1
            $p4 = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
            if (-not (Test-Path $p4)) { New-Item $p4 -Force | Out-Null }
            New-ItemProperty -Path $p4 -Name "SMB1" -Value 1 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p4 -Name "EnableSecuritySignature" -Value 0 -PropertyType DWord -Force | Out-Null
            New-ItemProperty -Path $p4 -Name "RequireSecuritySignature" -Value 0 -PropertyType DWord -Force | Out-Null
            "4/6 - SMB1 enabled."

            # 5. Improve SMB speed
            $p5 = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters"
            if (-not (Test-Path $p5)) { New-Item $p5 -Force | Out-Null }
            New-ItemProperty -Path $p5 -Name "EnablePMTUDiscovery" -Value 1 -PropertyType DWord -Force | Out-Null
            "5/6 - PMTU discovery enabled."

            # 6. Print spooler auto-start
            $p6 = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
            if (-not (Test-Path $p6)) { New-Item $p6 -Force | Out-Null }
            New-ItemProperty -Path $p6 -Name "Start" -Value 2 -PropertyType DWord -Force | Out-Null
            Start-Service spooler -ErrorAction SilentlyContinue
            "6/6 - Print Spooler set to auto-start."

            "All fixes applied. RESTART THE COMPUTER for everything to take full effect."
        }
    }
} -Tooltip "WARNING: applies all 6 fixes at once, including SMB1 and Guest Access."

# ============================================================
#  RUN
# ============================================================
function Test-Prerequisites {
    Write-Log "############################################################"
    Write-Log "  STARTUP CHECKLIST"
    Write-Log "############################################################"

    # 1. Admin rights
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { Write-Log "[OK] Running as Administrator" }
    else { Write-Log "[ERROR] NOT running as Administrator - most tools will fail" }

    # 2. PowerShell version
    $psVer = $PSVersionTable.PSVersion
    if ($psVer.Major -ge 5) { Write-Log "[OK] PowerShell version $psVer" }
    else { Write-Log "[WARNING] PowerShell version $psVer is old - some features may not work correctly" }

    # 3. Core Windows command-line tools this toolkit relies on
    $requiredCmds = @("sfc","DISM","chkdsk","netsh","reg","net","ipconfig","ping","tracert","netstat","arp",
        "systeminfo","driverquery","schtasks","powercfg","msinfo32","gpupdate","gpresult","wsreset","cscript","manage-bde")
    $missingCmds = @($requiredCmds | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) })
    if ($missingCmds.Count -eq 0) { Write-Log "[OK] All core Windows command-line tools found" }
    else { Write-Log "[WARNING] Missing from this PC: $($missingCmds -join ', ') - the related buttons will fail" }

    # 4. WMI/CIM (Quick Health Check, network scan auto-detect, driver lists, etc. all depend on this)
    try {
        Get-CimInstance Win32_OperatingSystem -ErrorAction Stop | Out-Null
        Write-Log "[OK] WMI/CIM is responding"
    } catch {
        Write-Log "[ERROR] WMI/CIM is not responding - Quick Health Check and several other tools will fail: $($_.Exception.Message)"
    }

    # 5. NetAdapter/NetTCPIP module (adapter list, network scan auto-detect - has a fallback if missing)
    if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) { Write-Log "[OK] NetAdapter module available" }
    else { Write-Log "[WARNING] NetAdapter module not found (older Windows) - adapter tools will use a slower fallback method" }

    # 6. LocalAccounts module (Add Local User dialog - has a fallback if missing)
    if (Get-Command New-LocalUser -ErrorAction SilentlyContinue) { Write-Log "[OK] LocalAccounts module available (New-LocalUser)" }
    else { Write-Log "[WARNING] LocalAccounts module not found (older Windows) - Add Local User will use a legacy fallback" }

    # 7. PortableTools folder
    if (Test-Path -LiteralPath $PortableToolsDir) {
        $foundExes = Get-ChildItem -Path $PortableToolsDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        Write-Log "[OK] PortableTools folder found ($($foundExes.Count) .exe file(s)): $PortableToolsDir"
    } else {
        Write-Log "[INFO] No PortableTools folder found - Hardware Diagnostics tab will fall back to installed paths / download links"
    }

    # 8. Free space on the system drive (SFC/DISM/CHKDSK need headroom to work reliably)
    try {
        $sysDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -ErrorAction Stop
        $freeGB = [math]::Round($sysDisk.FreeSpace / 1GB, 1)
        if ($freeGB -lt 5) { Write-Log "[WARNING] Only $freeGB GB free on $env:SystemDrive - low disk space can cause SFC/DISM/updates to fail" }
        else { Write-Log "[OK] $freeGB GB free on $env:SystemDrive" }
    } catch {
        Write-Log "[WARNING] Could not check disk space: $($_.Exception.Message)"
    }

    # 9. Internet connectivity (affects WinUtil, Speedtest, download-page buttons, Windows Update tools)
    try {
        $pingTest = New-Object System.Net.NetworkInformation.Ping
        $reply = $pingTest.Send("8.8.8.8", 800)
        if ($reply.Status -eq 'Success') { Write-Log "[OK] Internet connectivity detected ($($reply.RoundtripTime) ms)" }
        else { Write-Log "[WARNING] No internet connectivity - WinUtil, Speedtest, and download-page buttons won't work until this is back" }
    } catch {
        Write-Log "[WARNING] Could not check internet connectivity"
    }

    Write-Log "############################################################"
    Write-Log "  CHECKLIST COMPLETE"
    Write-Log "############################################################"
}

try {
    $winTheme = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction Stop
    if ($winTheme.AppsUseLightTheme -eq 0) { Set-Theme -Dark $true }
} catch {
    # Registry value not present (older Windows) - keep the default light theme
}

Write-Log "IT Technician Toolkit ready."
Test-Prerequisites
$form.Add_FormClosing({
    if ($script:LogFileWriter) {
        try { $script:LogFileWriter.Close() } catch {}
    }
})
[System.Windows.Forms.Application]::Run($form)
