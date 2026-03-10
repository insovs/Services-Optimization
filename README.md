# insopti ServiceOptimization

Disables unnecessary **Windows background services** to improve performance, reduce CPU/RAM usage and lower system latency.  
Designed for **gaming, competitive and performance-focused** setups. Everything is **safe**, **effective**, and **fully reversible with one click**.

> [!NOTE]
> A backup of your current service configuration is **automatically created** before any change is made. You can restore it at any time via the **Revert Optimization** button.

## Preview
![Proceed Optimization](https://imgur.com/rn70v3j.png)

<details>
  <summary>Click to show more screenshots</summary>

**Revert Optimization** — backup selection and restore  
![Revert Optimization](https://imgur.com/GpLiM9G.png)

**Show Service List** — live status of all tracked services  
![Show Service List](https://imgur.com/KYVltbi.png)

**Result** of a lightweight Windows without too much effort
![Task Manager result](https://imgur.com/lEdrvYW.png)

</details>

## Support
If you need any help or have questions, feel free to join the **[Discord support server](https://discord.gg/insovs)** — I'll be happy to assist you.

## Installation & Launch
Head to the **[Releases](https://github.com/insovs/insopti-ServiceOptimization/releases)** section and download `ServiceOptimization.ps1`, then **right-click** it → **"Run with PowerShell"**.  
The script will automatically request administrator privileges and open a dark GUI.

> [!CAUTION]
> If you are not allowed to run PowerShell scripts, enable it first:
> ```
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> or refer to [EnablePowerShellScript](https://github.com/insovs/EnablePowerShellScript).

## How to use

| Button | Description |
|---|---|
| **Proceed Optimization** | Opens the category selector — choose which services to disable, then click Apply |
| **Revert Optimization** | Restores a previous backup via registry import |
| **Show Service List** | Displays all tracked services with their current status (disabled / active / not found) |

> [!IMPORTANT]
> After running the optimization, a **reboot is recommended** to fully apply the changes.

## Service categories

| Category | Services targeted |
|---|---|
| **Telemetry & Diagnostics** | DiagTrack, WerSvc, DPS, PcaSvc, GraphicsPerfSvc, and more |
| **Windows Update & Edge** | Delivery Optimization, Microsoft Edge Update |
| **Remote Access & Network** | RemoteRegistry, WinRM, RasAuto, SSDP, UPnP, and more |
| **Xbox & Gaming DVR** | XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc |
| **Hyper-V** | All vmic* integration services, HvHost |
| **Bluetooth** | BthAvctpSvc, SEMgrSvc |
| **Printing** | Spooler, PrintNotify |
| **Sensors & Hardware** | SensrSvc, FrameServer, TabletInputService, WbioSrvc |
| **Smart Card** | ScDeviceEnum, SCPolicySvc, CertPropSvc |
| **Location & Maps** | lfsvc, MapsBroker |
| **Telephony & Mobile** | PhoneSvc, TapiSrv, icssvc |
| **Parental & Account** | WpcMonSvc, EntAppSvc, RetailDemo |
| **Media & Notifications** | WMPNetworkSvc, WpnService |
| **Windows Search** | WSearch |
| **Performance & Memory** | SysMain, DusmSvc, UevAgentService |
| **File System & Misc** | CscService, TrkWks, Fax, tzautoupdate |

> [!IMPORTANT]
> The **Apply Recommended** button selects everything except: Bluetooth, Printing, Sensors & Hardware, Smart Card, and Windows Search — categories that may affect hardware functionality for some users. If you don't use these, you can disable them manually.

## What the script does

| Action | Detail |
|---|---|
| **Backup creation** | Saves current `Start` registry values for all tracked services to a `.reg` file |
| **Service disabling** | Sets `Start=4` (disabled) in the registry for each selected service |
| **Delivery Optimization** | Sets `DODownloadMode=0` via group policy to disable peer-to-peer update sharing |
| **Revert** | Runs `regedit /s` on a selected backup file to fully restore previous state |

## Revert / Restore

To undo all changes:
1. Open `ServiceOptimization.ps1` and click **Revert Optimization**.
2. Select the backup you want to restore from the list.
3. Click **Restore** — the registry is reimported silently.
4. **Reboot** to apply.

> [!NOTE]
> Backups are stored in a `WinOptimizer_Backups` folder next to the script, named with a timestamp.  
> Results may vary depending on your Windows Services configuration and installed hardware.  
> The script does not delete or modify any system files — only registry `Start` values are changed.

---

<p align="center">
  <sub>©insopti — <a href="https://guns.lol/inso.vs">guns.lol/inso.vs</a> | For personal use only.</sub>
</p>
