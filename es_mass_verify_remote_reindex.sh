#!/bin/bash
# This script requires es_remote_reindex_file.txt to be created in the same folder and must contain the list of the index from the old cluster
# This script also requires jq library in order to parse JSON output you can install it on your local machine with "brew install jq"

file="es_remote_reindex_file.txt"
username_old_cluster=''
password_old_cluster=''
hostname_old_cluster=''
hostname_remote_reindex=""

username_new_cluster=''
password_new_cluster=''
hostname_new_cluster=''

prefix_to_trim='v2_, v3_'
not_found_string="no such index"

echo "index  count_6.7  count_7.8"
while IFS= read -r index
do
  index_old_cluster=$index
  echo $index_old_cluster
  for prefix in $(echo $prefix_to_trim | sed "s/,/ /g")
  do
     # TRIM PREFIX
     index=${index#"$prefix"}
  done
  index_new_cluster=$index
  
  # GET INDEX INFO FROM OLD CLUSTER AND NEW CLUSTER
  new_cluster_index_info=$(curl -u $username_new_cluster:$password_new_cluster -XGET $hostname_new_cluster/_cat/indices/$index_new_cluster)
  old_cluster_index_info=$(curl -u $username_old_cluster:$password_old_cluster -XGET $hostname_old_cluster/_cat/indices/$index_old_cluster)  
  new_index_doc_count=$(echo $new_cluster_index_info | cut -d' ' -f 7)
  old_index_doc_count=$(echo $old_cluster_index_info | cut -d' ' -f 7)

  if [[ "$new_index_doc_count" == "$old_index_doc_count" ]]; then  
    echo "$index_old_cluster  $index_new_cluster  $old_index_doc_count  $new_index_doc_count equal" >> es_mas_verify.log
  else
    echo "$index_old_cluster  $index_new_cluster  $old_index_doc_count  $new_index_doc_count diff" >> es_mas_verify.log
  fi
  
done < "$file"
