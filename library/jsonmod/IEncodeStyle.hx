package jsonmod;

interface IEncodeStyle
{
	function beginObject(depth:Int) : String;
	function endObject(depth:Int) : String;
	function beginArray(depth:Int) : String;
	function endArray(depth:Int) : String;
	function firstEntry(depth:Int) : String;
	function entrySeperator(depth:Int) : String;
	function keyValueSeperator(depth:Int) : String;
}
