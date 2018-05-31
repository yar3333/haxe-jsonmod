package jsonmod;

class FancyStyle implements IEncodeStyle
{
	public var tab(default, null) : String;
	
	public function new(tab = "    ")
	{
		this.tab = tab;
		charTimesNCache = [""];
	}
	
	public function beginObject(depth:Int) : String
	{
		return "{\n";
	}
	
	public function endObject(depth:Int) : String
	{
		return "\n"+charTimesN(depth)+"}";
	}
	
	public function beginArray(depth:Int) : String
	{
		return "[\n";
	}
	
	public function endArray(depth:Int) : String
	{
		return "\n"+charTimesN(depth)+"]";
	}
	
	public function firstEntry(depth:Int) : String
	{
		return charTimesN(depth + 1) + ' ';
	}
	
	public function entrySeperator(depth:Int) : String
	{
		return "\n"+charTimesN(depth+1)+",";
	}
	
	public function keyValueSeperator(depth:Int) : String
	{
		return " : ";
	}
	
	var charTimesNCache : Array<String>;
	function charTimesN(n:Int) : String
	{
		return n < charTimesNCache.length
			? charTimesNCache[n]
			: (charTimesNCache[n] = charTimesN(n-1) + tab);
	}
}

