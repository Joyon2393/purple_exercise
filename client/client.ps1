# Define the server's IP address and port
$SERVER_HOST = "192.168.56.109"  # Replace with your IP address
$SERVER_PORT = 9001

# Create TCP listener object
$TcpListener = [System.Net.Sockets.TcpListener]::new($SERVER_HOST, $SERVER_PORT)

# Start listening for incoming connections
$TcpListener.Start()
Write-Host "[*] Listening on $SERVER_HOST:$SERVER_PORT"

# Accept incoming client connection
$TcpClient = $TcpListener.AcceptTcpClient()
$NetworkStream = $TcpClient.GetStream()
$StreamWriter = [System.IO.StreamWriter]::new($NetworkStream)

# Function to send command and output to client
function Send-Command {
    param (
        [string]$Command
    )
    $StreamWriter.WriteLine($Command)
    $StreamWriter.WriteLine("SHELL>")
    $StreamWriter.Flush()
}

# Main loop to send commands and receive output
while ($true) {
    # Read command from user input
    $command = Read-Host "Enter command to execute (or 'exit' to quit):"
    if ($command -eq "exit") {
        break
    }

    # Send command to client
    Send-Command -Command $command

    # Wait for client to execute command and send output
    $output = $NetworkStream.ReadLine()
    Write-Host "[Client Output]: $output"
}

# Close connection
$TcpClient.Close()
$TcpListener.Stop()
