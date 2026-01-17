#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

#####################################################################################
##                                                                                 ##
## DESCRIPTION:                                                                    ##
##   Port Checker - A comprehensive utility for viewing and managing active        ##
##   listening ports on your system. Kill processes by port number or index,       ##
##   view detailed port information, and manage network connections with ease.     ##
##   Provides a user-friendly interactive interface with colored output and        ##
##   full readline support for command history and editing.                        ##
##                                                                                 ##
## FUNCTIONS:                                                                      ##
##   display_header - Clears the screen and displays the ASCII art logo            ##
##   display_help - Shows all available commands and usage instructions            ##
##   check_ports - Lists all active listening ports with their metadata            ##
##   show_full_details - Shows comprehensive information about specified ports     ##
##   kill_ports_new - Terminates processes running on specified ports              ##
##   parse_command - Processes and validates user input commands                   ##
##   convert_port_to_indices - Converts port numbers to their list indices         ##
##   main_loop - Main entry point with readline history support                    ##
##                                                                                 ##
## NAVIGATION:                                                                     ##
##   Up/Down Arrows         Navigate through command history                       ##
##   Left/Right Arrows      Move cursor in command line                            ##
##   Ctrl+A / Ctrl+E        Jump to start/end of line                              ##
##   Alt+B / Alt+F          Move cursor by word                                    ##
##   Ctrl+D / Ctrl+H        Delete forward/backward                                ##
##                                                                                 ##
#####################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

display_header() {
    clear
    echo -e "${CYAN}"
    echo -e " ____            _      ____ _               _               _"
    echo -e "|  _ \ ___  _ __| |_   / ___| |__   ___  ___| | _____ _ __  | |"
    echo -e "| |_) / _ \| '__| __| | |   | '_ \ / _ \/ __| |/ / _ \ '__| |_|"
    echo -e "|  __/ (_) | |  | |_  | |___| | | |  __/ (__|   <  __/ |     _"
    echo -e "|_|   \___/|_|   \__|  \____|_| |_|\___|\___|_|\_\___|_|    |_|"
    echo -e "                                                            "
    echo -e "${NC}"
}

display_help() {
    display_header
    echo -e "${CYAN}=============== HELP ===============${NC}"
    echo -e "${YELLOW}Port Checker - Monitor and manage active network ports${NC}"
    echo -e "${YELLOW}This tool allows you to view all listening ports and kill processes by port number.${NC}"
    echo -e "${YELLOW}You can select individual ports, port ranges, or all ports with exceptions.${NC}"
    echo -e ""
    
    echo -e "${YELLOW}Available commands:${NC}"
    echo -e "  ${GREEN}kill${NC} - Kill ports with options"
    echo -e "    ${CYAN}-i, --index${NC} INDEX_SPEC - Specify ports by index to kill (required unless -a is used)"
    echo -e "    ${CYAN}-p, --port${NC} PORT_SPEC - Specify ports by port number to kill (required unless -a is used)"
    echo -e "    ${CYAN}-e, --except${NC} SPEC - Specify ports to exclude"
    echo -e "    ${CYAN}-a, --all${NC} - Kill all ports (use with -i or -p)"
    
    echo -e "  ${GREEN}d${NC} or ${GREEN}detail${NC} - Show full details of ports"
    echo -e "    ${CYAN}-i, --index${NC} INDEX_SPEC - Specify ports by index to show details (required unless -a is used)"
    echo -e "    ${CYAN}-p, --port${NC} PORT_SPEC - Specify ports by port number to show details (required unless -a is used)"
    echo -e "    ${CYAN}-e, --except${NC} SPEC - Specify ports to exclude"
    echo -e "    ${CYAN}-a, --all${NC} - Show all ports (use with -i or -p)"
    
    echo -e "  Examples:"
    echo -e "    ${GREEN}kill -i 1${NC} - Kill port at index 1"
    echo -e "    ${GREEN}kill -i 1,5,7${NC} - Kill ports at indices 1, 5, and 7"
    echo -e "    ${GREEN}kill -i 1-5${NC} - Kill ports at indices 1 through 5"
    echo -e "    ${GREEN}kill -i -a${NC} - Kill all ports (by index)"
    echo -e "    ${GREEN}kill -p 8000${NC} - Kill port 8000"
    echo -e "    ${GREEN}kill -p 8000,9000,8080${NC} - Kill ports 8000, 9000, and 8080"
    echo -e "    ${GREEN}kill -p 8000-9000${NC} - Kill ports 8000 through 9000"
    echo -e "    ${GREEN}kill -p 8000-9000 -e 8080,8700${NC} - Kill ports 8000-9000 except 8080,8700"
    echo -e "    ${GREEN}kill -p -a${NC} - Kill all ports (by port number)"
    echo -e "    ${GREEN}d -i 1${NC} - Show full details of port at index 1"
    echo -e "    ${GREEN}d -p 8000${NC} - Show full details of port 8000"
    echo -e "    ${GREEN}d -p -a${NC} - Show full details of all ports"
    echo -e ""
    echo -e "  ${GREEN}r${NC} or ${GREEN}reface${NC} - Reload/refresh port list"
    echo -e "  ${GREEN}h${NC} or ${GREEN}help${NC} - Display this help information"
    echo -e "  ${GREEN}exit${NC}, ${GREEN}quit${NC}, ${GREEN}q${NC}, or ${GREEN}e${NC} - Exit program"
    
    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
}

