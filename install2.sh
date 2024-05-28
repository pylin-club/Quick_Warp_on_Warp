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
	subnets=(
		"104.28.37."
		"104.28.51."
		"104.28.80."
		"104.28.106."
		"104.28.131."
		"172.68.30."
		"172.68.75."
		"172.71.12."
		"172.69.228."
		"172.71.228."
    )
	iplist=$1
	n=0
 	flag=""
	# for counter in $(seq 0 255); do
		# temp[$n]=$(echo 162.159.192.$(counter))
  # 		n=$[$n+1]
  #   		temp[$n]=$(echo 162.159.193.$(counter))
  #     		n=$[$n+1]
		# temp[$n]=$(echo 162.159.195.$(counter))
  # 		n=$[$n+1]
  # 		temp[$n]=$(echo 188.114.96.$(counter))
  #   		n=$[$n+1]
  #     		temp[$n]=$(echo 188.114.97.$(counter))
		# n=$[$n+1]
  #   		temp[$n]=$(echo 188.114.98.$(counter))
  #     		n=$[$n+1]
  #     		temp[$n]=$(echo 188.114.99.$(counter))
		# n=$[$n+1]

		# temp[$n]=$(echo 190.93.241.$counter)
  # 		n=$[$n+1]
  #   		temp[$n]=$(echo 190.93.242.$counter)
  #     		n=$[$n+1]
		# temp[$n]=$(echo 190.93.243.$counter)
  # 		n=$[$n+1]
  # 		temp[$n]=$(echo 197.234.241.$counter)
  #   		n=$[$n+1]
  #     		temp[$n]=$(echo 197.234.242.$counter)
		# n=$[$n+1]
  #   		temp[$n]=$(echo 197.234.243.$counter)
  #     		n=$[$n+1]
  #     		temp[$n]=$(echo 131.0.73.0.$counter)
		# n=$[$n+1]
  #       	temp[$n]=$(echo 131.0.74.0.$counter)
		# n=$[$n+1]
  #       	temp[$n]=$(echo 131.0.75.0.$counter)
		# n=$[$n+1]
 	# done
  
	while true; do
 		for subnet in "${subnets[@]}"; do
			temp[$n]=$(echo ${subnet}$(($RANDOM%256)))
			n=$[$n+1]
			if [ $n -ge $iplist ]
			then
   				flag=1
				break
			fi
   		done
	 
   		if [ -n "$flag" ]; then
	 		break
		fi
	done
 
 	flag=""
	while true;	do
		for subnet in "${subnets[@]}"; do
			if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
			then
   				flag=1
				break
			else
				temp[$n]=$(echo ${subnet}$(($RANDOM%256)))
				n=$[$n+1]
			fi
   		done
	 
	 	if [ -n "$flag" ]; then
	 		break
		fi
	done
}


endipresult(){
	num_configs=$1
	echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u > ip.txt
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

    # برای هر سطر در result.csv دستورات را اجرا کنید
    for ((i=2; i<=$num_lines; i++)); do
    	echo "license $((i-1)), captured."
        # اطلاعات مورد نیاز از هر سطر را دریافت کنید
        local line=$(sed -n "${i}p" ./result.csv)
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

		# ترکیب رشته و متغیرها در یک متغیر دیگر

  		if [ $((i % 2)) -eq 0 ]; then
		    value_to_add="@pylin_news"
		else
		    value_to_add="@pylin_gap"
		fi
  		
		new_json='{
	      "type": "wireguard",
	      "tag": "\ud83c\udf10Web_'"${i-1}"' | $value_to_add",
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
	      "fake_packets": "1-6"
	    },
	    {
	      "type": "wireguard",
	      "tag": "\ud83c\udfaeGame_'"${i-1}"' | $value_to_add",
	      "detour": "\ud83c\udf10Web_'"${i-1}"' | $value_to_add",
	      "server": "'"$ip"'",
	      "server_port": '"$port"',
	      
	      "local_address": [
	          "172.16.0.2/32",
	          "'"$i_w_ip"'"
	      ],
	      "private_key": "'"$i_w_pv"'",
	      "peer_public_key": "'"$i_w_pb"'",
	      "reserved": ['$i_w_res'],  
	
	      "mtu": 1280,
	      "fake_packets": "1-6"
	    }'
	
	    temp_json+="$new_json"
	
		# اضافه کردن خط خالی به محتوای متغیر موقت
		if [ $i -lt $num_lines ]; then
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
	curl https://bashupload.com/ -T warp.json | sed -e 's#wget#Your Link#' -e 's#https://bashupload.com/\(.*\)#https://bashupload.com/\1?download=1#'
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
	      "tag": "\ud83c\udf10Web_'"${i-1}"' | ${value_to_add}",
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
	      "fake_packets": "1-6"
	    },
	    {
	      "type": "wireguard",
	      "tag": "\ud83c\udfaeGame_'"${i-1}"' | ${value_to_add}",
	      "detour": "\ud83c\udf10Web_'"${i-1}"' | ${value_to_add}",
	      "server": "engage.cloudflareclient.com",
	      "server_port": 2408,
	      
	      "local_address": [
	          "172.16.0.2/32",
	          "'"$i_w_ip"'"
	      ],
	      "private_key": "'"$i_w_pv"'",
	      "peer_public_key": "'"$i_w_pb"'",
	      "reserved": ['$i_w_res'],  
	
	      "mtu": 1280,
	      "fake_packets": "1-6"
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
	curl https://bashupload.com/ -T warp.json | sed -e 's#wget#Your Link#' -e 's#https://bashupload.com/\(.*\)#https://bashupload.com/\1?download=1#'
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
