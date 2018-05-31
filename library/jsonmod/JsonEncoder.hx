package jsonmod;

import haxe.rtti.Meta;
using StringTools;

class JsonEncoder
{
	var references = new Array<Dynamic>();

	public function new() {}

	public function doEncode(obj:Dynamic, ?style:EncodeStyle)
	{
		if (!Reflect.isObject(obj)) throw "Provided object is not an object.";
		
		var encodeStyle: IEncodeStyle;
		if (style != null)
		{
			switch (style)
			{
				case EncodeStyle.Simple: encodeStyle = new SimpleStyle();
				case EncodeStyle.Fancy: encodeStyle = new FancyStyle();
				case EncodeStyle.Custom(customStyle): encodeStyle = customStyle;
			}
		}
		else
		{
			encodeStyle = new SimpleStyle();
		}
		
		var buffer = new StringBuf();
		
		if (Std.is(obj, Array) || Std.is(obj, List))
		{
			buffer.add(encodeIterable(obj, encodeStyle, 0));
		}
		else if (Std.is(obj, haxe.ds.StringMap))
		{
			buffer.add(encodeMap(obj, encodeStyle, 0));
		}
		else
		{
			buffer.add(encodeObject(obj, encodeStyle, 0));
		}
		
		return buffer.toString();
	}

	private function encodeObject(obj:Dynamic, style:IEncodeStyle, depth:Int) : String
	{
		if (references.indexOf(obj) >= 0) throw "JsonEncoder: recursive reference detected.";
		
		references.push(obj);
		
		var buffer = new StringBuf();
		
		buffer.add(style.beginObject(depth));
		
		var isFirstField = true;
		for (field in getObjectFieldsToEncode(obj))
		{
			var value : Dynamic = Reflect.field(obj, field);
			var vStr : String = encodeValue(value, style, depth);
			if (vStr != null)
			{
				buffer.add(isFirstField ? style.firstEntry(depth) : style.entrySeperator(depth));
				buffer.add('"' + field + '"' + style.keyValueSeperator(depth) + Std.string(vStr));
				
				isFirstField = false;
			}
		}
		
		buffer.add(style.endObject(depth));
		
		references.pop();
		
		return buffer.toString();
	}
	
	private function encodeMap(obj:Map<Dynamic, Dynamic>, style:IEncodeStyle, depth:Int) : String
	{
		var buffer = new StringBuf();
		
		buffer.add(style.beginObject(depth));
		
		var isFirstField = true;
		for (field in obj.keys())
		{
			buffer.add(isFirstField ? style.firstEntry(depth) : style.entrySeperator(depth));
			buffer.add('"' + field + '"' + style.keyValueSeperator(depth));
			buffer.add(encodeValue(obj.get(field), style, depth));
			
			isFirstField = false;
		}
		
		buffer.add(style.endObject(depth));
		
		return buffer.toString();
	}
	
	private function encodeIterable(obj:Iterable<Dynamic>, style:IEncodeStyle, depth:Int) : String
	{
		var buffer = new StringBuf();
		
		buffer.add(style.beginArray(depth));
		
		var isFirstField = true;
		for (value in obj)
		{
			buffer.add(isFirstField ? style.firstEntry(depth) : style.entrySeperator(depth));
			buffer.add(encodeValue(value, style, depth));
			
			isFirstField = false;
		}
		
		buffer.add(style.endArray(depth));
		
		return buffer.toString();
	}
	
	private function encodeValue(value:Dynamic, style:IEncodeStyle, depth:Int) : String
	{
		if (Std.is(value, Int) || Std.is(value, Float))
		{
			return value;
		}
		else if (Std.is(value, Array) || Std.is(value, List))
		{
			var v : Iterable<Dynamic> = value;
			return encodeIterable(v, style, depth + 1);
		}
		else if (Std.is(value, haxe.ds.StringMap))
		{
			return encodeMap(value, style, depth + 1);
		}
		else if (Std.is(value, String))
		{
			return '"' + Std.string(value).replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r").replace('"', '\\"') + '"';
		}
		else if (Std.is(value, Bool))
		{
			return value;
		}
		else if (Std.is(value, Date))
		{
			return value.getTime();
		}
		else if (Reflect.isObject(value))
		{
			return encodeObject(value, style, depth + 1);
		}
		else if (value == null)
		{
			return "null";
		}
		else
		{
			return null;
		}
	}
	
	function getObjectFieldsToEncode(obj:Dynamic) : Array<String>
	{
		var getClassMethod = Reflect.field(obj, "getClass");
		var klass = getClassMethod != null ? Reflect.callMethod(obj, getClassMethod, []) : Type.getClass(obj);
		
		var r = Reflect.fields(obj);
		
		if (klass != null)
		{
			var fieldsMeta = Meta.getFields(klass);
			for (fieldName in Reflect.fields(fieldsMeta))
			{
				if (Reflect.hasField(Reflect.field(fieldsMeta, fieldName), "jsonIgnore"))
				{
					r.remove(fieldName);
				}
			}
		}
		
		return r;
	}
}
