mysql -u"mhoundegnon" -p"PasS123" -e "call temp_db.sp_rebuild_daily_fmi(7)"

mailx -v -A freeosk -s "CMS Daily Update for $(date +'%m/%d/%Y') "  db_support@thefreeosk.com mikael.houndegnon@thefreeosk.com <<< "CMS Data has been successfully updated for $(date +'%m/%d/%Y') "

