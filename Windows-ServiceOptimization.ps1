# Self-elevate silently
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo "powershell"
    $psi.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    [System.Diagnostics.Process]::Start($psi) | Out-Null; exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")]   public static extern bool ReleaseCapture();
    [DllImport("user32.dll")]   public static extern IntPtr SendMessage(IntPtr h, int msg, int w, int l);
}
"@
[Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0) | Out-Null

function RGB($r,$g,$b) { [System.Drawing.Color]::FromArgb($r,$g,$b) }

$BG=RGB 13 13 13; $SidebarBG=RGB 18 18 18; $SideEdgeC=RGB 38 38 38; $LogoBG=RGB 16 16 16
$BtnNormal=RGB 26 26 26; $BtnHover=RGB 38 38 40; $BtnBorder=RGB 52 52 54; $BtnBorderH=RGB 95 95 100
$TextHead=RGB 210 210 215; $TextWhite=RGB 175 178 185; $TextMuted=RGB 88 90 96; $TextDim=RGB 48 50 55
$ConsoleBG=RGB 10 10 10; $CWhite=RGB 201 209 217; $CGray=RGB 110 118 129; $CGreen=RGB 87 171 110
$CYellow=RGB 187 160 60; $CRed=RGB 204 88 88; $CDim=RGB 55 58 64
$DiscordC=RGB 100 120 200; $CBlue=RGB 80 140 220
$DotRed=RGB 220 80 70; $DotOrange=RGB 220 150 50; $DotWhite=RGB 200 200 205

# Services by category
$ServiceCategories = [ordered]@{
    "Telemetry & Diagnostics" = [ordered]@{
        "DiagTrack"="Connected User Experiences & Telemetry"; "dmwappushservice"="WAP Push Message Routing"
        "diagnosticshub.standardcollector.service"="Diagnostics Hub Standard Collector"
        "WerSvc"="Windows Error Reporting"; "diagsvc"="Diagnostic Execution Service"
        "WdiServiceHost"="Diagnostic Service Host"; "DPS"="Diagnostic Policy Service"
        "GraphicsPerfSvc"="Graphics Performance Monitor"; "wisvc"="Windows Insider Service"
        "PcaSvc"="Program Compatibility Assistant"; "wmiApSrv"="WMI Performance Adapter"
        "ndu"="Network Data Usage Monitor"
    }
    "Windows Update & Edge" = [ordered]@{
        "DoSvc"="Delivery Optimization"; "edgeupdate"="Microsoft Edge Update"
    }
    "Remote Access & Network" = [ordered]@{
        "RemoteRegistry"="Remote Registry"; "RemoteAccess"="Routing and Remote Access"
        "SessionEnv"="Remote Desktop Configuration"; "RasAuto"="Remote Access Auto Connection"
        "WinRM"="Windows Remote Management"; "SstpSvc"="Secure Socket Tunneling Protocol"
        "WebClient"="WebClient"; "WinHttpAutoProxySvc"="WinHTTP Web Proxy Auto-Discovery"
        "p2psvc"="Peer Networking Grouping"; "SNMPTrap"="SNMP Trap"
        "MSiSCSI"="Microsoft iSCSI Initiator"; "lltdsvc"="Link-Layer Topology Discovery"
        "FDResPub"="Function Discovery Resource Publication"; "fdPHost"="Function Discovery Provider Host"
        "SSDPSRV"="SSDP Discovery"; "upnphost"="UPnP Device Host"
        "SharedAccess"="Internet Connection Sharing"; "Netlogon"="Netlogon"
        "PeerDistSvc"="BranchCache"; "Eaphost"="Extensible Authentication Protocol"
    }
    "Bluetooth" = [ordered]@{ "BthAvctpSvc"="Bluetooth AVCTP Service"; "SEMgrSvc"="Payments and NFC/SE Manager" }
    "Printing"  = [ordered]@{ "Spooler"="Print Spooler"; "PrintNotify"="Printer Extensions and Notifications" }
    "Xbox & Gaming DVR" = [ordered]@{
        "XblAuthManager"="Xbox Live Auth Manager"; "XblGameSave"="Xbox Live Game Save"
        "XboxNetApiSvc"="Xbox Live Networking"; "XboxGipSvc"="Xbox Accessory Management"
    }
    "Hyper-V" = [ordered]@{
        "vmictimesync"="Hyper-V Time Synchronization"; "vmicheartbeat"="Hyper-V Heartbeat"
        "vmicvmsession"="Hyper-V VM Session"; "vmickvpexchange"="Hyper-V Data Exchange"
        "vmicshutdown"="Hyper-V Guest Shutdown"; "vmicvss"="Hyper-V Volume Shadow Copy"
        "vmicrdv"="Hyper-V Remote Desktop"; "vmicguestinterface"="Hyper-V Guest Interface"
        "HvHost"="Hyper-V Host Service"
    }
    "Sensors & Hardware" = [ordered]@{
        "SensrSvc"="Sensor Monitoring Service"; "SensorService"="Sensor Service"
        "FrameServer"="Windows Camera Frame Server"; "TabletInputService"="Touch Keyboard and Handwriting"
        "stisvc"="Windows Image Acquisition"; "WbioSrvc"="Windows Biometric Service"
    }
    "Smart Card" = [ordered]@{
        "ScDeviceEnum"="Smart Card Device Enumeration"; "SCPolicySvc"="Smart Card Removal Policy"
        "CertPropSvc"="Certificate Propagation"
    }
    "Location & Maps"      = [ordered]@{ "lfsvc"="Geolocation"; "MapsBroker"="Downloaded Maps Manager" }
    "Telephony & Mobile"   = [ordered]@{ "PhoneSvc"="Phone Service"; "TapiSrv"="Telephony"; "icssvc"="Windows Mobile Hotspot" }
    "Parental & Account"   = [ordered]@{ "WpcMonSvc"="Parental Controls"; "EntAppSvc"="Enterprise App Management"; "RetailDemo"="Retail Demo" }
    "Media & Notifications"= [ordered]@{ "WMPNetworkSvc"="Windows Media Player Network Sharing"; "WpnService"="Windows Push Notifications" }
    "Windows Search"       = [ordered]@{ "WSearch"="Windows Search" }
    "Performance & Memory" = [ordered]@{ "SysMain"="SysMain / Superfetch"; "DusmSvc"="Data Usage Subscription"; "UevAgentService"="UE-V Virtualization Agent" }
    "File System & Misc"   = [ordered]@{ "CscService"="Offline Files"; "TrkWks"="Distributed Link Tracking Client"; "Fax"="Fax"; "tzautoupdate"="Auto Time Zone Updater" }
}

