#!/bin/bash
function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}
# Initialise EESSI
source /cvmfs/pilot.eessi-hpc.org/latest/init/bash > /dev/null
# Grab the date we do this and use that as out key for json output
date=$(date -I)
echo "{ \"$date\":["
json_array=()
for s1server in `grep CVMFS_SERVER_URL /etc/cvmfs/domain.d/eessi-hpc.org.conf | grep -o '".*"' | sed 's/"//g' | tr ';' '\n'`; do
    # Edit the config file to point to a single S1 option, e.g.,
    echo 'CVMFS_SERVER_URL="'"$s1server"'"' | sudo tee /etc/cvmfs/domain.d/eessi-hpc.org.local > /dev/null
    # Reconfigure CVMFS 
    sudo cvmfs_config setup
    # Wipe the cache and run the example (I used Tensorflow from github.com/EESSI/eessi-demo)
    sudo cvmfs_config wipecache >& /dev/null
    # Run the TensorFlow example
    cd ../TensorFlow
    # Just print the real time
    realtime=$({ ./run.sh > /dev/null ; } 2> >(grep real | awk '{print $2}'))
    KB_per_sec=$(cvmfs_config stat pilot.eessi-hpc.org | column -t -H 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20 | tail -1)
    # Print json output
    json_array+=("{\"$s1server\": [{\"time\":\"$realtime\"},{\"speed\":\"${KB_per_sec}KB/sec\"}]}")
done
join_by ,$'\n' "${json_array[@]}"
echo -e "\n]}"