check_ports() {
    display_header
    # echo -e "${CYAN}======= CHECKING ACTIVE PORTS =======${NC}"
    ports=($(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -n | uniq))
    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${YELLOW}No active ports found.${NC}"
    else
        echo -e "ID   PORT     HOST       USER        PROCESS       PROTOCOL"
        echo -e "---------------------------------------------------------------"
        
        for i in "${!ports[@]}"; do
            port=${ports[$i]}
            lsof_info=$(lsof -i :$port -P -n 2>/dev/null | grep LISTEN | head -1)
            
            host=$(echo "$lsof_info" | awk '{print $9}' | cut -d':' -f1)
            user=$(echo "$lsof_info" | awk '{print $3}')
            pid=$(echo "$lsof_info" | awk '{print $2}')
            command=$(ps -p $pid -o comm= 2>/dev/null)
            
            protocol=$(ss -tuln 2>/dev/null | grep ":$port " | awk '{print $1}' | head -1)
            
            if [ -z "$protocol" ]; then
                protocol="-"
            else
                protocol=$(echo "$protocol" | tr '[:lower:]' '[:upper:]')
            fi

            if [ "$host" == "*" ]; then
                host="*"
            fi
            
            case "$port" in
                22|80|443|3306|5432|5900|8080|8443|27017|6379|3389)
                    printf "[%-1d] ${RED}%-8s${NC} %-10s %-12s %-14s %s\n" "$((i+1))" "$port" "$host" "$user" "$command" "$protocol"
                    ;;
                *)
                    printf "[%-1d] %-8s %-10s %-12s %-14s %s\n" "$((i+1))" "$port" "$host" "$user" "$command" "$protocol"
                    ;;
            esac
        done
    fi
    
    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
}

