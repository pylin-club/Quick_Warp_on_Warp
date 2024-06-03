#!/bin/bash

GREEN=$(tput setaf 2)
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

cfwarpIP(){
	echo "download warp endpoint file base on your CPU architecture"
	if [[ -n $cpu ]]; then
		curl -L -o warpendpoint -# --retry 2 https://raw.githubusercontent.com/pylin-club/Quick_Warp_on_Warp/main/cpu/$cpu
	fi
}

endipv4(){
	iplist=$1
 
	subnets=(
 		# Original
		"162.159.192."
		# "162.159.193."
		# "162.159.195."
		"188.114.96."
		"188.114.97."
		# "188.114.98."
		"188.114.99."
  		
		# Germany -> 172.64.0.0/13
		# "172.64.33."
		"172.64.97."
		"172.64.161."
		"172.64.225."
		
		"172.65.33."
		"172.65.97."
		# "172.65.161."
		"172.65.225."
		
		"172.67.33."
		"172.67.97."
		"172.67.161."
		"172.67.225."
		
		# "172.69.33."
		# "172.69.97."
		"172.69.161."
		# "172.69.225."
		
		# "172.71.33."
		# "172.71.97."
		# "172.71.161."
		# "172.71.225."

		# Netherlands -> 141.101.64.0/18
  		"141.101.65."
		"141.101.67."
		"141.101.75."
		"141.101.82."
  
		"141.101.97."
		"141.101.98."
		"141.101.107."
		"141.101.108."
  
		"141.101.116."
		"141.101.117."
		"141.101.126."
		"141.101.127."


		# temp  
		# "8.6.144."
		# "8.9.231."
		# "8.10.148."
		# "8.21.239."
		# "8.45.102."
		# "104.19.237."
		# "108.162.236."
		# "141.101.73."
  		"162.158.111."
		# "162.158.173."
		# "162.159.250."
		# "172.64.203."
		# "173.245.63."
		# "188.114.99."
		# "198.41.205."
		# "199.27.132."
    
    )

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

	#  	echo "Done! now let's scan $iplist ips"
	#    	echo "------------------------------------------------------------"
    
	declare -ag distinct_ips

	while [[ ${#distinct_ips[@]} -lt $iplist ]]; do

		for ip in "${subnets[@]}"; do

			if [[ ${#distinct_ips[@]} == $iplist ]]; then
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
	process_result_csv $num_configs
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
count_conf=$1

    # تعداد سطرهای فایل result.csv را بدست آورید
    num_lines=$(wc -l < ./result.csv)
    echo "------------------------------------------------------------"
    echo "We have considered the number of ${num_lines} IPs."
    echo ""

	if [ "$count_conf" -lt "$num_lines" ]; then
		num_lines=$count_conf
	elif [ "$count_conf" -gt "$num_lines" ]; then
		echo "Warning: The number of IPs found is less than the number you want!"
		num_lines=$count_conf
	fi

    # loop over result.csv IPs
	counter=0
	for ((i=2; i<=$num_lines; i++)); do
		# echo "license $((i-1)), captured."
		
		# extract each line
		local line=$(sed -n "${i}p" ./result.csv)
		
		# extract DELAY and filter DELAY >= 1000
		local delay=$(echo "$line" | awk -F',' '{gsub(/ ms/, "", $3); print $3}')
		if ["$delay" -lt 1000]; then
			counter=$((counter+1))

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
			},
			{
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
			}'
		
			temp_json+="$new_json"
		
			# اضافه کردن خط خالی به محتوای متغیر موقت
			if [ $i -lt $num_lines ]; then
				temp_json+=","
			fi
		fi
	done
		
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

process_no_result_csv() {
	count_conf=$1
	for ((i=2; i<=$count_conf; i++)); do
		echo "license $((i-1)), captured."
  
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

		if [ $((i % 2)) -eq 0 ]; then
		    value_to_add="@pylin_news"
		else
		    value_to_add="@pylin_gap"
		fi
  
		new_json='{
	      "type": "wireguard",
	      "tag": "\ud83c\udf10Web_'$((i - 1))' | '$value_to_add'",
	      "server": "engage.cloudflareclient.com",
	      "server_port": 2408,
	
	      "local_address": [
	        "172.16.0.2/32",
	        "'"$w_ip"'"
	      ],
	      "private_key": "'"$w_pv"'",
	      "peer_public_key": "'"$w_pb"'",
	      "reserved": ['$w_res'],
	
	      "mtu": 1280,
	      "fake_packets": "5-10"
	    },
	    {
	      "type": "wireguard",
	      "tag": "\ud83c\udfaeGame_'$((i - 1))' | '$value_to_add'",
	      "detour": "\ud83c\udf10Web_'$((i - 1))' | '$value_to_add'",
	      "server": "engage.cloudflareclient.com",
	      "server_port": 2408,
	      
	      "local_address": [
	          "172.16.0.2/32",
	          "'"$i_w_ip"'"
	      ],
	      "private_key": "'"$i_w_pv"'",
	      "peer_public_key": "'"$i_w_pb"'",
	      "reserved": ['$i_w_res'],  
	
	      "mtu": 1120,
	      "fake_packets": "5-10"
	    }'
	
	    temp_json+="$new_json"
	
		# اضافه کردن خط خالی به محتوای متغیر موقت
		if [ $i -lt $count_conf ]; then
		    temp_json+=","
		fi
	done
		
	full_json='
	{
	  "outbounds": 
	  [
		'"$temp_json"'
	  ]
	}
	'
	echo "$full_json" > warp.json
	echo ""
	echo "${GREEN}Upload Files to Get Link${RESET}"
	echo "------------------------------------------------------------"
	echo "Your link:"
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
 		read -r -p "Number of IPs to scan (e.g. 100) [0 for engage.cloudflareclient.com:2408]: " number_of_ips
		read -r -p "Number of configurations (e.g. 10): " number_of_configs

    	if [ "$number_of_ips" -ne 0 ]; then
			cfwarpIP
			endipv4 $number_of_ips
			endipresult $number_of_configs
		else
			process_no_result_csv $number_of_configs
		fi
	elif [ "$option" = "2" ]; then
		read -r -p "Number of configurations(e.g. 10): " number_of_configs
		process_result_csv $number_of_configs
	else
		echo "Invalid option"
	fi
}

menu
