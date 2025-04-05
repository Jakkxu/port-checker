# Port Checker

A cross-platform command-line utility to monitor and manage network ports on your system.

![Port Checker Banner](https://img.shields.io/badge/Port%20Checker-Monitor%20%26%20Manage%20Ports-blue)

## Description

Port Checker is a user-friendly utility designed to help you view all listening ports on your system and manage the processes associated with them. It provides a colorful terminal interface with various command options for both Windows and Linux/Unix environments.

## Features

- **View Active Ports**: Lists all active listening ports with their associated processes
- **Detailed Port Information**: Shows comprehensive details about specified ports including process data and network connections
- **Process Termination**: Easily kill processes running on specific ports
- **Flexible Port Selection**: Select ports individually, in ranges, as comma-separated lists, or all ports with exceptions
- **Cross-Platform Support**: Works on both Windows and Linux/Unix systems

## Installation

### Windows
Simply download the `port_checker.bat` file and run it from the command prompt with administrator privileges.

### Linux/Unix
1. Download the `port_checker.sh` file
2. Make it executable: `chmod +x port_checker.sh`
3. Run it: `./port_checker.sh`

## Usage

### Commands

The tool supports the following commands:

| Command | Description |
|---------|-------------|
| `r` or `reface` | Refresh the port list |
| `h` or `help` | Display help information |
| `kill` | Kill processes on specified ports |
| `fd` or `full-detail` | Show detailed information about specified ports |
| `exit`, `quit`, `q`, or `e` | Exit the program |

### Options

For both the `kill` and `fd`/`full-detail` commands:

| Option | Description |
|--------|-------------|
| `-p, --port PORT_SPEC` | Specify ports to process (required unless -a is used) |
| `-e, --except PORT_SPEC` | Specify ports to exclude |
| `-a, --all` | Select all ports |

### PORT_SPEC Format

The PORT_SPEC parameter can be specified in several formats:

- Single port: `3000`
- Comma-separated list: `80,443,8080`
- Range: `3000-3005`

### Examples

```
kill -p 1             # Kill process on port number 1
kill -p 1,5,7         # Kill processes on ports 1, 5, and 7
kill -a               # Kill all port processes
kill -p 1-5           # Kill processes on ports 1 through 5
kill -p 1-10 -e 5,8,9 # Kill processes on ports 1-10 except 5, 8, and 9
kill -a -e 2-5        # Kill all port processes except ports 2 through 5

fd -p 1               # Show full details of port 1
fd -a                 # Show full details of all ports
full-detail -p 1-3    # Show details for ports 1 through 3
```

## Implementation Details

The implementation differs between platforms:

- **Windows**: Uses `netstat` and `tasklist` to gather port and process information
- **Linux/Unix**: Uses `lsof`, `ps`, and `netstat` for the same functionality

## Requirements

### Windows
- Windows 7 or newer
- Administrator privileges for killing processes

### Linux/Unix
- `lsof` utility (installed by default on most distributions)
- `netstat` utility (usually part of net-tools)
- Root privileges for killing certain processes (`sudo` may be required)

## License

This tool is free to use, modify and distribute.

## Contributing

Feel free to fork this project and submit pull requests for any improvements or bug fixes.
