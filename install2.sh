#!/bin/bash

GREEN= $(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

case "$(uname -m)" in
	x86_64 | x64 | amd64 )
		cpu=amd64
	;;
	i386 | i686 )
		cpu=386
	;;
	armv8 | armv8l | arm64 | aarch64 )
		cpu=arm64
	;;
	armv7l )
		cpu=arm
	;;
	* )
		echo "The current architecture is $(uname -m), temporarily not supported"
		exit
	;;
esac

subnets=(
	# USA
	"141.101.116."
	"141.101.117."
	"141.101.127."

	"162.159.79."
	"162.159.81."
	"162.159.83."
	"162.159.98."
	"162.159.117."
	"162.159.242."
	"162.159.252."
	
	"172.64.97."
	"172.64.161."

	"172.69.33."
	"172.69.88."
	"172.69.70."

	"173.245.48."
	"173.245.53."
	"173.245.63."

	"188.114.99."
	"188.114.104."
	"188.114.105."

	"198.41.128."
	

	# UK
	"141.101.98."

	"172.69.79."
	"172.69.45."

	# ITALY
	"188.114.100."
	"188.114.101."
	"188.114.102."
	"188.114.103."

	# SPAIN
	"188.114.106."
	"188.114.107."
	"188.114.108."
	"188.114.109."
	"188.114.110."
	"188.114.111."

	# CANADA
	"162.159.5."
	"162.159.17."
	"162.159.37."
	"162.159.58."
	"162.159.76."
	"162.159.192."
	"162.159.193."
	"162.159.194."
	"162.159.195."
	"162.159.196."
	"162.159.197."
	"162.159.200."
	"162.159.201."

	"172.64.33."
	"172.64.246."

	"172.65.33."
	"172.65.97."
	"172.65.161."
	"172.65.225."

	"172.67.33."
	"172.67.97."
	"172.67.161."
	"172.67.225."
	
	"188.114.96."
	"188.114.97."
	"188.114.98."

	"198.41.153."
	"198.41.194."
	"198.41.223."

	# Germany
	"172.64.220."
	"172.64.221."
	"172.64.222."
	"172.64.224."
	"172.64.225."
	"172.64.226."
	"172.64.227."

	"162.159.178."
	"162.159.179."
	"162.159.180."
	"162.159.181."
	"162.159.182."
	"162.159.183."
	"162.159.185."
	"162.159.186."
	"162.159.187."
	"162.159.188."
	"162.159.189."
	"162.159.190."
	"162.159.191."
	"162.159.198."
	"162.159.199."
	"162.159.220."
	"162.159.221."
	"162.159.230."
	"162.159.231."

	# Netherlands -> 141.101.64.0/18
	"141.101.65."
	"141.101.75."

	"198.41.148."

	# South korea
	"141.101.82."

	# Austria
	"141.101.107."

	# Colombia
	"141.101.108."

	# FRANCE
	"141.101.67."
	"141.101.97."
	"141.101.126."

	"162.159.184."
	"162.159.222."
	"162.159.232."

	"172.64.223."
	
	"198.41.149."
	"198.41.150."
	"198.41.151."

	# INDIA
	"172.69.94."
	"172.69.95."

	"172.69.73."
	"172.69.74."
	"172.69.75."

	"198.41.244."
	"198.41.245."

	# Indonesia
	"172.69.89."

	# Luxembourg
	"198.41.253."

	# HONG KONG
	"172.69.96."
	"172.69.97."

	# Macao
	"172.69.72."

	# Bangladesh
	"172.69.78."

	# Nepal
	"172.69.76."
	"172.69.41."

	# Japan
	"172.69.62."
	"172.69.63."

	# Iraq
	"172.69.53."

	# Lithuania
	"172.69.52."

	# Poland
	"172.69.49."

	# Mongolia
	"172.69.45."

	# Greece
	"172.69.44."

	# Russia
	# "172.69.50."
)

