#!/bin/bash

# Check for pre-existing configuration
local_eessi_config="/etc/cvmfs/domain.d/eessi-hpc.org.local"
if [ -f $local_eessi_config ]; then
   echo "File $local_eessi_config exists, moving it temporarily"
   sudo mv $local_eessi_config ${local_eessi_config}.tmp
   restore_eessi_config=true
else
   echo "File $local_eessi_config does not exist."
   restore_eessi_config=false
fi

# Add the capability to clean up after ourselves
function cleanup()
{
  if [ "$restore_eessi_config" = true ] ; then
    echo "Restoring original $local_eessi_config"
    sudo mv ${local_eessi_config}.tmp $local_eessi_config
  else
    echo "Removing $local_eessi_config"
    sudo rm $local_eessi_config
  fi
  # disable our traps
  trap - SIGINT
  trap - EXIT
  # exit as normal
  echo "Finished cleaning up, exiting"
  exit
}
trap cleanup SIGINT
trap cleanup EXIT

# Function used to help stitch json objects together
function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

# Test a particular S1 and return a valid json object
function test_S1 {
    # Edit the config file to point to a single S1 option, e.g.,
    echo 'CVMFS_SERVER_URL="'"$1"'"' | sudo tee $local_eessi_config > /dev/null
    # Reconfigure CVMFS 
    sudo cvmfs_config setup
    # Wipe the cache and run the example (from github.com/EESSI/eessi-demo)
    sudo cvmfs_config wipecache >& /dev/null
    # Run the example
    cd $(dirname $(realpath $BASH_SOURCE))/../$2
    # Just print the real time
    realtime=$({ ./run.sh > /dev/null ; } 2> >(grep real | awk '{print $2}'))
    bandwidth=( $(cvmfs_config stat pilot.eessi-hpc.org | column -t -H 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20 ) )
    cache_usage=( $( cvmfs_config stat pilot.eessi-hpc.org | column -t -H 1,2,3,4,5,6,7,9,10,11,12,13,14,15,16,17,18,19,20 ))
    # Print json output
    echo -n "{\"$1\": {\"time\":\"$realtime\",\"speed\":\"${bandwidth[1]}\",\"speed_unit\":\"${bandwidth[0]}\",\"data\":\"${cache_usage[1]}\",\"data_unit\":\"${cache_usage[0]}\",\"application\":\"$2\",\"arch\":\"$EESSI_SOFTWARE_SUBDIR\" }}" 
}

# Initialise EESSI
source /cvmfs/pilot.eessi-hpc.org/latest/init/bash > /dev/null
# Grab the date we do this and use that as out key for json output
application="${APPLICATION:-TensorFlow}"
date=$(date -I)
json_array=()
for s1server in $(grep CVMFS_SERVER_URL /etc/cvmfs/domain.d/eessi-hpc.org.conf | grep -o '".*"' | sed 's/"//g' | tr ';' '\n'); do
json_array+=("$(test_S1 "$s1server" "$application")")
done
echo -e "{\"$date\":["
join_by ,$'\n' "${json_array[@]}"
echo -e "\n]}"
