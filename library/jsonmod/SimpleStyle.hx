package jsonmod;

class SimpleStyle implements IEncodeStyle
{
	public function new() {}
	
	public function beginObject(depth:Int) : String
	{
		return "{";
	}
	
	public function endObject(depth:Int) : String
	{
		return "}";
	}
	
	public function beginArray(depth:Int, empty:Bool) : String
	{
		return "[";
	}
	
	public function endArray(depth:Int, empty:Bool) : String
	{
		return "]";
	}
	
	public function firstEntry(depth:Int) : String
	{
		return "";
	}
	
	public function entrySeperator(depth:Int) : String
	{
		return ",";
	}
	
	public function keyValueSeperator(depth:Int) : String
	{
		return ":";
	}
}