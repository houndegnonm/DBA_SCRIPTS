#!/bin/bash
# This script requires es_sid_list_reindex_file.txt to be created in the same folder and must contain the list of the index from the old cluster
# This script also requires jq library in order to parse JSON output you can install it on your local machine with "brew install jq"


file="es_sid_list_reindex_file.txt"
username_old_cluster='mikael_gbai'
password_old_cluster='9jj!8O!e94Sl4Yz6'
hostname_old_cluster='https://es-cdr-prod67x.dialogtech.com'
hostname_remote_reindex="https://es-cdr-prod67X.dialogtech.com:443"

username_new_cluster='sumgbai'
password_new_cluster='.YP}4R4:sx>.frTL'
hostname_new_cluster='https://elasticsearch-cdr.dialogtech.com'
i=0
sid_list=""
while IFS= read -r sid
do
  if [[ "$i" == "668" ]]; then
    echo $sid
    sid_list=${sid_list%", "}
    
    start_time=$(date "+%m/%d/%Y %T")
    echo "" >> es_sid_list_reindex_task.log
    echo " #### STARTING REMOTE REINDEXING  AT $start_time " >> es_sid_list_reindex_task.log
    curl -u $username_new_cluster:$password_new_cluster -XPOST $hostname_new_cluster/_reindex?wait_for_completion=false -H 'Content-Type: application/json'  -d "{
      \"source\": {
        \"remote\": {
          \"host\": \"$hostname_remote_reindex\",
          \"username\": \"$username_old_cluster\",
          \"password\": \"$password_old_cluster\"
        },
        \"index\": \"v3_cdr_calls_201701\",
        \"size\": 1000,
        \"query\": {
          \"terms\": {
            \"sid\": [$sid_list]
          }
        }
     },
     \"dest\": {
        \"index\": \"reindex_test_cdr_calls_201701\",
        \"version_type\": \"external\"
      },
      \"conflicts\": \"proceed\"
    }" >> es_sid_list_reindex_task.log
    
    end_time=$(date "+%m/%d/%Y %T")
    echo " #### END REMOTE REINDEXING SUCCESS  AT $end_time " >> es_sid_list_reindex_task.log 

    i=0
    sid_list=""
    sid_list+="\"${sid}\", "
    
  else 
   sid_list+="\"${sid}\", "
  fi

  i=$((i+1))
done < "$file"
