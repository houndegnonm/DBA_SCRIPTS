#!/bin/bash
# This script requires es_remote_reindex_file.txt to be created in the same folder and must contain the list of the index from the old cluster
# This script also requires jq library in order to parse JSON output you can install it on your local machine with "brew install jq"
usage() {
    echo "INVALID OPTION PLEASE SPECIFY ONE OF THE PARAMETER BELOW "
    echo "./$(basename $0) [full or incremental]"
}

type_reindex=$1

if [ $# -eq 0 ]
then
  usage
  exit 1
fi

file="es_remote_reindex_file.txt"
username_old_cluster='mikael_gbai'
password_old_cluster='9jj!8O!e94Sl4Yz6'
hostname_old_cluster='https://es-cdr-prod67x.dialogtech.com'
hostname_remote_reindex="https://es-cdr-prod67X.dialogtech.com:443"

username_new_cluster='sumgbai'
password_new_cluster='GkdERckjGxFpyg8Q'
hostname_new_cluster='https://elasticsearch-cdr.dialogtech.com'

prefix_to_trim='v1_, v2_, v3_'
not_found_string="no such index"



case $type_reindex in
    "incremental")
        echo "INCREMENTAL REMOTE REINDEXING"
        while IFS= read -r index_date
        do
            index=$(echo $index_date| cut -d' ' -f 1)
            index_old_cluster=$index
            for prefix in $(echo $prefix_to_trim | sed "s/,/ /g")
            do
               # TRIM PREFIX
               index=${index#"$prefix"}
            done
            index_new_cluster=$index

            last_indexed_date=$(echo $index_date| cut -d' ' -f 2)
            last_indexed_time=$(echo $index_date| cut -d' ' -f 3)
            last_indexed_date_time="$last_indexed_date $last_indexed_time"
            last_indexed_date_time=$(echo $last_indexed_date_time | tr -d '\n')

            #echo $last_indexed_date_time 
            #exit
            start_time=$(date "+%m/%d/%Y %T")
            echo " #### STARTING REMOTE REINDEXING 2nd Time $index_old_cluster => $index_new_cluster AT $start_time "
            echo "" >> es_remote_reindex_task.log
            
            echo " #### STARTING REMOTE REINDEXING 2nd Time $index_old_cluster => $index_new_cluster AT $start_time " >> es_remote_reindex_task.log
            curl -u $username_new_cluster:$password_new_cluster -XPOST $hostname_new_cluster/_reindex?wait_for_completion=false -H 'Content-Type: application/json'  -d "{
              \"source\": {
                \"remote\": {
                  \"host\": \"$hostname_remote_reindex\",
                  \"username\": \"$username_old_cluster\",
                  \"password\": \"$password_old_cluster\"
                },
                \"index\": \"$index_old_cluster\",
                \"size\": 1000,
                \"query\": {
                  \"range\": {
                      \"_doc_meta.last_indexed_date\": {
                          \"gte\": \"$last_indexed_date_time\",
                          \"time_zone\": \"-05:00\",
                          \"format\": \"MM/dd/yyyy HH:mm:ss\"
                      }
                  }
                }
                
              },
              \"dest\": {
                \"index\": \"$index_new_cluster\",
                \"version_type\": \"external\"
              },
              \"conflicts\": \"proceed\"
            }" >> es_remote_reindex_task.log
            
           # ABOVE COMMAND WILL PRINT THE TASK ID INTO THE FILE
           # WE WILL NEXT CAT THAT LINE TO CHECK THE PROGRESS OF STATUS
           full_task_id=$(tail -1 es_remote_reindex_task.log | jq ".task")
           task_id=${full_task_id#"\""}
           task_id=${task_id%"\""}
           
           task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
           check_task_progress=$(echo $task_info | jq ".completed")

           while [[ "$check_task_progress" != "true" ]]; do
             if [[ "$check_task_progress" == "true" ]]; then  
               # Task Complete 
               end_time=$(date "+%m/%d/%Y %T")
               echo  "END OF TASK $full_task_id  AT $end_time " >> es_remote_reindex_task.log
             else
               sleep 10
             fi
             task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
             check_task_progress=$(echo $task_info | jq ".completed")
           done 
           echo "" >> es_remote_reindex_task.log
           end_time=$(date "+%m/%d/%Y %T")

           error=$(echo $task_info | jq ".error")
           if [[ $error == "null" ]]; then
              echo "#### SUCCESS - END OF 2nd REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
           else 
              echo "#### FAIL    - END OF 2nd REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
           fi  

           
          
        done < "$file"
        exit
    ;;
    "full")
        echo "FULL REMOTE REINDEXING"
        
        while IFS= read -r index
        do
          index_old_cluster=$index
          for prefix in $(echo $prefix_to_trim | sed "s/,/ /g")
          do
             # TRIM PREFIX
             index=${index#"$prefix"}
          done
          index_new_cluster=$index
          
          echo "$index_old_cluster => $index_new_cluster"
          # GET INDEX INFO FROM OLD CLUSTER AND NEW CLUSTER
          new_cluster_index_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_cat/indices/$index_new_cluster)
          old_cluster_index_info=$(curl -u $username_old_cluster:$password_old_cluster -XGET $hostname_old_cluster/_cat/indices/$index_old_cluster)  
          #echo $new_cluster_index_info
          #echo $old_cluster_index_info
          #exit
          if [[ "$new_cluster_index_info" == *"$not_found_string"* ]]; then
            start_time=$(date "+%m/%d/%Y %T")
            echo "INDEX $index_new_cluster NOT EXIST ON 7.8 CLUSTER"
            echo " CREATING NEW INDEX $index_new_cluster "
            curl -u $username_new_cluster:$password_new_cluster -XPUT $hostname_new_cluster/$index_new_cluster -H 'Content-Type: application/json'  -d '{
              "settings": {
                "index": {
            "refresh_interval": -1,
              "number_of_replicas": 0
                }
              } 
            }'
            new_cluster_index_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_cat/indices/$index_new_cluster)
            index_name_created=$(echo $new_cluster_index_info | cut -d' ' -f 3)
            #echo "$index_name_created  $index_new_cluster"
            #exit
            # CHECK IF INDEX SUCCESSFULY CREATED
            if [[ "$index_name_created" == "$index_new_cluster" ]]; then
               start_time=$(date "+%m/%d/%Y %T")
               echo "" >> es_remote_reindex_task.log
               echo " #### NEW INDEX $index_new_cluster SUCCESSFULLY CREATED" >> es_remote_reindex_task.log
               echo " #### STARTING REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $start_time " >> es_remote_reindex_task.log
                curl -u $username_new_cluster:$password_new_cluster -XPOST $hostname_new_cluster/_reindex?wait_for_completion=false -H 'Content-Type: application/json'  -d '{
                  "source": {
                    "remote": {
                      "host": "'$hostname_remote_reindex'",
                      "username": "'$username_old_cluster'",
                      "password": "'$password_old_cluster'"
                    },
                    "index": "'$index_old_cluster'",
                    "size": 500
                  },
                  "dest": {
                    "index": "'$index_new_cluster'",
                    "version_type": "external"
                  },
                  "conflicts": "proceed"
                }' >> es_remote_reindex_task.log
               # ABOVE COMMAND WILL PRINT THE TASK ID INTO THE FILE
               # WE WILL NEXT CAT THAT LINE TO CHECK THE PROGRESS OF STATUS
               full_task_id=$(tail -1 es_remote_reindex_task.log | jq ".task")
               task_id=${full_task_id#"\""}
               task_id=${task_id%"\""}
               new_cluster_index_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_cat/indices/$index_new_cluster) 
               new_index_doc_count=$(echo $new_cluster_index_info | cut -d' ' -f 7)
               old_index_doc_count=$(echo $old_cluster_index_info | cut -d' ' -f 7)
               
               task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
               check_task_progress=$(echo $task_info | jq ".completed")

               while [[ "$check_task_progress" != "true" ]]; do
                 new_cluster_index_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_cat/indices/$index_new_cluster)
                 new_index_doc_count=$(echo $new_cluster_index_info | cut -d' ' -f 7)

                 if [[ "$check_task_progress" == "true" ]]; then  
                   # Task Complete 
                   end_time=$(date "+%m/%d/%Y %T")
                   echo  "END OF TASK $full_task_id  AT $end_time - DOCUMENT COUNT $new_index_doc_count / $old_index_doc_count" >> es_remote_reindex_task.log
                 else
                   sleep 10
                 fi

                 task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
                 check_task_progress=$(echo $task_info | jq ".completed")
                 
                 echo "$new_index_doc_count / $old_index_doc_count"
               done 
               
               end_time=$(date "+%m/%d/%Y %T")
               echo "DOCUMENT COUNT MATCH $new_index_doc_count / $old_index_doc_count" >> es_remote_reindex_task.log

               error=$(echo $task_info | jq ".error")
               if [[ $error == "null" ]]; then
                  echo "#### SUCCESS - END OF REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
               else 
                  echo "#### FAIL - END OF REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
               fi  
               
               # change the setting when re-index is done
               curl -u $username_new_cluster:$password_new_cluster -XPUT $hostname_new_cluster/$index_new_cluster/_settings -H 'Content-Type: application/json'  -d '{
                 "number_of_replicas": 1,
                 "refresh_interval": null,
                 "routing": {
                   "allocation": {
                     "exclude": {
                       "data_tier": "hot"
                      },
                     "require": {
                        "data_tier": ""
                     }
                   }
                 }
               }'

               end_time=$(date "+%m/%d/%Y %T")
               echo "#### END OF SETTING CHANGE $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
               echo "" >> es_remote_reindex_task.log
               # Done Here we will send an email notification
                
            else
              echo "FAIL TO CREATE INDEX $index_new_cluster, INVESTIGATE !!!! YOU CAN SKIP BY REMOVING THE INDEX FROM THE INPUT FILE" >> es_remote_reindex_task.log
              exit
            fi
          else 
              echo " #### STARTING REMOTE REINDEXING 2nd Time $index_old_cluster => $index_new_cluster AT $start_time "
              start_time=$(date "+%m/%d/%Y %T")
              echo "" >> es_remote_reindex_task.log
              
              echo " #### STARTING REMOTE REINDEXING 2nd Time $index_old_cluster => $index_new_cluster AT $start_time " >> es_remote_reindex_task.log
              curl -u $username_new_cluster:$password_new_cluster -XPOST $hostname_new_cluster/_reindex?wait_for_completion=false -H 'Content-Type: application/json'  -d '{
                "source": {
                  "remote": {
                    "host": "'$hostname_remote_reindex'",
                    "username": "'$username_old_cluster'",
                    "password": "'$password_old_cluster'"
                  },
                  "index": "'$index_old_cluster'",
                  "size": 1000
                },
                "dest": {
                  "index": "'$index_new_cluster'",
                  "version_type": "external"
                },
                "conflicts": "proceed"
              }' >> es_remote_reindex_task.log
             # ABOVE COMMAND WILL PRINT THE TASK ID INTO THE FILE
             # WE WILL NEXT CAT THAT LINE TO CHECK THE PROGRESS OF STATUS
             full_task_id=$(tail -1 es_remote_reindex_task.log | jq ".task")
             task_id=${full_task_id#"\""}
             task_id=${task_id%"\""}
             
             task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
             check_task_progress=$(echo $task_info | jq ".completed")

             while [[ "$check_task_progress" != "true" ]]; do
               if [[ "$check_task_progress" == "true" ]]; then  
                 # Task Complete 
                 end_time=$(date "+%m/%d/%Y %T")
                 echo  "END OF TASK $full_task_id  AT $end_time " >> es_remote_reindex_task.log
               else
                 sleep 10
               fi
               task_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_tasks/$task_id)
               check_task_progress=$(echo $task_info | jq ".completed")
             done 
             echo "" >> es_remote_reindex_task.log
             end_time=$(date "+%m/%d/%Y %T")

             error=$(echo $task_info | jq ".error")
             if [[ $error == "null" ]]; then
                echo "#### SUCCESS - END OF 2nd REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
             else 
                echo "#### FAIL - END OF 2nd REMOTE REINDEXING $index_old_cluster => $index_new_cluster AT $end_time" >> es_remote_reindex_task.log
             fi  
             
          fi 
          
        done < "$file"
        exit
    ;;  
    *) 
      echo "INVALID OPTION"
      exit 0
    ;;
esac




