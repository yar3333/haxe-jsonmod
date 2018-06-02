package jsonmod;

interface IEncodeStyle
{
	function beginObject(depth:Int) : String;
	function endObject(depth:Int) : String;
	function beginArray(depth:Int, empty:Bool) : String;
	function endArray(depth:Int, empty:Bool) : String;
	function firstEntry(depth:Int) : String;
	function entrySeperator(depth:Int) : String;
	function keyValueSeperator(depth:Int) : String;
}
