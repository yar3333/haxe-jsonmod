package jsonmod;

typedef JsonEncodeStyle = EncodeStyle;

class Json
{
	/**
	    @param	json JSON string to parse.
	**/
	public static function parse(json:String) : Dynamic
	{
        var t = new JsonParser(json);
		return t.doParse();
	}
	
	/**
	    @param	json JSON string to parse.
	    @param	fileName Used for generating nice error messages.
	**/
	public static function parseTyped<T:{}>(json:String, destObj:T) : T
	{
        var t = new JsonParser(json);
		return t.doParseTyped(destObj);
	}
	
	/**
	   @param	obj The object to be serialized.
	   @param	style The style to use.
	**/ 
	public static function encode(obj:Dynamic, ?style:JsonEncodeStyle) : String
	{
		var t = new JsonEncoder();
		return t.doEncode(obj, style);
	}
}
