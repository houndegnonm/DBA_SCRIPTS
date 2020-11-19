#!/bin/bash
# This script requires es_remote_reindex_file.txt to be created in the same folder and must contain the list of the index from the old cluster
# This script also requires jq library in order to parse JSON output you can install it on your local machine with "brew install jq"


file="task_list.txt"

username_new_cluster='sumgbai'
password_new_cluster='GkdERckjGxFpyg8Q'
hostname_new_cluster='https://elasticsearch-cdr.dialogtech.com'

while IFS= read -r task
do
  full_task_id=$(echo $task | jq ".task")
  task_id=${full_task_id#"\""}
  task_id=${task_id%"\""}

  task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)

  start_time=$(echo $task_info | jq ".task.start_time_in_millis")
  start_time=$((start_time / 1000))
  start_date=$(date -r $start_time  '+%m/%d/%Y')
  start_time=$(date -r $start_time  '+%H:%M:%S')

  duration=$(echo $task_info | jq ".task.running_time_in_nanos")
  error=$(echo $task_info | jq ".error")

  duration_second=$((duration / 1000000000))

  end_time=$(date -v +"$duration_second"S -jf %H:%M:%S  $start_time +%H:%M:%S )
  
  if [[ $error == "null" ]]; then
    echo "Successful $task_id start at : $start_date $start_time finish at $start_date $end_time  " >> es_task_status.log
  else 
        echo "failed $task_id start at : $start_date $start_time finish at $start_date $end_time  " >> es_task_status.log
  fi  
  
done < "$file"

628359