convert_port_to_indices() {
    local port_spec=$1
    shift
    local ports_array=("$@")
    local indices=()

    if [[ "$port_spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        start="${BASH_REMATCH[1]}"
        end="${BASH_REMATCH[2]}"
        for ((port=$start; port<=$end; port++)); do
            for i in "${!ports_array[@]}"; do
                if [ "${ports_array[$i]}" -eq "$port" ]; then
                    indices+=($((i+1)))
                    break
                fi
            done
        done
    elif [[ "$port_spec" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        IFS=',' read -ra port_list <<< "$port_spec"
        for port in "${port_list[@]}"; do
            for i in "${!ports_array[@]}"; do
                if [ "${ports_array[$i]}" -eq "$port" ]; then
                    indices+=($((i+1)))
                    break
                fi
            done
        done
    fi
    
    echo "${indices[@]}"
}

show_full_details() {
    local port_spec=$1
    local except_spec=$2

    display_header
    echo -e "${CYAN}=============== DETAILS ===============${NC}"

    ports=($(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -n | uniq))

    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${YELLOW}No active ports to show details.${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    echo -e "${CYAN}Found ${#ports[@]} active ports.${NC}"

    local indices_to_show=()
    local indices_to_except=()

    if [[ "$port_spec" == port:* ]]; then
        port_spec="${port_spec#port:}"
        indices_array=($(convert_port_to_indices "$port_spec" "${ports[@]}"))
        indices_to_show=("${indices_array[@]}")
    elif [ "$port_spec" == "all_port" ]; then
        echo -e "${CYAN}Processing all ports for details...${NC}"
        for i in "${!ports[@]}"; do
            indices_to_show+=($((i+1)))
        done
    elif [ "$port_spec" == "all_index" ]; then
        echo -e "${CYAN}Processing all ports for details...${NC}"
        for i in "${!ports[@]}"; do
            indices_to_show+=($((i+1)))
        done
    else
        if [[ "$port_spec" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            IFS=',' read -ra specified_indices <<< "$port_spec"
            for index in "${specified_indices[@]}"; do
                if [ "$index" -le "${#ports[@]}" ] && [ "$index" -gt 0 ]; then
                    indices_to_show+=($index)
                fi
            done
        elif [[ "$port_spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            for ((i=start; i<=end; i++)); do
                if [ "$i" -le "${#ports[@]}" ] && [ "$i" -gt 0 ]; then
                    indices_to_show+=($i)
                fi
            done
        else
            echo -e "${RED}Invalid port specification: $port_spec${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
            return
        fi
    fi
    if [ -n "$except_spec" ]; then
        if [[ "$except_spec" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            IFS=',' read -ra specified_indices <<< "$except_spec"
            for index in "${specified_indices[@]}"; do
                if [ "$index" -le "${#ports[@]}" ] && [ "$index" -gt 0 ]; then
                    indices_to_except+=($index)
                fi
            done
        elif [[ "$except_spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            for ((i=start; i<=end; i++)); do
                if [ "$i" -le "${#ports[@]}" ] && [ "$i" -gt 0 ]; then
                    indices_to_except+=($i)
                fi
            done
        else
            echo -e "${RED}Invalid exception specification: $except_spec${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
            return
        fi
    fi
    
    if [ ${#indices_to_except[@]} -gt 0 ]; then
        new_indices_to_show=()
        for show_idx in "${indices_to_show[@]}"; do
            exclude=false
            for except_idx in "${indices_to_except[@]}"; do
                if [ "$show_idx" -eq "$except_idx" ]; then
                    exclude=true
                    break
                fi
            done
            if [ "$exclude" == "false" ]; then
                new_indices_to_show+=($show_idx)
            fi
        done
        indices_to_show=("${new_indices_to_show[@]}")
    fi
    
    if [ ${#indices_to_show[@]} -eq 0 ]; then
        echo -e "${RED}No valid ports selected for showing details.${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    for index in "${indices_to_show[@]}"; do
        port=${ports[$index-1]}
        if [ -z "$port" ]; then
            echo -e "${RED}Invalid port at index $index. Skipping...${NC}"
            continue
        fi
        
        echo -e "\n${YELLOW}Details for port [$(($index))]: ${GREEN}$port${NC}"
        echo -e "${CYAN}-------------------------------------${NC}"
        
        echo -e "${GREEN}Process Information:${NC}"
        lsof_output=$(lsof -i :$port -P -n 2>/dev/null)
        if [ -n "$lsof_output" ]; then
            echo -e "$lsof_output"
        else
            echo -e "No process information available"
        fi
        
        pid=$(lsof -i :$port -t 2>/dev/null)
        if [ -n "$pid" ]; then
            echo -e "\n${GREEN}Process Details:${NC}"
            pid_list=$(echo "$pid" | tr '\n' ',' | sed 's/,$//')
            ps_output=$(ps -p "$pid_list" -f 2>/dev/null)
            echo -e "$ps_output"
            
            echo -e "\n${GREEN}Process Tree:${NC}"
            first_pid=$(echo "$pid" | head -n1)
            pstree_output=$(pstree -p $first_pid 2>/dev/null || echo "pstree command not available")
            echo -e "$pstree_output"
            
            echo -e "\n${GREEN}Network Connections:${NC}"
            ss_output=$(ss -tuln | grep ":$port " 2>/dev/null || echo "No network data available")
            echo -e "$ss_output"
        else
            echo -e "\n${RED}No active process found for this port${NC}"
        fi
        echo -e "${CYAN}-------------------------------------${NC}"
    done
    
    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
}

parse_command() {
    local input="$1"
    local command=""
    local ports=""
    local except=""
    local all=false
    local use_index=false
    local use_port=false
    local oldIFS="$IFS"
    IFS=' '
    
    read -ra args <<< "$input"
    IFS="$oldIFS"
    
    if [ ${#args[@]} -eq 0 ]; then
        return
    fi
    
    command="${args[0]}"
    
    if [ "$command" == "r" ] || [ "$command" == "reface" ]; then
        check_ports
        return
    elif [ "$command" == "h" ] || [ "$command" == "help" ]; then
        display_help
        return
    elif [ "$command" == "exit" ] || [ "$command" == "quit" ] || [ "$command" == "q" ] || [ "$command" == "e" ]; then
        echo -e "${CYAN}Exiting...${NC}"
        sleep 1
        clear
        exit 0
    elif [ "$command" != "kill" ] && [ "$command" != "d" ] && [ "$command" != "detail" ]; then
        display_header
        echo -e "${RED}Unknown command: $command${NC}"
        echo -e "${YELLOW}Type 'help' or 'h' for available commands${NC}"

        return
    fi

    if [[ "$input" =~ ^(kill|d|detail)\ +-i\ +-a$ ]]; then
        echo -e "${CYAN}Running ${command} all command...${NC}"
        case "$command" in
            kill)
                kill_ports_new "all_index" "" ""
                ;;
            d|detail)
                show_full_details "all_index" "" 
                ;;
        esac
        return
    fi
    
    if [[ "$input" =~ ^(kill|d|detail)\ +-p\ +-a$ ]]; then
        echo -e "${CYAN}Running ${command} all command...${NC}"
        case "$command" in
            kill)
                kill_ports_new "all_port" "" ""
                ;;
            d|detail)
                show_full_details "all_port" "" 
                ;;
        esac
        return
    fi
    
    i=1
    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            -i|--index)
                use_index=true
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    ports="${args[$i]}"
                else
                    display_header
                    echo -e "${RED}Missing argument for -i/--index${NC}"
                    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
                    return
                fi
                ;;
            -p|--port)
                use_port=true
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    ports="${args[$i]}"
                else
                    display_header
                    echo -e "${RED}Missing argument for -p/--port${NC}"
                    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
                    return
                fi
                ;;
            -e|--except)
                i=$((i+1))
                if [ $i -lt ${#args[@]} ]; then
                    except="${args[$i]}"
                else
                    display_header
                    echo -e "${RED}Missing argument for -e/--except${NC}"
                    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
                    return
                fi
                ;;
            -a|--all)
                all=true
                ;;
            *)
                display_header
                echo -e "${RED}Unknown option: ${args[$i]}${NC}"
                echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
                return
                ;;
        esac
        i=$((i+1))
    done
    
    if [ "$command" == "kill" ]; then
        if [ "$all" == "true" ]; then
            if [ "$use_port" == "true" ]; then
                kill_ports_new "all_port" "$except" ""
            else
                kill_ports_new "all_index" "$except" ""
            fi
        elif [ -n "$ports" ]; then
            if [ "$use_port" == "true" ]; then
                kill_ports_new "port:$ports" "$except" ""
            else
                kill_ports_new "$ports" "$except" ""
            fi
        else
            display_header
            echo -e "${RED}Missing port specification. Use -i, -p, or -a option.${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        fi
    elif [ "$command" == "d" ] || [ "$command" == "detail" ]; then
        if [ "$all" == "true" ]; then
            if [ "$use_port" == "true" ]; then
                show_full_details "all_port" "$except"
            else
                show_full_details "all_index" "$except"
            fi
        elif [ -n "$ports" ]; then
            if [ "$use_port" == "true" ]; then
                show_full_details "port:$ports" "$except"
            else
                show_full_details "$ports" "$except"
            fi
        else
            display_header
            echo -e "${RED}Missing port specification. Use -i, -p, or -a option.${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        fi
    fi
}

kill_ports_new() {
    local port_spec=$1
    local except_spec=$2
    shift 2
    local all_ports=("$@")
    local ports_to_kill=()
    local indices_to_kill=()
    local indices_to_except=()
    
    display_header
    
    ports=($(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -n | uniq))
    
    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${YELLOW}No active ports found to kill.${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    echo -e "${CYAN}Found ${#ports[@]} active ports.${NC}"
    
    if [[ "$port_spec" == port:* ]]; then
        port_spec="${port_spec#port:}"
        indices_array=($(convert_port_to_indices "$port_spec" "${ports[@]}"))
        indices_to_kill=("${indices_array[@]}")
    elif [ "$port_spec" == "all_port" ]; then
        echo -e "${CYAN}Processing all ports for killing...${NC}"
        for i in "${!ports[@]}"; do
            indices_to_kill+=($((i+1)))
        done
    elif [ "$port_spec" == "all_index" ]; then
        echo -e "${CYAN}Processing all ports for killing...${NC}"
        for i in "${!ports[@]}"; do
            indices_to_kill+=($((i+1)))
        done
    else
        if [ -n "$port_spec" ]; then
            if [[ "$port_spec" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
                IFS=',' read -ra specified_indices <<< "$port_spec"
                for index in "${specified_indices[@]}"; do
                    if [ "$index" -le "${#ports[@]}" ] && [ "$index" -gt 0 ]; then
                        indices_to_kill+=($index)
                    fi
                done
            elif [[ "$port_spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                start="${BASH_REMATCH[1]}"
                end="${BASH_REMATCH[2]}"
                for ((i=start; i<=end; i++)); do
                    if [ "$i" -le "${#ports[@]}" ] && [ "$i" -gt 0 ]; then
                        indices_to_kill+=($i)
                    fi
                done
            else
                echo -e "${RED}Invalid port specification: $port_spec${NC}"
                echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
                return
            fi
        else
            echo -e "${RED}Empty port specification.${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
            return
        fi
    fi
    
    if [ -n "$except_spec" ]; then
        if [[ "$except_spec" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            IFS=',' read -ra specified_indices <<< "$except_spec"
            for index in "${specified_indices[@]}"; do
                if [ "$index" -le "${#ports[@]}" ] && [ "$index" -gt 0 ]; then
                    indices_to_except+=($index)
                fi
            done
        elif [[ "$except_spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            for ((i=start; i<=end; i++)); do
                if [ "$i" -le "${#ports[@]}" ] && [ "$i" -gt 0 ]; then
                    indices_to_except+=($i)
                fi
            done
        else
            echo -e "${RED}Invalid exception specification: $except_spec${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
            return
        fi
    fi
    
    if [ ${#indices_to_except[@]} -gt 0 ]; then
        new_indices_to_kill=()
        for kill_idx in "${indices_to_kill[@]}"; do
            exclude=false
            for except_idx in "${indices_to_except[@]}"; do
                if [ "$kill_idx" -eq "$except_idx" ]; then
                    exclude=true
                    break
                fi
            done
            if [ "$exclude" == "false" ]; then
                new_indices_to_kill+=($kill_idx)
            fi
        done
        indices_to_kill=("${new_indices_to_kill[@]}")
    fi
    
    for index in "${indices_to_kill[@]}"; do
        port=${ports[$index-1]}
        if [ -n "$port" ]; then
            ports_to_kill+=("$port")
        fi
    done
    
    if [ ${#ports_to_kill[@]} -eq 0 ]; then
        echo -e "${RED}No valid ports selected for killing.${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    echo -e "${YELLOW}Killing the following ports:${NC}"
    for port in "${ports_to_kill[@]}"; do        
        echo -e "  ${RED}Port $port${NC}"
        pid=$(lsof -i :$port -t 2>/dev/null)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}Successfully killed process $pid running on port $port${NC}"
            else
                echo -e "  ${RED}Failed to kill process $pid on port $port${NC}"
            fi
        else
            echo -e "  ${RED}No process found on port $port${NC}"
        fi
    done
    
    echo -e "${CYAN}Reloading port list after killing operations...${NC}"
    sleep 1
    check_ports
}

main_loop() {
    check_ports
    
    local HISTFILE="${HOME}/.port_checker_history"
    
    while true; do
        read -e -p "-> $ " input

        if [ -n "$input" ]; then
            history -s "$input" 2>/dev/null
        fi
        
        parse_command "$input"
    done
}

main_loop
