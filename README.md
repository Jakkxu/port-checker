# Port Checker

- [Description](#description)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Implementation Details](#implementation-details)
- [Requirements](#requirements)

## Description

Port Checker is a user-friendly utility designed to help you view all listening ports on your system and manage the processes associated with them. It provides a colorful terminal interface with various command options for both Windows and Linux/Unix environments.

## Features

- **View Active Ports**: Lists all active listening ports with their associated processes, protocol type (TCP/UDP), and highlighted important ports
- **Dual Selection Modes**: Select ports by index (position in list) or by actual port number
- **Detailed Port Information**: Shows comprehensive details about specified ports including process data and network connections
- **Process Termination**: Easily kill processes running on specific ports
- **Flexible Port Selection**: Select ports individually, in ranges, as comma-separated lists, or all ports with exceptions
- **Important Port Highlighting**: Automatically highlights critical ports (SSH:22, HTTP:80, HTTPS:443, MySQL:3306, PostgreSQL:5432, etc.) in red

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
| `d` or `detail` | Show detailed information about specified ports |
| `exit`, `quit`, `q`, or `e` | Exit the program |

### Options

For both the `kill` and `d`/`detail` commands, you can use either:

| Option | Description |
|--------|-------------|
| `-i, --index INDEX_SPEC` | Specify ports by their index in the list (1, 2, 3, etc.) |
| `-p, --port PORT_SPEC` | Specify ports by their actual port number (8000, 9000, etc.) |
| `-e, --except SPEC` | Specify ports to exclude from the operation |
| `-a, --all` | Select all ports (use with `-i` or `-p`) |

### SPEC Format

Both INDEX_SPEC and PORT_SPEC parameters can be specified in several formats:

- Single value: `1` or `8000`
- Comma-separated list: `1,5,7` or `80,443,8080`
- Range: `1-5` or `8000-9000`

### Examples

#### Using Index (-i option)

```
kill -i 1             # Kill port at index 1
kill -i 1,5,7         # Kill ports at indices 1, 5, and 7
kill -i 1-5           # Kill ports at indices 1 through 5
kill -i -a            # Kill all ports (by index)

d -i 1                # Show details of port at index 1
detail -i 1-3         # Show details for ports at indices 1 through 3
detail -i -a          # Show details of all ports
```

#### Using Port Number (-p option)

```
kill -p 8000          # Kill port 8000
kill -p 8000,9000,8080       # Kill ports 8000, 9000, and 8080
kill -p 8000-9000     # Kill ports 8000 through 9000
kill -p 8000-9000 -e 8080,8700    # Kill ports 8000-9000 except 8080 and 8700
kill -p 8000-9000 -e 8080-8500    # Kill ports 8000-9000 except 8080-8500
kill -p -a            # Kill all ports (by port number)
kill -p -a -e 8080-8500    # Kill all ports except 8080-8500

d -p 8000             # Show details of port 8000
d -p 80,443           # Show details of ports 80 and 443
detail -p 8000-9000   # Show details for ports 8000 through 9000
detail -p -a          # Show details of all ports
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
