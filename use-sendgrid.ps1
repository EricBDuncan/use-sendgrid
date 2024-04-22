<#PSScriptInfo
.DESCRIPTION Script module for sending email with SendGrid and PowerShells send-MailMessage.
.VERSION 1.0
.GUID bcec630b-5f0e-4d64-a2ed-5b8e77b81a5a
.AUTHOR Eric Duncan
.COMPANYNAME kalyeri
.COPYRIGHT
MIT License

Copyright (c) 2024 Eric Duncan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
.LICENSEURI https://opensource.org/license/mit/

.PROJECTURI https://github.com/EricBDuncan/Use-SendGrid

.RELEASENOTES
	20240422 Public release.
#>
<#
.SYNOPSIS
 Script module for sending email with SendGrid and PowerShells send-MailMessage.

.DESCRIPTION
In your scripts, import as a module (Import-Module ..\use-SendGrid\use-SendGrid.ps1).
Set in your script or functions the following vars:
Required: 
$emailto="user1@abc.com","user2@efg.com"
$subject=""
$body=""
or
$body=@"
xyz
123
"@

Optional: 
$emailcc,$emailbcc,$attachments
BodyAsHtml=$true
send the message by calling the function name: email.

Enter your static from address and API key in the cfg.json file.

.PARAMETER cfgFile
Specify the configuration file. Default file is use-sendgrid.cfg.json.

.INPUTS
 None. You cannot pipe objects to this script.
 
.OUTPUTS
None.

.EXAMPLE
Import-Module ..\use-SendGrid\use-SendGrid.ps1
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $False)] [String] $cfgFile = ".\$(($MyInvocation.MyCommand.Name).replace(".ps1",'.cfg.json'))"
)

<# Load Config/VARIABLES #>
if (test-path $cfgFile)
	{
		$cfgIn=get-content $cfgFile -raw | convertfrom-json -ErrorAction Stop
		$cfg=@{}
		foreach ($setting in $cfgIn.PSObject.Properties)
			{
				$value=$setting.Value
				if ($value -is [System.Management.Automation.PSCustomObject]) {
					$value = ConvertTo-Hashtable -Object $value
					} elseif ($value -is [System.Array]) {
						$value = $value | ForEach-Object { ConvertTo-Hashtable -Object $_ }
					}
				$cfg[$setting.Name] = $value
				Set-Variable -Name $setting.Name -Value $Value -Scope Script
			}
	} ELSE {throw "Configuration file not found...; default filename is $cfgFile"; break}

#Init vars as arrays if not already set
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!($emailto)) {$emailto=@()}
if (!($emailcc)) {$emailcc=@()}
if (!($emailbcc)) {$emailbcc=@()}
if (!($attachments)) {$attachments=@()}

function email() {

#SendGrid API
$script:mailpass=[string]$apikey | ConvertTo-SecureString -AsPlainText -Force
[PSCredential]$APIcreds = New-Object System.Management.Automation.PSCredential -ArgumentList $APIUsername,$mailpass

if (!($emailto)) {$emailto=read-host "Please enter the To: email address"}
if (!($subject)) {$subject=read-host "Please enter the email subject"}
if (!($body)) {$body=read-host "Please enter the email body"}

$syntax=@{
	To=$emailto
	From=$FromEmail
	Subject="$subject"
	Body=$Body
	SmtpServer=$SmtpServer
	usessl=$true
	port=[int]$SmtpPort
	Credential=$APIcreds
	}

#Enable options if vars are set
if ($attachments) {$syntax.Add('attachments', $attachments)}
if ($BodyAsHtml) {$syntax.Add('BodyAsHtml', $true)}
if ($emailcc) {$syntax.Add('cc', $emailcc)}
if ($emailbcc) {$syntax.Add('bcc', $emailbcc)}

#Send email
if ($EmailTestMode) {"Email Test Mode Enabled: This would send an email to $($syntax.to)"} ELSE {Send-MailMessage @syntax}
}

