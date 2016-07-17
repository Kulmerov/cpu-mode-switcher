#!/bin/bash

set_core_governor() {
	local core=$1
	local cpu_governor=$2
	echo $cpu_governor > /sys/devices/system/cpu/cpu$core/cpufreq/scaling_governor
}

print_current_status() {
	local current_cpu_mode=$(get_current_cpu_mode)
	local title="CPU mode: ${current_cpu_mode^^}"
	echo $title
	cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

get_current_cpu_mode() {
	local number_of_performance=$(get_number_of_performance)
	local name_of_cpu_mode=""
	if [ "$number_of_performance" -gt 2 ]; then
		echo "high"
		return;
	else
		if [ "$number_of_performance" == 2 ]; then
			echo "medium"
			return;
		fi
	fi
	echo "low"
}

get_number_of_performance() {
	local number_of_performance=0
	for governor in $(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor); do 
		if [ "$governor" == "performance" ]; then
  			((number_of_performance++))
		fi
	done
	echo "$number_of_performance"
}

switch_to_next_cpu_mode() {
	local current_cpu_mode=$(get_current_cpu_mode)
	case $current_cpu_mode in
	    low)
			set_cpu_mode medium
		    shift 
	    ;;
	    medium)
			set_cpu_mode high
		    shift 
	    ;;
	    high)
		  	set_cpu_mode low
		    shift 
	    ;;
	esac
}

set_cpu_mode() {
	local mode=$1

	set_cpu_governor() {
		local start=$1
		local end=$2
		local governor=$3
		for i in $(eval echo {$start..$end})
		do
			set_core_governor $i $governor
		done
	}

	case $mode in
	    low)
			set_cpu_governor 0 3 'powersave'
		    shift 
	    ;;
	    medium)
			set_cpu_governor 0 1 'powersave'
			set_cpu_governor 2 3 'performance'
		    shift 
	    ;;
	    high)
		  	set_cpu_governor 0 3 'performance'
		    shift 
	    ;;
	esac
}

USAGE="Usage: $0 [-m|--mode=low|medium|high] | [-h|--help] | [-s|--status] | [-n|--next-mode] | [-c|-current-mode]\n
		"
for i in "$@"
do
	case $i in
	    -m=low|-m=medium|-m=high|--mode=low|--mode=medium|--mode=high)
		    mode="${i#*=}"
		    set_cpu_mode $mode
		    print_current_status
		    exit 
	    ;;
	    -h|--help)
		    echo -e $USAGE
		    exit 
	    ;;
	    -s|--status)
			print_current_status
		    exit
	    ;;
	    -n|--next-mode)
			switch_to_next_cpu_mode
			print_current_status
		    exit
	    ;;
	    -c|--current-mode)
			current_cpu_mode=$(get_current_cpu_mode)
			echo "CPU mode: ${current_cpu_mode^^}"
		    exit
	    ;;
	    *)
	    	echo -e "$0: invalid option '$i'\n$USAGE" 
	    	exit
	    ;;
	esac
done
echo -e $USAGE