$Services=[ordered]@{}
foreach($cat in $ServiceCategories.Keys){foreach($svc in $ServiceCategories[$cat].Keys){if(-not $Services.Contains($svc)){$Services[$svc]=$ServiceCategories[$cat][$svc]}}}

$BackupDir=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "WinOptimizer_Backups"
$Script:RichBox=$null; $Script:Opaque=$true

function wc{param([string]$t,[System.Drawing.Color]$c,[bool]$nl=$true)
    $Script:RichBox.SelectionStart=$Script:RichBox.TextLength;$Script:RichBox.SelectionLength=0;$Script:RichBox.SelectionColor=$c
    if($nl){$Script:RichBox.AppendText("$t`r`n")}else{$Script:RichBox.AppendText($t)}
    $Script:RichBox.ScrollToCaret();$Script:RichBox.Refresh()}
function wBlk  { wc "" $CGray }
function wSep  { wc ([string][char]0x2500 * 96) $CDim }
function wTitle{ param($m) wBlk; wc "  $m" $CWhite; wBlk }
function wInfo { param($m) wc "  $m" $CGray }
function wOK   { param($m) wc "  $m" $CGreen }
function wWarn { param($m) wc "  $m" $CYellow }
function wErr  { param($m) wc "  $m" $CRed }
function wLabel{ param($k,$v,[System.Drawing.Color]$vc=$CWhite)
    wc "  $($k.PadRight(10))" $CGray $false; wc $v $vc }

function Write-Description {
    wBlk
    wc "  About" $CWhite; wBlk
    wc "  Disables unnecessary Windows services to improve performance, latency and resource usage." $CGray
    wc "  Safe, easy to use, effective and reversible with one click." $CGray; wBlk
    wc "  Designed for gaming, competitive and performance-focused low latency setups." $CGray
    wc "  Disabling these services frees up CPU, RAM, etc. and reduces system" $CGray
    wc "  latency by removing unnecessary background processes you don't need." $CGray; wBlk
    wc "  A backup is created automatically before any modification." $CDim
    wc "  It can be restored at any time via Revert Optimization." $CDim
    wc "  Results may vary depending on your Windows Services configuration." $CDim
    wBlk
    wc "  For personal use only. Modifying, copying, or redistributing this script is prohibited." $CRed
    wc "  This script must be downloaded only from the official source: https://github.com/insovs" $CGray
    wBlk; wSep; wBlk
}

