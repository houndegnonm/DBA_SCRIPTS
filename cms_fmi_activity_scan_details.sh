user="mhoundegnon"
pwd="PasS123"

mysql -u$user -p$pwd -e"
use temp_db;

TRUNCATE TABLE temp_db.scans_fmi_details;

insert ignore into temp_db.scans_fmi_details
select
unique_id,
fmi,
date_scanned scan_date,
scan_type,
temp_db.get_retailer_by_kiosk(kiosk_id) retailer,
programs.id program_id,
program_scan_code program_code,
programs.short_description program_name,
placements.id placement_id,
placements.code placement_code,
placements.name placement_name,
IF(sample_dispensed=1,'YES','NO') sample_dispensed,
temp_db.fmi_opt_in(fmi , date_scanned , kiosk_id, program_scan_code , placement_code ) opt_in_ind,
skus.product_category_id,
product_categories.name product_category_name,
product_subcategories.id  product_sub_category_id,
product_subcategories.name product_subcategory_name,
curdate() db_created_at,
curdate() db_updated_at

FROM ods.ods_scan_data
LEFT JOIN ods.programs                                          ON programs.code=ods_scan_data.program_scan_code
LEFT JOIN ods.placements                                        ON placements.code=placement_code AND placements.program_id= programs.id
LEFT JOIN ods.placements_merchandises           ON placements_merchandises.placement_id=placements.id
LEFT JOIN ods.placements_merchandise_skus       ON placements_merchandise_skus.placements_merchandise_id=placements_merchandises.id
LEFT JOIN ods.skus                                                      ON placements_merchandise_skus.sku_id=skus.id
LEFT JOIN ods.product_categories                        ON skus.product_category_id=product_categories.id
LEFT JOIN ods.product_subcategories             ON product_subcategories.product_category_id=product_categories.id
WHERE fmi NOT IN (-1,-2)
"

mailx -v -A freeosk -s "CMS Phase Details 1 Done" -a /root/script/scans_by_fmi_temp.log  mikael.houndegnon@thefreeosk.com <<< "Done"
