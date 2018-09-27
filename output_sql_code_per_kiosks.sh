user="mhoundegnon"
pwd="PasS123"

rm -rf /root/script/sql/*

mysql -u$user -p$pwd -se"SELECT distinct kiosk_id FROM temp_tables.users_stg" | while read kiosk_id; do
        # kiosk_id=171
	nb_row=$(mysql -u$user -p$pwd -se"SELECT count(*) FROM temp_tables.users_stg where kiosk_id='$kiosk_id'")
	first_row="true"
	file_name="kiosk_"$kiosk_id"_"$nb_row".sql"
	echo "
USE [Freeosk]
GO

ALTER TABLE [dbo].[users] DROP CONSTRAINT [DF_users_create_date]
GO

ALTER TABLE [dbo].[users] DROP CONSTRAINT [DF_users_modify_date]
GO

ALTER TABLE [dbo].[users] DROP CONSTRAINT [DF_users_needs_pairing]
GO

ALTER TABLE [dbo].[users] DROP CONSTRAINT [PK_users]
GO

IF EXISTS(select * from INFORMATION_SCHEMA.TABLES where table_name = 'old_users')
BEGIN
DROP TABLE [dbo].[old_users]
END
GO

EXEC sp_rename 'users', 'old_users';
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[freeosk_member_id] [bigint] NULL,
	[retailer_member_id] [varbinary](128) NULL,
	[email] [varbinary](128) NULL,
	[email_status] [varchar](50) NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL,
	[needs_pairing] [bit] NULL,
	[scan_type] [varchar](10) NULL,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[users] ADD CONSTRAINT [DF_users_create_date]  DEFAULT (getdate()) FOR [create_date]
GO

ALTER TABLE [dbo].[users] ADD CONSTRAINT [DF_users_modify_date]  DEFAULT (getdate()) FOR [modify_date]
GO

ALTER TABLE [dbo].[users] ADD CONSTRAINT [DF_users_needs_pairing]  DEFAULT ((1)) FOR [needs_pairing]
GO

" >> /root/script/sql/$file_name

	mysql -u$user -p$pwd -se"select
                                        user_freeosk_member_id as freeosk_member_id,
                                        concat('0x',hex(encrypted_scan_code)) as  retailer_member_id,
                                        concat('0x',hex(user_email)) as  email,
                                        email_status                     
                                from temp_tables.users_stg
                                WHERE kiosk_id='$kiosk_id' " | while read results; 
	do
		row=(${results[0]})
		

		echo "INSERT INTO freeosk.dbo.users VALUES (${row[0]},CONVERT(varbinary(128),'${row[1]}',1),CONVERT(varbinary(128),'${row[2]}',1),${row[3]},SYSDATETIME(),SYSDATETIME(),0,'SC');" >> /root/script/sql/$file_name;
	done

echo "
DECLARE @count AS INT
SELECT @count = COUNT(*) FROM users
DECLARE @comments AS VARCHAR(100) = 'The users table has ' + (CONVERT(VARCHAR(20), @count)) + ' record(s)'
EXEC dbo.spLogEvent 'other', NULL, 'User Table Rebuild', @comments, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL

IF NOT EXISTS(SELECT * FROM [settings] WHERE [setting]='UserTableRebuildRowCount')
    INSERT [settings] ([kiosk_id], [setting], [value], [type], [comments]) VALUES (NULL, N'UserTableRebuildRowCount', @count, N'Int', N'Record count after User table rebuild.')
ELSE
    UPDATE [settings] SET [value] = @count WHERE [setting] = 'UserTableRebuildRowCount'

GO	
" >> /root/script/sql/$file_name

done


