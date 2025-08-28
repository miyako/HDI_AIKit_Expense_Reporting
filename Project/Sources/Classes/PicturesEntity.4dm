Class extends Entity

local Function get url() : Text
	
	var $blob : Blob
	var $base64 : Text
	If (This:C1470.picture#Null:C1517)
		$blob:=This:C1470.picture
		BASE64 ENCODE:C895($blob; $base64)
		return "data:;base64,"+$base64
	End if 