function New-Backup{
    $out=Join-Path $BackupDir "Backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').reg"
    if(-not(Test-Path $BackupDir)){New-Item -ItemType Directory -Path $BackupDir -Force|Out-Null}
    $lines=@("Windows Registry Editor Version 5.00","")
    foreach($svc in $Services.Keys){
        $q=reg query "HKLM\SYSTEM\CurrentControlSet\Services\$svc" /v Start 2>$null
        if($q){$m=$q|Select-String "Start\s+REG_DWORD\s+0x([0-9a-fA-F]+)"
            if($m){$d=[uint32]("0x"+$m.Matches[0].Groups[1].Value)
                $lines+="[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$svc]"
                $lines+="`"Start`"=dword:$($d.ToString('x8'))";$lines+=""}}
    }
    $lines|Set-Content -Path $out -Encoding Unicode;return $out}

function Show-ServiceSelector {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text="Select categories to disable"; $dlg.Size=New-Object System.Drawing.Size(620,620)
    $dlg.StartPosition="CenterParent"; $dlg.BackColor=$SidebarBG; $dlg.ForeColor=$TextWhite
    $dlg.FormBorderStyle="None"; $dlg.MaximizeBox=$false; $dlg.MinimizeBox=$false

    $drag={if($_.Button -eq [System.Windows.Forms.MouseButtons]::Left){[Win32]::ReleaseCapture()|Out-Null;[Win32]::SendMessage($dlg.Handle,0xA1,0x2,0)|Out-Null}}
    $dlgBar=New-Object System.Windows.Forms.Panel;$dlgBar.Location=New-Object System.Drawing.Point(0,0);$dlgBar.Size=New-Object System.Drawing.Size(620,36);$dlgBar.BackColor=RGB 10 10 10;$dlgBar.Add_MouseDown($drag)
    $dlgBarTitle=New-Object System.Windows.Forms.Label;$dlgBarTitle.Text="";$dlgBarTitle.Location=New-Object System.Drawing.Point(12,10);$dlgBarTitle.Size=New-Object System.Drawing.Size(400,16);$dlgBarTitle.ForeColor=$TextMuted;$dlgBarTitle.Font=New-Object System.Drawing.Font("Consolas",8);$dlgBarTitle.Add_MouseDown($drag)
    $dlgClose=New-Object System.Windows.Forms.Panel;$dlgClose.Size=New-Object System.Drawing.Size(13,13);$dlgClose.Location=New-Object System.Drawing.Point(595,12);$dlgClose.BackColor=$DotRed;$dlgClose.Cursor=[System.Windows.Forms.Cursors]::Hand
    $dlgClose.Add_Paint({param($s,$e);$e.Graphics.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias;$b=New-Object System.Drawing.SolidBrush($s.BackColor);$e.Graphics.FillEllipse($b,0,0,$s.Width-1,$s.Height-1);$b.Dispose()})
    $dlgClose.Add_Click({$dlg.DialogResult=[System.Windows.Forms.DialogResult]::Cancel;$dlg.Close()})
    $dlgBar.Controls.AddRange(@($dlgBarTitle,$dlgClose));$dlg.Controls.Add($dlgBar)
    $hdr=New-Object System.Windows.Forms.Label;$hdr.Text="Select categories to disable";$hdr.Location=New-Object System.Drawing.Point(16,50);$hdr.Size=New-Object System.Drawing.Size(580,18);$hdr.ForeColor=$TextHead;$hdr.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $sub=New-Object System.Windows.Forms.Label;$sub.Text="Uncheck categories/services you want to keep active (e.g. Bluetooth, Printing, etc..)";$sub.Location=New-Object System.Drawing.Point(16,70);$sub.Size=New-Object System.Drawing.Size(580,16);$sub.ForeColor=$TextMuted;$sub.Font=New-Object System.Drawing.Font("Consolas",8)

    $scrollOuter=New-Object System.Windows.Forms.Panel;$scrollOuter.Location=New-Object System.Drawing.Point(12,106);$scrollOuter.Size=New-Object System.Drawing.Size(590,432);$scrollOuter.BackColor=$BG;$scrollOuter.BorderStyle="None"
    $scroll=New-Object System.Windows.Forms.Panel;$scroll.Location=New-Object System.Drawing.Point(0,0);$scroll.Size=New-Object System.Drawing.Size(567,100);$scroll.BackColor=$BG;$scroll.AutoSize=$false
    $vbar=New-Object System.Windows.Forms.VScrollBar;$vbar.Location=New-Object System.Drawing.Point(573,0);$vbar.Size=New-Object System.Drawing.Size(17,432);$vbar.Minimum=0;$vbar.Maximum=1000;$vbar.SmallChange=30;$vbar.LargeChange=100;$vbar.BackColor=RGB 20 20 20
    $vbar.Add_Scroll({$scroll.Top=-$vbar.Value})
    $scrollOuter.Add_MouseWheel({$v=[Math]::Max($vbar.Minimum,[Math]::Min($vbar.Maximum-$vbar.LargeChange,$vbar.Value-[int]($_.Delta/120*30)));$vbar.Value=$v;$scroll.Top=-$v})
    $scrollOuter.Controls.AddRange(@($scroll,$vbar))

    $Script:CategoryChecks=@{}; $Script:ServiceChecks=@{}; $yPos=8

    foreach ($cat in $ServiceCategories.Keys) {
        $catChk = New-Object System.Windows.Forms.CheckBox
        $catChk.Text=$cat; $catChk.Location=New-Object System.Drawing.Point(8,$yPos)
        $catChk.Size=New-Object System.Drawing.Size(560,20); $catChk.Checked=$true
        $catChk.ForeColor=RGB 80 140 220; $catChk.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
        $catChk.BackColor=$BG; $catChk.FlatStyle="Standard"
        $Script:CategoryChecks[$cat]=$catChk
        $catName=$cat
        $catChk.Add_CheckedChanged({
            $checked=$Script:CategoryChecks[$catName].Checked
            foreach ($svcKey in $Script:ServiceChecks.Keys) {
                if ($svcKey.StartsWith("${catName}::")) {
                    $ck=$Script:ServiceChecks[$svcKey]
                    $ck.Checked=$checked; $ck.Enabled=$checked
                    $ck.ForeColor=if($checked){$CGray}else{RGB 38 38 42}
                    $ck.Refresh()
                }
            }
        })
        $scroll.Controls.Add($catChk); $yPos+=24
        $sep=New-Object System.Windows.Forms.Panel
        $sep.Location=New-Object System.Drawing.Point(8,$yPos); $sep.Size=New-Object System.Drawing.Size(560,1)
        $sep.BackColor=$SideEdgeC; $scroll.Controls.Add($sep); $yPos+=4
        foreach ($svc in $ServiceCategories[$cat].Keys) {
            $svcChk=New-Object System.Windows.Forms.CheckBox
            $svcChk.Text="  $($svc.PadRight(44)) $($ServiceCategories[$cat][$svc])"
            $svcChk.Location=New-Object System.Drawing.Point(22,$yPos); $svcChk.Size=New-Object System.Drawing.Size(555,17)
            $svcChk.Checked=$true; $svcChk.ForeColor=$CGray; $svcChk.Font=New-Object System.Drawing.Font("Consolas",8)
            $svcChk.BackColor=$BG; $svcChk.FlatStyle="Standard"
            $Script:ServiceChecks["${cat}::${svc}"]=$svcChk; $scroll.Controls.Add($svcChk); $yPos+=18
        }
        $yPos+=10
    }
    $scroll.Height=$yPos+10
    if ($scroll.Height -le $scrollOuter.Height){ $vbar.Visible=$false; $scroll.Width=580 }
    else { $vbar.Visible=$true; $vbar.Maximum=$scroll.Height-$scrollOuter.Height+$vbar.LargeChange }

    # Helper to make buttons
    function Mk-Btn($txt,$x,$w,$fc){
        $b=New-Object System.Windows.Forms.Button; $b.Text=$txt
        $b.Location=New-Object System.Drawing.Point($x,580); $b.Size=New-Object System.Drawing.Size($w,28)
        $b.BackColor=$BtnNormal; $b.ForeColor=$fc; $b.FlatStyle="Flat"; $b.FlatAppearance.BorderColor=$BtnBorder
        $b.Font=New-Object System.Drawing.Font("Consolas",8,[System.Drawing.FontStyle]::Bold); return $b
    }
    $bApply  = Mk-Btn "Apply"              12  100 $CGreen
    $bCancel = Mk-Btn "Cancel"             120 100 $TextMuted
    $bRec    = Mk-Btn "Apply Recommended"  228 160 $CYellow
    $bAll    = Mk-Btn "Select All"         400 90  $TextMuted
    $bNone   = Mk-Btn "Select None"        498 90  $TextMuted
    $bApply.DialogResult=[System.Windows.Forms.DialogResult]::OK
    $bCancel.DialogResult=[System.Windows.Forms.DialogResult]::Cancel

    $RecommendedKeep=@("Bluetooth","Printing","Sensors & Hardware","Smart Card","Windows Search")
    $selectAll={foreach($c in $Script:CategoryChecks.Values){$c.Checked=$true};foreach($c in $Script:ServiceChecks.Values){$c.Checked=$true;$c.Enabled=$true;$c.ForeColor=$CGray;$c.Refresh()}}
    $bAll.Add_Click($selectAll)
    $bNone.Add_Click({foreach($c in $Script:CategoryChecks.Values){$c.Checked=$false};foreach($c in $Script:ServiceChecks.Values){$c.Checked=$false;$c.Enabled=$false;$c.ForeColor=RGB 38 38 42;$c.Refresh()}})
    $bRec.Add_Click({&$selectAll;foreach($cat in $RecommendedKeep){if($Script:CategoryChecks.ContainsKey($cat)){$Script:CategoryChecks[$cat].Checked=$false}}})

    $dlg.Controls.AddRange(@($hdr,$sub,$scrollOuter,$bApply,$bCancel,$bAll,$bNone,$bRec))
    $dlg.AcceptButton=$bApply; $dlg.CancelButton=$bCancel
    return $dlg.ShowDialog()
}

function Do-Optimize {
    $result=Show-ServiceSelector
    if ($result -ne [System.Windows.Forms.DialogResult]::OK){ return }
    $selected=[ordered]@{}
    foreach ($key in $Script:ServiceChecks.Keys) {
        if ($Script:ServiceChecks[$key].Checked) {
            $parts=$key -split "::"; $cat=$parts[0]; $svc=$parts[1]
            if (-not $selected.Contains($svc)){ $selected[$svc]=$ServiceCategories[$cat][$svc] }
        }
    }
    if ($selected.Count -eq 0){ $Script:RichBox.Clear(); Write-Description; wWarn "No services selected."; return }
    $Script:RichBox.Clear(); Write-Description
    wTitle "Proceed Optimization"
    wInfo "Creating backup..."; wBlk
    try{ $bf=New-Backup; wLabel "backup" $bf $CGray }catch{ wErr "Backup failed: $_"; return }
    wBlk; wInfo "Disabling $($selected.Count) selected services"; wBlk
    $ok=0;$sk=0;$fa=0
    foreach ($svc in $selected.Keys) {
        $rp="HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
        if (-not (Test-Path $rp)){ wc "  skip      " $CDim $false; wc $svc $TextMuted; $sk++; continue }
        try {
            Set-ItemProperty -Path $rp -Name "Start" -Value 4 -Type DWord -Force -ErrorAction Stop
            wc "  disabled  " $CGreen $false; wc "$($svc.PadRight(40))" $CWhite $false; wc $selected[$svc] $CGray; $ok++
        } catch { wc "  failed    " $CRed $false; wc $svc $CWhite; $fa++ }
        [System.Windows.Forms.Application]::DoEvents()
    }
    $dp="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    if (-not (Test-Path $dp)){ New-Item -Path $dp -Force|Out-Null }
    Set-ItemProperty -Path $dp -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    wBlk; wSep; wBlk
    wc "  disabled  " $CGreen $false; wc "$ok services" $CWhite
    wc "  skipped   " $CGray  $false; wc "$sk not found on this system" $CGray
    if ($fa -gt 0){ wc "  failed    " $CRed $false; wc "$fa services" $CWhite }
    wBlk; wWarn "Reboot recommended to apply changes."; wSep
}

function Do-Revert {
    $Script:RichBox.Clear(); Write-Description
    wTitle "Revert Optimization"
    if (-not (Test-Path $BackupDir)){ wErr "No backup folder found."; return }
    $bfiles=Get-ChildItem -Path $BackupDir -Filter "*.reg"|Sort-Object LastWriteTime -Descending
    if ($bfiles.Count -eq 0){ wErr "No backup files found."; return }
    wInfo "Available backups"; wBlk; $i=1
    foreach ($b in $bfiles) {
        $age=(Get-Date)-$b.LastWriteTime
        $as=if($age.TotalMinutes -lt 60){"$([int]$age.TotalMinutes)m ago"}elseif($age.TotalHours -lt 24){"$([int]$age.TotalHours)h ago"}else{"$([int]$age.TotalDays)d ago"}
        wc "  [$i]  " $TextMuted $false; wc "$($b.Name.PadRight(46))" $CWhite $false; wc $as $CGray; $i++
    }
    wBlk
    $dlg=New-Object System.Windows.Forms.Form;$dlg.Text="Select Backup";$dlg.Size=New-Object System.Drawing.Size(500,165);$dlg.StartPosition="CenterParent";$dlg.BackColor=$SidebarBG;$dlg.ForeColor=$TextWhite;$dlg.FormBorderStyle="FixedDialog";$dlg.MaximizeBox=$false;$dlg.MinimizeBox=$false
    $lbl=New-Object System.Windows.Forms.Label;$lbl.Text="Select a backup to restore:";$lbl.Location=New-Object System.Drawing.Point(16,16);$lbl.Size=New-Object System.Drawing.Size(460,18);$lbl.ForeColor=$TextHead;$lbl.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $cb=New-Object System.Windows.Forms.ComboBox;$cb.Location=New-Object System.Drawing.Point(16,42);$cb.Size=New-Object System.Drawing.Size(462,24);$cb.BackColor=$BtnNormal;$cb.ForeColor=$TextWhite;$cb.Font=New-Object System.Drawing.Font("Consolas",9);$cb.DropDownStyle="DropDownList";foreach($b in $bfiles){$cb.Items.Add($b.Name)|Out-Null};$cb.SelectedIndex=0
    $bOK=New-Object System.Windows.Forms.Button;$bOK.Text="Restore";$bOK.Location=New-Object System.Drawing.Point(16,80);$bOK.Size=New-Object System.Drawing.Size(100,28);$bOK.BackColor=$BtnNormal;$bOK.ForeColor=$CGreen;$bOK.FlatStyle="Flat";$bOK.FlatAppearance.BorderColor=$BtnBorder;$bOK.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold);$bOK.DialogResult=[System.Windows.Forms.DialogResult]::OK
    $bCx=New-Object System.Windows.Forms.Button;$bCx.Text="Cancel";$bCx.Location=New-Object System.Drawing.Point(124,80);$bCx.Size=New-Object System.Drawing.Size(100,28);$bCx.BackColor=$BtnNormal;$bCx.ForeColor=$TextMuted;$bCx.FlatStyle="Flat";$bCx.FlatAppearance.BorderColor=$BtnBorder;$bCx.Font=New-Object System.Drawing.Font("Consolas",9);$bCx.DialogResult=[System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.AddRange(@($lbl,$cb,$bOK,$bCx));$dlg.AcceptButton=$bOK;$dlg.CancelButton=$bCx
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK){ wWarn "Cancelled."; return }
    $sel=$bfiles[$cb.SelectedIndex].FullName
    wInfo "Restoring  $($bfiles[$cb.SelectedIndex].Name)"
    $res=Start-Process "regedit.exe" -ArgumentList "/s `"$sel`"" -Wait -PassThru; wBlk
    if($res.ExitCode -eq 0){ wOK "Registry restored successfully."; wBlk; wWarn "Reboot recommended." }
    else{ wErr "regedit exited with code $($res.ExitCode)." }
    wSep
}

function Do-List {
    $Script:RichBox.Clear(); Write-Description
    wTitle "Service Status"
    wc "  $("service".PadRight(44))" $CDim $false; wc "  status      description" $CDim
    foreach ($cat in $ServiceCategories.Keys) {
        wBlk; wc "  [$cat]" $CBlue; wBlk
        foreach ($svc in $ServiceCategories[$cat].Keys) {
            $rp="HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
            $ex=Test-Path $rp
            $sv=if($ex){(Get-ItemProperty $rp -Name Start -ErrorAction SilentlyContinue).Start}else{$null}
            $status=if(-not $ex){"not found"}elseif($sv -eq 4){"disabled"}else{"active   "}
            $sc=if(-not $ex){$CDim}elseif($sv -eq 4){$CGreen}else{$CYellow}
            wc "  $($svc.PadRight(44))" $CWhite $false
            wc "  $($status.PadRight(10))" $sc $false
            wc "  $($ServiceCategories[$cat][$svc])" $CGray
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    wBlk; wSep; wInfo "$($Services.Count) services total."; wSep
}

$Form=New-Object System.Windows.Forms.Form;$Form.Text="Service Optimization";$Form.Size=New-Object System.Drawing.Size(980,680);$Form.MinimumSize=New-Object System.Drawing.Size(860,560);$Form.StartPosition="CenterScreen";$Form.BackColor=$BG;$Form.ForeColor=$TextWhite;$Form.FormBorderStyle="None"
$TitleBar=New-Object System.Windows.Forms.Panel;$TitleBar.Location=New-Object System.Drawing.Point(0,0);$TitleBar.Size=New-Object System.Drawing.Size(980,32);$TitleBar.BackColor=RGB 10 10 10;$TitleBar.Anchor="Top,Left,Right"
$TitleBar.Add_MouseDown({if($_.Button -eq [System.Windows.Forms.MouseButtons]::Left){[Win32]::ReleaseCapture()|Out-Null;[Win32]::SendMessage($Form.Handle,0xA1,0x2,0)|Out-Null}})

function Make-Dot {
    param([System.Drawing.Color]$col,[int]$x,[scriptblock]$action)
    $d=New-Object System.Windows.Forms.Panel; $d.Size=New-Object System.Drawing.Size(13,13)
    $d.Location=New-Object System.Drawing.Point($x,10); $d.BackColor=$col
    $d.Cursor=[System.Windows.Forms.Cursors]::Hand
    $d.Add_Paint({ param($s,$e); $e.Graphics.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias; $b=New-Object System.Drawing.SolidBrush($s.BackColor); $e.Graphics.FillEllipse($b,0,0,$s.Width-1,$s.Height-1); $b.Dispose() })
    $d.Add_Click($action); return $d
}
$DotClose=Make-Dot $DotRed    780 { $Form.Close() }
$DotMin  =Make-Dot $DotOrange 800 { $Form.WindowState="Minimized" }
$DotMax  =Make-Dot $DotWhite  820 { if($Form.WindowState -eq "Maximized"){$Form.WindowState="Normal"}else{$Form.WindowState="Maximized"} }

$OpacBtn=New-Object System.Windows.Forms.Button;$OpacBtn.Text="Opacity  ON / OFF";$OpacBtn.Size=New-Object System.Drawing.Size(128,22);$OpacBtn.Location=New-Object System.Drawing.Point(844,5);$OpacBtn.BackColor=$BtnNormal;$OpacBtn.ForeColor=$TextMuted;$OpacBtn.FlatStyle="Flat";$OpacBtn.FlatAppearance.BorderColor=$BtnBorder;$OpacBtn.Font=New-Object System.Drawing.Font("Consolas",7);$OpacBtn.Cursor=[System.Windows.Forms.Cursors]::Hand
$TitleBar.Controls.AddRange(@($DotClose,$DotMin,$DotMax,$OpacBtn))
$Form.Controls.Add($TitleBar)

$Sidebar=New-Object System.Windows.Forms.Panel;$Sidebar.Location=New-Object System.Drawing.Point(0,32);$Sidebar.Size=New-Object System.Drawing.Size(260,648);$Sidebar.BackColor=$SidebarBG;$Sidebar.Anchor="Top,Left,Bottom"
$SideEdge=New-Object System.Windows.Forms.Panel;$SideEdge.Location=New-Object System.Drawing.Point(259,32);$SideEdge.Size=New-Object System.Drawing.Size(1,648);$SideEdge.BackColor=$SideEdgeC;$SideEdge.Anchor="Top,Left,Bottom"
$LogoPanel=New-Object System.Windows.Forms.Panel;$LogoPanel.Location=New-Object System.Drawing.Point(0,0);$LogoPanel.Size=New-Object System.Drawing.Size(259,106);$LogoPanel.BackColor=$LogoBG
$LogoDiv=New-Object System.Windows.Forms.Panel;$LogoDiv.Location=New-Object System.Drawing.Point(0,105);$LogoDiv.Size=New-Object System.Drawing.Size(259,1);$LogoDiv.BackColor=$SideEdgeC
$TitleLbl=New-Object System.Windows.Forms.Label;$TitleLbl.Text="SERVICE`r`nOPTIMIZATION";$TitleLbl.Location=New-Object System.Drawing.Point(0,16);$TitleLbl.Size=New-Object System.Drawing.Size(259,54);$TitleLbl.TextAlign="MiddleCenter";$TitleLbl.ForeColor=$TextHead;$TitleLbl.Font=New-Object System.Drawing.Font("Consolas",13,[System.Drawing.FontStyle]::Bold)
$GHLbl=New-Object System.Windows.Forms.Label;$GHLbl.Text="github.com/insovs";$GHLbl.Location=New-Object System.Drawing.Point(0,72);$GHLbl.Size=New-Object System.Drawing.Size(259,20);$GHLbl.TextAlign="MiddleCenter";$GHLbl.ForeColor=$TextMuted;$GHLbl.Font=New-Object System.Drawing.Font("Consolas",8);$GHLbl.Cursor=[System.Windows.Forms.Cursors]::Hand
$GHLbl.Add_Click({[System.Diagnostics.Process]::Start("https://github.com/insovs")});$GHLbl.Add_MouseEnter({$GHLbl.ForeColor=$TextWhite});$GHLbl.Add_MouseLeave({$GHLbl.ForeColor=$TextMuted})
$LogoPanel.Controls.AddRange(@($TitleLbl,$GHLbl))
$SecDiv=New-Object System.Windows.Forms.Panel;$SecDiv.Location=New-Object System.Drawing.Point(0,106);$SecDiv.Size=New-Object System.Drawing.Size(259,1);$SecDiv.BackColor=$SideEdgeC
$SecLbl=New-Object System.Windows.Forms.Label;$SecLbl.Text="MAIN MENU";$SecLbl.Location=New-Object System.Drawing.Point(16,118);$SecLbl.Size=New-Object System.Drawing.Size(220,13);$SecLbl.ForeColor=$TextDim;$SecLbl.Font=New-Object System.Drawing.Font("Consolas",7,[System.Drawing.FontStyle]::Bold)

function Make-Btn {
    param([string]$Label,[string]$Icon,[int]$Y)
    $p=New-Object System.Windows.Forms.Panel
    $p.Location=New-Object System.Drawing.Point(12,$Y); $p.Size=New-Object System.Drawing.Size(236,42)
    $p.BackColor=$BtnNormal; $p.Cursor=[System.Windows.Forms.Cursors]::Hand
    $strip=New-Object System.Windows.Forms.Panel
    $strip.Location=New-Object System.Drawing.Point(0,0); $strip.Size=New-Object System.Drawing.Size(2,42); $strip.BackColor=$BtnBorder
    $ico=New-Object System.Windows.Forms.Label
    $ico.Text=$Icon; $ico.Location=New-Object System.Drawing.Point(14,12)
    $ico.Size=New-Object System.Drawing.Size(18,18); $ico.ForeColor=$TextMuted
    $ico.Font=New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Bold)
    $txt=New-Object System.Windows.Forms.Label
    $txt.Text=$Label; $txt.Location=New-Object System.Drawing.Point(36,13)
    $txt.Size=New-Object System.Drawing.Size(194,16); $txt.ForeColor=$TextWhite
    $txt.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $txt.Cursor=[System.Windows.Forms.Cursors]::Hand
    $p.Controls.AddRange(@($strip,$ico,$txt))
    $hIn={ $p.BackColor=$BtnHover;$strip.BackColor=$BtnBorderH;$txt.ForeColor=$TextHead;$ico.ForeColor=$TextWhite }
    $hOut={ $p.BackColor=$BtnNormal;$strip.BackColor=$BtnBorder;$txt.ForeColor=$TextWhite;$ico.ForeColor=$TextMuted }
    foreach($c in @($p,$ico,$txt)){$c.Add_MouseEnter($hIn);$c.Add_MouseLeave($hOut)}
    return $p
}
$BtnOpt=Make-Btn "Proceed Optimization" ">" 136
$BtnRev=Make-Btn "Revert Optimization"  "<" 188
$BtnLst=Make-Btn "Show Service List"    "i" 240

$SuppDiv=New-Object System.Windows.Forms.Panel;$SuppDiv.Location=New-Object System.Drawing.Point(0,300);$SuppDiv.Size=New-Object System.Drawing.Size(259,1);$SuppDiv.BackColor=$SideEdgeC
$SuppLbl=New-Object System.Windows.Forms.Label;$SuppLbl.Text="SUPPORT";$SuppLbl.Location=New-Object System.Drawing.Point(16,314);$SuppLbl.Size=New-Object System.Drawing.Size(220,13);$SuppLbl.ForeColor=$TextDim;$SuppLbl.Font=New-Object System.Drawing.Font("Consolas",7,[System.Drawing.FontStyle]::Bold)
$SuppText=New-Object System.Windows.Forms.Label;$SuppText.Location=New-Object System.Drawing.Point(16,332);$SuppText.Size=New-Object System.Drawing.Size(228,30);$SuppText.ForeColor=$TextMuted;$SuppText.Font=New-Object System.Drawing.Font("Segoe UI",8);$SuppText.Text="Need help or have questions ?"
$DiscordBtn=New-Object System.Windows.Forms.Panel;$DiscordBtn.Location=New-Object System.Drawing.Point(12,368);$DiscordBtn.Size=New-Object System.Drawing.Size(236,36);$DiscordBtn.BackColor=$BtnNormal;$DiscordBtn.Cursor=[System.Windows.Forms.Cursors]::Hand
$DiscordStrip=New-Object System.Windows.Forms.Panel;$DiscordStrip.Location=New-Object System.Drawing.Point(0,0);$DiscordStrip.Size=New-Object System.Drawing.Size(2,36);$DiscordStrip.BackColor=$DiscordC
$DiscordIco=New-Object System.Windows.Forms.Label;$DiscordIco.Location=New-Object System.Drawing.Point(14,9);$DiscordIco.Size=New-Object System.Drawing.Size(18,18);$DiscordIco.ForeColor=$DiscordC;$DiscordIco.Font=New-Object System.Drawing.Font("Consolas",10,[System.Drawing.FontStyle]::Bold)
$DiscordTxt=New-Object System.Windows.Forms.Label;$DiscordTxt.Text="Join Discord Server";$DiscordTxt.Location=New-Object System.Drawing.Point(36,10);$DiscordTxt.Size=New-Object System.Drawing.Size(194,16);$DiscordTxt.ForeColor=$TextWhite;$DiscordTxt.Font=New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold);$DiscordTxt.Cursor=[System.Windows.Forms.Cursors]::Hand
$DiscordBtn.Controls.AddRange(@($DiscordStrip,$DiscordIco,$DiscordTxt))
$dHIn={$DiscordBtn.BackColor=$BtnHover;$DiscordStrip.BackColor=RGB 130 150 230;$DiscordTxt.ForeColor=$TextHead;$DiscordIco.ForeColor=RGB 160 175 240}
$dHOut={$DiscordBtn.BackColor=$BtnNormal;$DiscordStrip.BackColor=$DiscordC;$DiscordTxt.ForeColor=$TextWhite;$DiscordIco.ForeColor=$DiscordC}
foreach($c in @($DiscordBtn,$DiscordIco,$DiscordTxt)){$c.Add_MouseEnter($dHIn);$c.Add_MouseLeave($dHOut);$c.Add_Click({[System.Diagnostics.Process]::Start("https://discord.gg/insovs")})}
$VerLbl=New-Object System.Windows.Forms.Label;$VerLbl.Text="v2.0  |  Administrator";$VerLbl.Location=New-Object System.Drawing.Point(0,618);$VerLbl.Size=New-Object System.Drawing.Size(259,22);$VerLbl.TextAlign="MiddleCenter";$VerLbl.ForeColor=$TextDim;$VerLbl.Font=New-Object System.Drawing.Font("Consolas",7);$VerLbl.Anchor="Bottom,Left"

$Sidebar.Controls.AddRange(@($LogoPanel,$LogoDiv,$SecDiv,$SecLbl,$BtnOpt,$BtnRev,$BtnLst,$SuppDiv,$SuppLbl,$SuppText,$DiscordBtn,$VerLbl))

$Right=New-Object System.Windows.Forms.Panel;$Right.Location=New-Object System.Drawing.Point(260,32);$Right.Size=New-Object System.Drawing.Size(720,648);$Right.BackColor=$ConsoleBG;$Right.Anchor="Top,Left,Right,Bottom"
$RTB=New-Object System.Windows.Forms.RichTextBox;$RTB.Location=New-Object System.Drawing.Point(0,0);$RTB.Size=New-Object System.Drawing.Size(720,648);$RTB.BackColor=$ConsoleBG;$RTB.ForeColor=$CWhite;$RTB.Font=New-Object System.Drawing.Font("Consolas",9);$RTB.ReadOnly=$true;$RTB.BorderStyle="None";$RTB.ScrollBars="Vertical";$RTB.WordWrap=$false;$RTB.Anchor="Top,Left,Right,Bottom"
$Right.Controls.Add($RTB);$Script:RichBox=$RTB

$OpacBtn.Add_Click({
    if($Script:Opaque){$Form.Opacity=0.98;$Script:Opaque=$false}else{$Form.Opacity=1.0;$Script:Opaque=$true}
})
$Form.Controls.AddRange(@($Sidebar,$SideEdge,$Right))
$Form.Add_Resize({
    $w=$Form.ClientSize.Width; $h=$Form.ClientSize.Height
    $TitleBar.Width=$w; $OpacBtn.Left=$w-136
    $DotClose.Left=$w-200; $DotMin.Left=$w-180; $DotMax.Left=$w-160
    $Sidebar.Height=$h-32; $SideEdge.Height=$h-32; $VerLbl.Top=$h-32-26
    $Right.Width=$w-260; $Right.Height=$h-32; $RTB.Width=$w-260; $RTB.Height=$h-32
})

foreach($c in $BtnOpt.Controls){$c.Add_Click({Do-Optimize})};$BtnOpt.Add_Click({Do-Optimize})
foreach($c in $BtnRev.Controls){$c.Add_Click({Do-Revert})};$BtnRev.Add_Click({Do-Revert})
foreach($c in $BtnLst.Controls){$c.Add_Click({Do-List})};$BtnLst.Add_Click({Do-List})

$Form.Add_Shown({ Write-Description })
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($Form)
