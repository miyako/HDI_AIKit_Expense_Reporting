//%attributes = {"invisible":true,"preemptive":"capable"}
//If (False)
TRUNCATE TABLE:C1051([Pictures:1])
SET DATABASE PARAMETER:C642([Pictures:1]; Table sequence number:K37:31; 0)

var $picture : cs:C1710.PicturesEntity
var $file : 4D:C1709.File
For each ($file; Folder:C1567("/RESOURCES/files/").files(fk ignore invisible:K87:22))
	$picture:=ds:C1482.Pictures.new()
	$picture.picture:=$file.getContent()
	$picture.name:=$file.name
	$picture.codec:=$file.extension
	$picture.timestamp:=Timestamp:C1445
	$picture.save()
End for each 
//End if 

$APIKey:=ds:C1482.getAPIKey()