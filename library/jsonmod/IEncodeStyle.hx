package jsonmod;

interface IEncodeStyle
{
	public function beginObject(depth:Int) : String;
	public function endObject(depth:Int) : String;
	public function beginArray(depth:Int) : String;
	public function endArray(depth:Int) : String;
	public function firstEntry(depth:Int) : String;
	public function entrySeperator(depth:Int) : String;
	public function keyValueSeperator(depth:Int) : String;
}