total_ips=$(( ${#subnets[@]} * 256 ))
min_possible_ips=100
max_possible_ips=$((total_ips / 8))

min_configs=2
max_configs=25


cfwarpIP(){
	echo "download warp endpoint file base on your CPU architecture"
	if [[ -n $cpu ]]; then
		curl -L -o warpendpoint -# --retry 2 https://raw.githubusercontent.com/pylin-club/Quick_Warp_on_Warp/main/cpu/$cpu
	fi
}

endipv4(){
	num_ips=$1

	# check the range of IPs
	if [[ ${num_ips} -lt ${min_possible_ips} ]]; then
		num_ips=${min_possible_ips}
	elif [[ ${num_ips} -gt ${max_possible_ips} ]]; then
		num_ips=${max_possible_ips}
	fi

	# Initialize an empty array for responsive IPs
	# echo "------------------------------------------------------------"
	# 	echo "ping ip pools (this might take some time!):"
	# responsive_ips=()
	
	# Check ping for each IP
	# for ip in "${subnets[@]}"; do
	#     if ping -c 1 "${ip}78" &> /dev/null; then
	#         # IP responds to ping
	#  	echo "${GREEN}range: ${ip}0, OK!${RESET}"
	#         responsive_ips+=("$ip")
	#     else
	#         # IP does not respond to ping
	#         echo "${RED}range: ${ip}0, does not ping and removed.${RESET}"
	#     fi
	# done

	#  	echo "Done! now let's scan $num_ips ips"
	#    	echo "------------------------------------------------------------"
    
	declare -ag distinct_ips

	while [[ ${#distinct_ips[@]} -lt $num_ips ]]; do

		for ip in "${subnets[@]}"; do

			if [[ ${#distinct_ips[@]} == $num_ips ]]; then
				break
			fi
			
			random_ip=$(echo ${ip}$((RANDOM % 256)))
			
			if [[ ! "${distinct_ips[@]}" =~ "$random_ip" ]]; then
				distinct_ips+=("$random_ip")
			fi

		done
	done

}


endipresult(){
	num_configs=$1

	# write random distinct IPs into a txt file
	for value in "${distinct_ips[@]}"; do
		echo "$value" >> "ip.txt"
	done

	ulimit -n 102400
	chmod +x warpendpoint
	./warpendpoint

	echo "------------------------------------------------------------"
	echo "${GREEN}successfully generated ipv4 endip list${RESET}"
	echo "${GREEN}successfully create result.csv file${RESET}"
	echo "${CYAN}Now we're going to process result.csv${RESET}"

	process_result_csv $num_configs 1

	rm -rf ip.txt warpendpoint result.csv
	exit
}

get_values() {
    local api_output=$(curl -sL "https://api.zeroteam.top/warp?format=sing-box")
    local ipv6=$(echo "$api_output" | grep -oE '"2606:4700:[0-9a-f:]+/128"' | sed 's/"//g')
    local private_key=$(echo "$api_output" | grep -oE '"private_key":"[0-9a-zA-Z\/+]+=+"' | sed 's/"private_key":"//; s/"//')
    local public_key=$(echo "$api_output" | grep -oE '"peer_public_key":"[0-9a-zA-Z\/+]+=+"' | sed 's/"peer_public_key":"//; s/"//')
    local reserved=$(echo "$api_output" | grep -oE '"reserved":\[[0-9]+(,[0-9]+){2}\]' | sed 's/"reserved"://; s/\[//; s/\]//')
    echo "$ipv6@$private_key@$public_key@$reserved"
}

process_result_csv() {
	num_configs=$1
	use_default_ip_port=$2
	num_lines=$(wc -l < ./result.csv)

	# Default IP & PORT
	local ip="engage.cloudflareclient.com"
	local port=2408

	# check the range of IPs
	if [[ ${num_configs} -lt ${min_configs} ]]; then
		num_configs=${min_configs}
	elif [[ ${num_configs} -gt ${max_configs} ]]; then
		num_configs=${max_configs}
	fi

	echo "This step might take some times based on how many configs you ordered:"

    # loop over result.csv IPs
	counter=0
	for ((i=2; i<=$num_configs; i++)); do

		if [ "$use_default_ip_port" -eq 1 ]; then
			# extract each line
			local line=$(sed -n "${i}p" ./result.csv)
			
			# extract DELAY and filter DELAY >= 1000
			local delay=$(echo "$line" | awk -F',' '{gsub(/ ms/, "", $3); print $3}')
			if [ "$delay" -lt 1000 ]; then
				counter=$((counter+1))
				echo "config $((counter)), created."
				
				# extract ip:port
				local endpoint=$(echo "$line" | awk -F',' '{print $1}')
				local ip=$(echo "$endpoint" | awk -F':' '{print $1}')
				local port=$(echo "$endpoint" | awk -F':' '{print $2}')
				
				values=$(get_values)
				w_ip=$(echo "$values" | cut -d'@' -f1)
				w_pv=$(echo "$values" | cut -d'@' -f2)
				w_pb=$(echo "$values" | cut -d'@' -f3)
				w_res=$(echo "$values" | cut -d'@' -f4)
				
				i_values=$(get_values)
				i_w_ip=$(echo "$i_values" | cut -d'@' -f1)
				i_w_pv=$(echo "$i_values" | cut -d'@' -f2)
				i_w_pb=$(echo "$i_values" | cut -d'@' -f3)
				i_w_res=$(echo "$i_values" | cut -d'@' -f4)
			
			else
				continue
			fi

		else
			values=$(get_values)
			w_ip=$(echo "$values" | cut -d'@' -f1)
			w_pv=$(echo "$values" | cut -d'@' -f2)
			w_pb=$(echo "$values" | cut -d'@' -f3)
			w_res=$(echo "$values" | cut -d'@' -f4)
			
			i_values=$(get_values)
			i_w_ip=$(echo "$i_values" | cut -d'@' -f1)
			i_w_pv=$(echo "$i_values" | cut -d'@' -f2)
			i_w_pb=$(echo "$i_values" | cut -d'@' -f3)
			i_w_res=$(echo "$i_values" | cut -d'@' -f4)

		fi
			
		if [ $((i % 2)) -eq 0 ]; then
			value_to_add="@pylin_news"
		else
			value_to_add="@pylin_gap"
		fi
		
		new_json='{
		"type": "wireguard",
		"tag": "\ud83c\udf10Web_'$((i - 1))' | '$value_to_add'",
		"server": "'"$ip"'",
		"server_port": '"$port"',
		"local_address": [
			"172.16.0.2/32",
			"'"$w_ip"'"
		],
		"private_key": "'"$w_pv"'",
		"peer_public_key": "'"$w_pb"'",
		"reserved": ['$w_res'],
		"mtu": 1280,
		"fake_packets": "5-10"
		}, {
		"type": "wireguard",
		"tag": "\ud83c\udfaeGame_'$((i - 1))' | '$value_to_add'",
		"detour": "\ud83c\udf10Web_'$((i - 1))' | '$value_to_add'",
		"server": "'"$ip"'",
		"server_port": '"$port"',
		"local_address": [
			"172.16.0.2/32",
			"'"$i_w_ip"'"
		],
		"private_key": "'"$i_w_pv"'",
		"peer_public_key": "'"$i_w_pb"'",
		"reserved": ['$i_w_res'],  
		"mtu": 1120,
		"fake_packets": "5-10"
		},'
	
		temp_json+="$new_json"
	done


    echo "------------------------------------------------------------"
    echo "We have found the number of ${counter} clean IPs."
    echo ""
	if [ "$counter" -gt "$num_configs" ]; then
		echo "Warning: you have requested ${num_configs} configs but only ${counter} configs created."
		echo "try using a bigger number for scanning IPs"
	fi

	temp_json="${temp_json%,}"

	full_json='
	{
		"outbounds": 
			[
				'"$temp_json"'
			]
	}
	'
	echo "$full_json" > warp.json
	echo "number of final IPs: ${counter}"
	echo "------------------------------------------------------------"
	echo "${GREEN}Your link:${RESET}"
	curl https://bashupload.com/ -T warp.json | sed -e 's#wget#Your Link#' -e 's#https://bashupload.com/\(.*\)#https://bashupload.com/\1#'
	echo "------------------------------------------------------------"
	echo ""
	mv warp.json warp_$(date +"%Y%m%d_%H%M%S").json
}

menu(){
	clear
	echo "---------------Credits-----------------------------"
	echo ""
	echo "Yonggekkk  ：github.com/yonggekkk"
	echo "Elfina Tech  : github.com/Elfiinaa"
	echo "Elfina Tech(YT)  : youtube.com/@ElfinaTech"
	echo "------------------------------------------------------------"
	echo "1.Automatic scanning and execution (Android / Linux)"
	echo "2.Import custom IPs with result.csv file (windows)"
	echo ""
	read -r -p "Please choose an option: " option

	if [ "$option" = "1" ]; then
		read -rep $"Number of IPs to scan (min:${min_possible_ips}, max:${max_possible_ips}) use 0 for engage.cloudflareclient.com:2408): " number_of_ips
		read -rep $"Number of configurations (min:${min_configs}, max:${max_configs}) [5 is recommended] : " number_of_configs

		if [ "$number_of_ips" -ne 0 ]; then
			cfwarpIP
			endipv4 $number_of_ips
			endipresult $number_of_configs
		else
			process_result_csv $number_of_configs 0
		fi
	elif [ "$option" = "2" ]; then
		read -rep $"Number of configurations(e.g. 10): " number_of_configs
		process_result_csv $number_of_configs 1
	else
		echo "Invalid option"
	fi
}

menu
