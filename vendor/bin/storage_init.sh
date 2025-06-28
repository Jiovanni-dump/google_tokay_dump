#!/vendor/bin/sh
#
# This script is for storage related init service including the below
#  - adjusting storage total size to the nearest power of 2.
#

ufs_size_prop="ro.boot.hardware.ufs"

ufs_size_str=`getprop "ro.boot.hardware.ufs"`
ufs_size=`echo "$ufs_size_str" | sed 's/[^0-9].*//'`
block_size=`getprop "ro.boot.hardware.cpu.pagesize"`

if [[ -z "$ufs_size" || -z "$block_size" ]]; then
	exit 1
fi

# Function to find the nearest LOWER power of 2 (make number 1000 from 1024)
nearest_lower_power_of_2() {
	local num=$1
	local power

	if [[ "$num" -le 0 ]]; then
		return 1
	fi

	if [[ "$num" -ge 1000 ]]; then
		power=1000
	else
		power=1
	fi

	while [[ "$((power * 2))" -le "$num" ]]; do
		power=$((power * 2))
	done

	echo "$power"
	return 0
}

diff_from_nearest_lower_power_of_2() {
	local num=$1
	local lower_power=$(nearest_lower_power_of_2 "$num")

	if [[ $? -ne 0 ]]; then
		return 1
	fi

	local twenty_percent=$((lower_power / 5))

	if [[ "$((num - lower_power))" -le "$twenty_percent" ]]; then
		local difference=$((num - lower_power))
		echo "$difference"
		return 0
	else
		return 1
	fi
}

difference=$(diff_from_nearest_lower_power_of_2 "$ufs_size")

if [[ $? -eq 0 ]] && [[ -e /dev/sys/fs/by-name/userdata/carve_out ]]; then
	reserved_blocks=$((difference * (1024 * 1024 * 1024 / block_size)))
	echo "1" > /dev/sys/fs/by-name/userdata/carve_out
	echo "$reserved_blocks" > /dev/sys/fs/by-name/userdata/reserved_blocks
fi

