# Port Checker

A powerful utility for monitoring and managing active network ports with an interactive command-line interface.

![Port Checker Screenshot](https://i.imgur.com/YourScreenshot.png)

## Description

Port Checker is a command-line tool that helps you view and manage listening network ports on your system. It provides a user-friendly interface with colored output and various command options for identifying and killing processes running on specific ports.

This tool is particularly useful for:
- Developers running multiple services and needing to free up ports
- System administrators monitoring network services
- Troubleshooting port conflicts between applications
- Quickly identifying what process is running on a specific port

## Features

- **Interactive Command Interface**: Easy-to-use command prompt with help system
- **Color-Coded Output**: Clear visual presentation of information
- **Detailed Port Information**: View comprehensive details about listening ports
- **Flexible Port Selection**: Target individual ports, port ranges, or all ports
- **Exception Handling**: Exclude specific ports from operations
- **Cross-Platform Support**: Available for both Linux (Bash) and Windows (Batch)

## Installation

### Linux (Bash)

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/port-checker.git
   cd port-checker
   ```

2. Make the script executable:
   ```bash
   chmod +x port_checker.sh
   ```

3. Run the script:
   ```bash
   ./port_checker.sh
   ```

#### Dependencies

- `lsof`: For listing open files and ports
- `ps`: For process information
- `pstree` (optional): For displaying process trees
- `netstat`: For network statistics

Install these dependencies using your package manager if not already installed:
```bash
sudo apt-get install lsof psmisc net-tools   # Debian/Ubuntu
sudo yum install lsof psmisc net-tools       # CentOS/RHEL
```

### Windows (Batch)

1. Clone the repository:
   ```cmd
   git clone https://github.com/yourusername/port-checker.git
   cd port-checker
   ```

2. Run the batch script:
   ```cmd
   port_checker.bat
   ```

#### Dependencies

- Windows 10 or later (for ANSI color support)
- Administrative privileges (required for killing processes)

## Usage

### Basic Commands

Once the script is running, you'll see a prompt where you can enter commands:

```
-> $
```

Available commands:

- `r` or `reface` - Reload/refresh port list
- `h` or `help` - Display help information
- `exit`, `quit`, `q`, or `e` - Exit the program

### Port Operations

#### Viewing Port Details

```
-> $ fd -p 1         # Show details for port #1 in the list
-> $ fd -p 1,2,3     # Show details for ports #1, #2, and #3
-> $ fd -p 1-5       # Show details for ports #1 through #5
-> $ fd -a           # Show details for all ports
-> $ fd -a -e 2,3    # Show details for all ports except #2 and #3
```

You can also use `full-detail` instead of `fd`.

#### Killing Processes on Ports

```
-> $ kill -p 1         # Kill process on port #1
-> $ kill -p 1,2,3     # Kill processes on ports #1, #2, and #3
-> $ kill -p 1-5       # Kill processes on ports #1 through #5
-> $ kill -a           # Kill processes on all ports
-> $ kill -a -e 2,3    # Kill processes on all ports except #2 and #3
```

## Command Reference

### Kill Command

```
kill -p PORT_SPEC [-e EXCEPT_SPEC] [-a]
```

Parameters:
- `-p, --port`: Specify ports to kill (required unless -a is used)
- `-e, --except`: Specify ports to exclude
- `-a, --all`: Kill all ports

Examples:
- `kill -p 1` - Kill port number 1
- `kill -p 1,5,7` - Kill ports 1, 5, and 7
- `kill -a` - Kill all ports
- `kill -p -a` - Also kills all ports (same as kill -a)
- `kill -p 1-5` - Kill ports 1 through 5
- `kill -p 1-10 -e 5,8,9` - Kill ports 1-10 except 5,8,9
- `kill -a -e 2-5` - Kill all ports except 2 through 5

### Full-Detail Command

```
fd -p PORT_SPEC [-e EXCEPT_SPEC] [-a]
```
or
```
full-detail -p PORT_SPEC [-e EXCEPT_SPEC] [-a]
```

Parameters:
- `-p, --port`: Specify ports to show details (required unless -a is used)
- `-e, --except`: Specify ports to exclude
- `-a, --all`: Show all ports

Examples:
- `fd -p 1` - Show full details of port 1
- `fd -a` - Show full details of all ports
- `full-detail -p 1-3` - Show details for ports 1 through 3

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

- **ausa** - *Initial work*

## Acknowledgments

- Inspired by the need for a simpler way to manage ports during development
- Thanks to all the contributors who have helped improve this tool
