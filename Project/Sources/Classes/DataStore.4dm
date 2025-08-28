Class extends DataStoreImplementation

exposed Function getDetails($pictureEntity : cs:C1710.PicturesEntity; $apiKey : Text; $fromWebCam : Boolean) : Object
	
	var $client:=cs:C1710.AIKit.OpenAI.new($apiKey)
	var $picture : Picture
	BLOB TO PICTURE:C682($pictureEntity.picture; $picture)
	$prompt:=\
		"領収書画像から経費精算に必要な項目と金額を読み取り、厳密なJSON形式で値を返しなさい。"+\
		"余計な注釈などは要りません。"+\
		"マークダウンは要りません。"+\
		"金額は非常に重要な情報ですからきちんと有効な値が読み取れるまでがんばってください。"+\
		"前後の空白も入れないでください。"+\
		"必ず以下の構造仕様で有効なJSONを返してください: {"+\
		"\"document_type\": \"領収書\" | \"注文書\"|\"請求書\" | \"その他\","+\
		"\"date\": \"日付, YYYY-MM-DDまたはDD-MM-YYYY形式, text or null\", "+\
		"\"vendor\": \"マーチャント名, text or null\", "+\
		"\"invoice_number\": \"国内のマーチャントであればT+11桁の数字からなるインボイス登録番号, "+\
		"それ以外は請求書番号等の識別番号, text, それらしいものが読み取れなければnull\","+\
		"\"currency\": \"通貨を示すJPY,EUR,EUR,USDのような3文字のtext, "+\
		"明記されていなければJPY, 読み取れなければnull\","+\
		"\"total_incl_tax\": \"国内のマーチャントで領収金額や合計金額が[税込]で明記されていればその金額, "+\
		"国内のマーチャントで合計金額が税込で明記されていなければ税抜金額と消費税額の合計, "+\
		"それ以外はtotalなどの合計金額,"+\
		"どうしても読み取れなければnull\","+\
		"\"total_excl_tax\": \"国内のマーチャントで税抜金額が明記されていればその金額, "+\
		"国内のマーチャントで合計金額しか明記されていなければその金額から消費税額（通常は10%だが明記されていれば8%）を差し引いた税抜金額, "+\
		"それ以外は明記されている税抜金額, 読み取れなければnull\","+\
		"\"tax\": 国内のマーチャントで消費税額が明記されていればその金額, "+\
		"非課税と明記されていれば0, "+\
		"国内のマーチャントで税込金額しか明記されていなければ消費税額（通常は10%だが明記されていれば8%）, "+\
		"それ以外は明記されているTVA/VATの合計, 読み取れなければnull\","+\
		"\"items\": [ { "+\
		"\"name\": \"string\","+\
		"\"quantity\": number or null,"+\
		"\"unit_price\": unit price in number or null,"+\
		"\"total_price\": total price in number or null } ] }"
	
	var $result:=$client.chat.vision.fromPicture($picture).prompt($prompt).choice.message.content
	var $parsedJSON : Object
	$parsedJSON:=JSON Parse:C1218($result; Is object:K8:27)
	
	If ($parsedJSON.date#Null:C1517)
		Case of 
			: (Value type:C1509($parsedJSON.date)=Is text:K8:3)
				ARRAY LONGINT:C221($pos; 0)
				ARRAY LONGINT:C221($len; 0)
				var $YYYY; $MM; $DD : Text
				Case of 
					: (Match regex:C1019("(\\d{4}).(\\d{1,2}).(\\d{1,2})"; $parsedJSON.date; 1; $pos; $len))
						$YYYY:=Substring:C12($parsedJSON.date; $pos{1}; $len{1})
						$MM:=Substring:C12($parsedJSON.date; $pos{2}; $len{2})
						$DD:=Substring:C12($parsedJSON.date; $pos{3}; $len{3})
					: (Match regex:C1019("(\\d{1,2}).(\\d{1,2}).(\\d{4})"; $parsedJSON.date; 1; $pos; $len))
						$YYYY:=Substring:C12($parsedJSON.date; $pos{3}; $len{3})
						$MM:=Substring:C12($parsedJSON.date; $pos{2}; $len{2})
						$DD:=Substring:C12($parsedJSON.date; $pos{1}; $len{1})
				End case 
				$parsedJSON.date:=Add to date:C393(!00-00-00!; Num:C11($YYYY); Num:C11($MM); Num:C11($DD))
		End case 
		$parsedJSON.date:=String:C10($parsedJSON.date; ISO date:K1:8; !00-00-00!)
	End if 
	
	If ($fromWebCam)
		var $entity : cs:C1710.PicturesEntity
		$entity:=ds:C1482.Pictures.new()
		$entity.picture:=$pictureEntity.picture
		$entity.timestamp:=Timestamp:C1445
		$entity.save()
	End if 
	
	return $parsedJSON
	
exposed Function getAPIKey : Text
	
	var $file : 4D:C1709.File
	$file:=Folder:C1567("/PACKAGE/").file("api.token")
	
	If ($file.exists)
		return $file.getText()
	End if 
	
exposed Function getInvoices : Collection
	
	var $pictures : cs:C1710.PicturesSelection
	$pictures:=This:C1470.Pictures.all().orderBy("timestamp desc")  //.slice(0; 3)
	
	return $pictures.toCollection("name,url,ID")
	
exposed Function getPicture($invoice : Object) : cs:C1710.PicturesEntity
	
	return ds:C1482.Pictures.get($invoice.ID)