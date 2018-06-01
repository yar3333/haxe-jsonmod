package jsonmod;

typedef JsonEncodeStyle = EncodeStyle;

class Json
{
	public static function parse(json:String) : Dynamic
	{
        var t = new JsonParser(json);
		return t.parse();
	}
	
	public static function parseTyped<T>(json:String, klass:Class<T>) : T
	{
        var t = new JsonParser(json);
		return t.parse(klass);
	}
	
	public static function encode(obj:Dynamic, ?style:JsonEncodeStyle) : String
	{
		var t = new JsonEncoder();
		return t.doEncode(obj, style);
	}
}
