Class extends DataStoreImplementation

exposed Function getDetails($pictureEntity : cs:C1710.PicturesEntity; $apiKey : Text) : Object
	var $client:=cs:C1710.AIKit.OpenAI.new($apiKey)
	var $blob:=$pictureEntity.picture
	var $base64Encoded : Text
	BASE64 ENCODE:C895($blob; $base64Encoded)
	$picture:="data:image/jpeg;base64,"+$base64Encoded
	$prompt:=\
		"You are an expert assistant in processing accounting documents. Analyze the image of the attached document (receipt, invoice, or purchase order)."+\
		"Return only a JSON object, without any explanation, without markdown tags, without commentary, and withou"+"t any line break before or after."+\
		"The JSON must be clean and follow this exact structure: { \"document_type\": \"receipt\" | \"invoice\" | \"purchase_order\", \"date\": \"MM-DD-YYYY\", \"vendor\": \"Merchant or company name\", \"invoice_number\": \"text or null\", \"curre"+"ncy\": \"EUR\" | \"USD\" | \"other\", \"total_incl_tax\": float or null, \"total_excl_tax\": float or null, \"tax\": float or null, \"items\": [ { \"name\": \"string\", \"quantity\": number or null, \"unit_price\": float or null, \"total_price\": float or null } ] } Remember:"+" no sentences, tags, or text should surround or precede the JSON. Just the pure JSON object, that’s all."
	var $result:=$client.chat.vision.create($picture).prompt($prompt).choice.message.content
	var $parsedJSON : Object
	$parsedJSON:=JSON Parse:C1218($result)
	return $parsedJSON
	
exposed Function getInvoices : Collection
	var invoicesFile : 4D:C1709.File
	invoicesFile:=File:C1566("/PACKAGE/Project/Sources/Shared/invoices.json")
	return JSON Parse:C1218(invoicesFile.getText())
	
	
exposed Function getPicture($pictureEntity : Object) : cs:C1710.PicturesEntity
	
	var $invoicesFile : 4D:C1709.File
	var text : Text:=Replace string:C233($pictureEntity.url; "$Shared/"; "")
	$invoicesFile:=File:C1566("/PACKAGE/Project/Sources/Shared/"+text)
	$imageBlob:=$invoicesFile.getContent()  // Lire le fichier image comme BLOB
	$pict:=ds:C1482.Pictures.new()
	$pict.picture:=$imageBlob
	return $pict