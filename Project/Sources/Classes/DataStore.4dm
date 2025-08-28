Class extends DataStoreImplementation

exposed Function getDetails($pictureEntity : cs:C1710.PicturesEntity; $apiKey : Text) : Object
	var $client:=cs:C1710.AIKit.OpenAI.new($apiKey)
	var $picture : Picture
	BLOB TO PICTURE:C682($pictureEntity.picture; $picture)
	$prompt:=\
		"領収書画像から経費精算に必要な項目と金額を読み取り、厳密なJSON形式で値を返しなさい。"+\
		"余計な注釈などは要りません。"+\
		"マークダウンは要りません。"+\
		"前後の空白も入れないでください。"+\
		"必ず以下の構造仕様で有効なJSONを返してください: {"+\
		"\"document_type\": \"領収書\" | \"注文書\"|\"請求書\" | \"その他\","+\
		"\"date\": \"日付, text or null\", "+\
		"\"vendor\": \"マーチャント名, text or null\", "+\
		"\"invoice_number\": \"国内のマーチャントであればTから始まるインボイス登録番号のtext, それ以外は請求書番号等の識別番号のtext, それらしいものが読み取れなければnull\","+\
		"\"currency\": \"通貨を示すJPY,EUR,EUR,USDのような3文字のtext, 明記されていなければJPY, 読み取れなければnull\","+\
		"\"total_incl_tax\": \"合計金額が明記されていればその金額, 読み取れなければnull\","+\
		"\"total_excl_tax\": \"国内のマーチャントで税抜金額が明記されていればその金額, 国内のマーチャントで合計金額しか明記されていなければその金額から消費税額（通常は10%だが明記されてい"+"れば8%）を差し引いた税抜金額, それ以外は明記されている税抜金額, 読み取れなければnull\","+\
		"\"tax\": 国内のマーチャントで消費税額が明記されていればその金額, 非課税と明記されていれば0, 国内のマーチャントで税込金額しか明記されていなければ消費税額（通常は10%だが明記さ"+"れていれば8%）, それ以外は明記されている税額, 読み取れなければnull\","+\
		"\"items\": [ { "+\
		"\"name\": \"string\","+\
		"\"quantity\": number or null,"+\
		"\"unit_price\": unit price in number or null,"+\
		"\"total_price\": total price in number or null } ] }"
	var $result:=$client.chat.vision.fromPicture($picture).prompt($prompt).choice.message.content
	var $parsedJSON : Object
	$parsedJSON:=JSON Parse:C1218($result)
	
	If ($parsedJSON.date#Null:C1517)
		$parsedJSON.date:=String:C10(Date:C102($parsedJSON.date); ISO date:K1:8; !00-00-00!)
	End if 
	
	return $parsedJSON
	
exposed Function getInvoices : Collection
	
	var $uploadedInvoicesFile : 4D:C1709.File
	$uploadedInvoicesFile:=File:C1566("/PACKAGE/Project/Sources/Shared/invoices.json")
	If ($uploadedInvoicesFile.exists)
		return JSON Parse:C1218($uploadedInvoicesFile.getText(); Is collection:K8:32)
	End if 
	
	return []
	
exposed Function getPicture($pictureEntity : Object) : cs:C1710.PicturesEntity
	
	var $invoicesFile : 4D:C1709.File
	var text : Text:=Replace string:C233($pictureEntity.url; "$Shared/"; "")
	$invoicesFile:=File:C1566("/PACKAGE/Project/Sources/Shared/"+text)
	$imageBlob:=$invoicesFile.getContent()  // Lire le fichier image comme BLOB
	$pict:=ds:C1482.Pictures.new()
	$pict.picture:=$imageBlob
	return $pict