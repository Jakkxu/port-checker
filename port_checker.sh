#!/bin/bash
#####################################################################################
##                                                                                 ##
## DESCRIPTION:                                                                    ##
##   This script allows you to view all listening ports on your system             ##
##   and kill processes by port number. It provides a user-friendly interface      ##
##   with colored output and various command options.                              ##
##                                                                                 ##
## FUNCTIONS:                                                                      ##
##   display_header - Clears the screen and displays the ASCII art logo            ##
##   display_help - Shows all available commands and usage instructions            ##
##   check_ports - Lists all active listening ports with their processes           ##
##   show_full_details - Shows detailed information about specified ports          ##
##   kill_ports_new - Terminates processes running on specified ports              ##
##   parse_command - Processes user input and executes the appropriate function    ##
##   main_loop - Main entry point that starts the command loop                     ##
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
    echo -e "    ${CYAN}-p, --port${NC} PORT_SPEC - Specify ports to kill (required unless -a is used)"
    echo -e "    ${CYAN}-e, --except${NC} PORT_SPEC - Specify ports to exclude"
    echo -e "    ${CYAN}-a, --all${NC} - Kill all ports"
    
    echo -e "  ${GREEN}fd${NC} or ${GREEN}full-detail${NC} - Show full details of ports"
    echo -e "    ${CYAN}-p, --port${NC} PORT_SPEC - Specify ports to show details (required unless -a is used)"
    echo -e "    ${CYAN}-e, --except${NC} PORT_SPEC - Specify ports to exclude"
    echo -e "    ${CYAN}-a, --all${NC} - Show all ports"
    
    echo -e "  Examples:"
    echo -e "    ${GREEN}kill -p 1${NC} - Kill port number 1"
    echo -e "    ${GREEN}kill -p 1,5,7${NC} - Kill ports 1, 5, and 7"
    echo -e "    ${GREEN}kill -a${NC} - Kill all ports"
    echo -e "    ${GREEN}kill -p -a${NC} - Also kills all ports (same as kill -a)"
    echo -e "    ${GREEN}kill -p 1-5${NC} - Kill ports 1 through 5"
    echo -e "    ${GREEN}kill -p 1-10 -e 5,8,9${NC} - Kill ports 1-10 except 5,8,9"
    echo -e "    ${GREEN}kill -a -e 2-5${NC} - Kill all ports except 2 through 5"
    echo -e "    ${GREEN}fd -p 1${NC} - Show full details of port 1"
    echo -e "    ${GREEN}fd -a${NC} - Show full details of all ports"
    echo -e "    ${GREEN}full-detail -p 1-3${NC} - Show details for ports 1 through 3"
    echo -e ""
    echo -e "  ${GREEN}r${NC} or ${GREEN}reface${NC} - Reload/refresh port list"
    echo -e "  ${GREEN}h${NC} or ${GREEN}help${NC} - Display this help information"
    echo -e "  ${GREEN}exit${NC}, ${GREEN}quit${NC}, ${GREEN}q${NC}, or ${GREEN}e${NC} - Exit program"
    
    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
}

check_ports() {
    display_header
    echo -e "${CYAN}======= CHECKING ACTIVE PORTS =======${NC}"
    ports=($(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -n | uniq))
    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${YELLOW}No active ports found.${NC}"
    else
        echo -e "ID   PORT     HOST            PROCESS                  "
        echo -e "------------------------------------------------------------"
        
        for i in "${!ports[@]}"; do
            port=${ports[$i]}
            pid=$(lsof -i :$port -t)
            command=$(ps -p $pid -o comm= 2>/dev/null)
            host=$(lsof -i :$port -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f1 | head -1)

            if [ "$host" != "*" ]; then
                host="127.0.0.1"
            fi

            printf "[%d] %-8s %-15s %-25s\n" "$((i+1))" "$port" "$host" "$command"
        done
    fi
    
    echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
}

show_full_details() {
    local port_spec=$1
    local except_spec=$2

    display_header
    echo -e "${CYAN}=============== FULL DETAILS ===============${NC}"

    ports=($(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -n | uniq))

    if [ ${#ports[@]} -eq 0 ]; then
        echo -e "${YELLOW}No active ports to show details.${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    echo -e "${CYAN}Found ${#ports[@]} active ports.${NC}"

    local indices_to_show=()
    local indices_to_except=()

    if [ "$port_spec" == "all" ]; then
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
            ps_output=$(ps -p $pid -f)
            echo -e "$ps_output"
            
            echo -e "\n${GREEN}Process Tree:${NC}"
            pstree_output=$(pstree -p $pid 2>/dev/null || echo "pstree command not available")
            echo -e "$pstree_output"
            
            echo -e "\n${GREEN}Network Connections:${NC}"
            netstat_output=$(netstat -tuln | grep ":$port " || echo "No netstat data available")
            echo -e "$netstat_output"
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
    
    read -ra args <<< "$input"
    
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
    elif [ "$command" != "kill" ] && [ "$command" != "fd" ] && [ "$command" != "full-detail" ]; then
        display_header
        echo -e "${RED}Unknown command: $command${NC}"
        echo -e "${YELLOW}Type 'help' or 'h' for available commands${NC}"
        echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        return
    fi
    
    if [[ "$input" =~ ^(kill|fd|full-detail)\ +-p\ +-a$ ]]; then
        echo -e "${CYAN}Running ${command} all command...${NC}"
        case "$command" in
            kill)
                kill_ports_new "all" "" ""
                ;;
            fd|full-detail)
                show_full_details "all" "" 
                ;;
        esac
        return
    fi
    
    i=1
    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            -p|--port)
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
            kill_ports_new "all" "$except" "${ports[@]}"
        elif [ -n "$ports" ]; then
            kill_ports_new "$ports" "$except" "${ports[@]}"
        else
            display_header
            echo -e "${RED}Missing port specification. Use -p or -a option.${NC}"
            echo -e "\n${YELLOW}Type 'help' or 'h' for available commands${NC}"
        fi
    elif [ "$command" == "fd" ] || [ "$command" == "full-detail" ]; then
        if [ "$all" == "true" ]; then
            show_full_details "all" "$except"
        elif [ -n "$ports" ]; then
            show_full_details "$ports" "$except"
        else
            display_header
            echo -e "${RED}Missing port specification. Use -p or -a option.${NC}"
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
    
    if [ "$port_spec" == "all" ]; then
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
    
    while true; do
        read -p "-> $ " input
        parse_command "$input"
    done
}

main_loop
