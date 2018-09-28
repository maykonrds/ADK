New-Item -ItemType Directory -Path C:\WindowsISO
New-Item -ItemType Directory -Path C:\WindowsISO\ISOResult
New-Item -ItemType Directory -Path C:\WindowsISO\UnattendXML2016

#Modify user parameters as needed.
$SourceWindowsIsoPath = 'C:\WindowsISO\ISOSource\Windows_Server_2016.ISO'
$AutoUnattendXmlPath = 'C:\WindowsISO\UnattendXML2016\autounattend.xml'

Remove-Item -Recurse -Force 'C:\WindowsISO\Temp2016'

New-Item -ItemType Directory -Path C:\WindowsISO\Temp2016
New-Item -ItemType Directory -Path C:\WindowsISO\Temp2016\WorkingFolder
New-Item -ItemType Directory -Path C:\WindowsISO\Temp2016\MountDISM

#Prepare path for the Windows ISO destination file
$SourceWindowsIsoFullName = $SourceWindowsIsoPath.split("\")[-1]
$DestinationWindowsIsoPath = 'C:\WindowsISO\ISOResult\' +  ($SourceWindowsIsoFullName -replace ".iso","") + '-CUSTOM.ISO'

# mount the source Windows iso.
$MountSourceWindowsIso = mount-diskimage -imagepath $SourceWindowsIsoPath -passthru
# get the drive letter assigned to the iso.
$DriveSourceWindowsIso = ($MountSourceWindowsIso | get-volume).driveletter + ':'

# Copy the content of the Source Windows Iso to a Working Folder
copy-item $DriveSourceWindowsIso\* -Destination 'C:\WindowsISO\Temp2016\WorkingFolder' -force -recurse

# remove the read-only attribtue from the extracted files.
get-childitem 'C:\WindowsISO\Temp2016\WorkingFolder' -recurse | %{ if (! $_.psiscontainer) { $_.isreadonly = $false } }

#Optional check all Image Index for boot.wim
Get-WindowsImage -ImagePath 'C:\WindowsISO\Temp2016\WorkingFolder\sources\boot.wim'

#Optional check all Image Index for install.wim
Get-WindowsImage -ImagePath 'C:\WindowsISO\Temp2016\WorkingFolder\sources\install.wim'

copy-item $AutoUnattendXmlPath -Destination 'C:\WindowsISO\Temp2016\WorkingFolder\autounattend.xml'

#Now copy the content of the working folder in the new custom windows ISO.

$OcsdimgPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg'
$oscdimg  = "$OcsdimgPath\oscdimg.exe"
$etfsboot = "$OcsdimgPath\etfsboot.com"
$efisys   = "$OcsdimgPath\efisys.bin"

$data = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f $etfsboot, $efisys
start-process $oscdimg -args @("-bootdata:$data",'-u2','-udfver102', 'C:\WindowsISO\Temp2016\WorkingFolder', $DestinationWindowsIsoPath) -wait -nonewwindow
