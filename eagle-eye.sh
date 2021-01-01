#!/bin/bash

# Values
all_directories=( "/" "/etc" "/logs" "/opt" "/root" "/home" "/usr" "/var" "/var/tmp" "/var/log" "/tmp" "Custom" ) 
users=( $(cat /etc/passwd | grep -E ":/home" | cut -d":" -f1) )
substrings_minimal=( "backup" "pass" "pwd" "user" )
substrings_extended=( ${substrings_minimal[@]} "bak" "auth" "cmd" "command" "comm=" "root" ${users[@]} )
hash_lengths=( 32 40 56 64 80 96 112 128 192 256 )
output_file=""
cwd=$(pwd)
dir_success=false
custom_dirs=false

# Some functions
function banner(){
	echo "
 ___           _       ___         
| __|__ _ __ _| |___  | __|  _ ___ 
| _|/ _\` / _\` | / -_) | _| || / -_)
|___\__,_\__, |_\___| |___\_, \___|
         |___/            |__/ v1.0
"
}

function tab(){
	echo -en "\t"
}

function error(){
	echo -e "[!] Option does not exist"
	sleep 1
}

function wait_for_user(){
	echo -e "\n[+] Press enter to continue..."
	read
}

function dir_and_pattern_chooser(){
	# Print menu
	clear
	banner
	echo -e "[1] Search locations:\n"
	for i in ${!all_directories[@]}; do
		echo -e "\t${i}) ${all_directories[${i}]}"
	done
	echo ""
	
	# Take directory choices
	tab
	read -p "[..] Enter (multiple space separated) choice/s: " -a chosen_directories
	for i in ${!chosen_directories[@]}; do
		if (( ${chosen_directories[$i]} >= ${#all_directories[@]} )) || (( ${chosen_directories[$i]} < 0 )); then # If option does not exist			
			tab
			error
			return			
		else # Else
		chosen_directories[$i]=${all_directories[chosen_directories[$i]]}		
		fi 		
	done
	temp_arr=()
	for i in ${chosen_directories[@]}; do		
		if [[ ${i} != "Custom" ]]; then
			temp_arr=( "${temp_arr[@]}" "${i}" )
		else
			custom_dirs=true
		fi
	done
	tab
	if [ ${custom_dirs} = true ]; then
		read -p "[..] Enter (space separated) custom directories: " -a cus
		chosen_directories=( "${temp_arr[@]}" "${cus[@]}" )
		tab
	else
		chosen_directories=( "${temp_arr[@]}" )
	fi
	echo "[->] Search locations set to: ${chosen_directories[@]}"
	
	# Set output file
	echo ""
	read -p "[2] Output filename (Default: null): " output_file
	if (( $(echo "${output_file}" | grep -c "/")!=1 )); then
		output_file="${cwd}/${output_file}"
	fi
	
	if [[ ! -d ${output_file} ]]; then
		echo -e "\t[->] Output file set to: ${output_file}"
	else
		echo -e "\t[->] No output file set"
	fi
	
	dir_success=true
		
	if (( $1==1 )); then # for Hash
		return
	fi
	
	# Take strings to search for
	echo -e "\n[3] Choose wordlist"
	echo -e "\t1. Minimal (default) -> ${substrings_minimal[@]}"
	echo -e "\t2. Extended -> ${substrings_extended[@]}"
	tab
	read -p "[..] Option: " choice
	case ${choice} in		
		2)
			substrings_to_be_used=${substrings_extended[@]}
			;;
		*)
			substrings_to_be_used=${substrings_minimal[@]}
			;;			
	esac	
	
	tab
	read -p "[..] (A)dd to patterns / (C)ustom patterns / (N)o change (default): " c
	case ${c} in
		"a" | "A")
			tab
			read -p "[..] Custom (space separated) patterns to add (if any): " -a cus
			substrings_to_be_used=( "${substrings_to_be_used[@]}" "${cus[@]}" )
			;;
		"c" | "C")
			tab
			read -p "[..] Enter custom (space separated) patterns: " -a cus
			substrings_to_be_used=( "${cus[@]}" )
			;;
		"n" | "N" | "")			
			;;
		*)
			error
			return
			;;
	esac
	patterns=""
	for substring in ${substrings_to_be_used[@]}; do
		if [[ -z ${patterns} ]]; then
			patterns="${substring}"
		else
			patterns="${patterns}|${substring}"
		fi		
	done
	echo -e "\t[->] Search patterns set to: ${patterns[@]}\n"	
	
	echo "[*] Searching"
}

function search_in_files(){
	dir_and_pattern_chooser	0	
	if [ "${dir_success}" = false ]; then
		return
	fi

	for directory in ${chosen_directories[@]}; do
		cd ${directory}
		if [[ ! -d ${output_file} ]]; then
			grep --color=auto -inHEr "${patterns}" 2> /dev/null | tee -a ${output_file}
		else
			grep --color=auto -inHEr "${patterns}" 2> /dev/null 
		fi
	done
	wait_for_user
}

function search_for_dirs(){
	dir_and_pattern_chooser 0
	if [ "${dir_success}" = false ]; then
		return
	fi
	
	for directory in ${chosen_directories[@]}; do
		cd ${directory}
		if [[ ! -d ${output_file} ]]; then
			find ./ | grep --color=auto -iE "${patterns}" 2> /dev/null | tee -a ${output_file}
		else
			find ./ | grep --color=auto -iE "${patterns}" 2> /dev/null
		fi
	done
	wait_for_user
}

function search_for_hashes(){
	dir_and_pattern_chooser 1
	
	if [ "${dir_success}" = false ]; then
		return
	fi
	
	echo -e "\n[*] Searching hashes"
	for directory in ${chosen_directories[@]}; do
		cd ${directory}		
		for hash_length in ${hash_lengths[@]}; do # Find common type hashes
			if [[ ! -d ${output_file} ]]; then
				grep --color=auto -inHEr "(^|[^a-z0-9])[a-z0-9]{${hash_length}}($|[^a-z0-9])" 2> /dev/null | tee -a ${output_file}
			else
				grep --color=auto -inHEr "(^|[^a-z0-9])[a-z0-9]{${hash_length}}($|[^a-z0-9])" 2> /dev/null
			fi
		done
		if [[ ! -d ${output_file} ]]; then
				grep --color=auto -inHEr "\\\$2[aby]\\$" 2> /dev/null | tee -a ${output_file}
			else
				grep --color=auto -inHEr "\\\$2[aby]\\$" 2> /dev/null
			fi
	done
	wait_for_user
}

function show_help(){
	clear
	banner
	echo -e "Usage: ${0}\nEagle-Eye is a simple shell script that can recursively search\n(any chosen portion of) the filesystem and list out files or folders that\ncontain specific substrings of interest.\nGithub: https://github.com/captain-woof/Eagle-Eye"
	wait_for_user
}

# MAIN CODE

# MAIN MENU LOOP
while true; do
	clear
	dir_success=false
	custom_dirs=false
	# Main menu
	banner
	echo "1. Search for text inside files"
	echo "2. Search for directory/file by name"
	echo "3. Search for possible hashes inside files"
	echo "4. Help"
	echo -e "5. EXIT\n"
	read -p "Enter choice: " choice
	
	case ${choice} in
		1)
			search_in_files
			;;
		2)
			search_for_dirs
			;;
		3)
			search_for_hashes
			;;
		4)
			show_help
			;;
		5)
			exit
			;;
		*)
			error
			;;
	esac		
done
