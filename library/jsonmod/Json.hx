package jsonmod;

class Json
{
	public static var OBJECT_REFERENCE_PREFIX = "@~obRef#";
	
	/**
	    @param	json The JSON string to parse
	    @param	fileName String the file name to whic the JSON code belongs. Used for generating nice error messages.
	 **/
	 public static function parse(json:String, fileName="JSON Data", ?stringProcessor:String->Dynamic) : Dynamic
	{
        var t = new JsonParser(json, fileName, stringProcessor);
		return t.doParse();
	}
	
	/**
	   @param	obj The object to be serialized.
	   @param	style The style to use. Either an object implementing EncodeStyle interface or the strings 'fancy' or 'simple'.
	**/ 
	public static function encode(obj:Dynamic, ?style:EncodeStyle, ?customEncodeStyle:IEncodeStyle, useCache=true) : String
	{
		var t = new JsonEncoder(useCache);
		return t.doEncode(obj, style, customEncodeStyle);
	}
}
