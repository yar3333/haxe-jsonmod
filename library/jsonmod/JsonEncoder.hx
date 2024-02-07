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
				case EncodeStyle.Indented: encodeStyle = new IndentedStyle();
				case EncodeStyle.Custom(customStyle): encodeStyle = customStyle;
			}
		}
		else
		{
			encodeStyle = new SimpleStyle();
		}
		
		var buffer = new StringBuf();
		
		if (Std.isOfType(obj, Array) || Std.isOfType(obj, List))
		{
			buffer.add(encodeIterable(obj, encodeStyle, 0));
		}
		else if (Std.isOfType(obj, haxe.ds.StringMap))
		{
			buffer.add(encodeMap(obj, encodeStyle, 0));
		}
		else
		{
			buffer.add(encodeObject(obj, encodeStyle, 0));
		}
		
		return buffer.toString();
	}

	function encodeObject(obj:Dynamic, style:IEncodeStyle, depth:Int) : String
	{
		if (references.indexOf(obj) >= 0)
		{
			throw "JsonEncoder: recursive reference detected:\n\t" + references.concat([obj]).map(function(x) {
				var klass = Type.getClass(x);
				return klass == null ? "object" : Type.getClassName(klass);
			}).join("\n\t"); 
		}
		
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
	
	function encodeMap(obj:Map<Dynamic, Dynamic>, style:IEncodeStyle, depth:Int) : String
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
	
	function encodeIterable(obj:Iterable<Dynamic>, style:IEncodeStyle, depth:Int) : String
	{
		var buffer = new StringBuf();
		
		var it = obj.iterator();
		buffer.add(style.beginArray(depth, !it.hasNext()));
		
		var isFirstField = true;
		for (value in it)
		{
			buffer.add(isFirstField ? style.firstEntry(depth) : style.entrySeperator(depth));
			buffer.add(encodeValue(value, style, depth));
			
			isFirstField = false;
		}
		
		buffer.add(style.endArray(depth, isFirstField));
		
		return buffer.toString();
	}
	
	function encodeValue(value:Dynamic, style:IEncodeStyle, depth:Int) : String
	{
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float))
		{
			return value;
		}
		else if (Std.isOfType(value, Array) || Std.isOfType(value, List))
		{
			var v : Iterable<Dynamic> = value;
			return encodeIterable(v, style, depth + 1);
		}
		else if (Std.isOfType(value, haxe.ds.StringMap))
		{
			return encodeMap(value, style, depth + 1);
		}
		else if (Std.isOfType(value, String))
		{
			return '"' + Std.string(value).replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r").replace('"', '\\"') + '"';
		}
		else if (Std.isOfType(value, Bool))
		{
			return value;
		}
		else if (Std.isOfType(value, Date))
		{
			var dt = (cast value : Date);
            var ms = dt.getTime() % 1000;
            return '"' + dt.getUTCFullYear()
                + "-" + Std.string(dt.getUTCMonth() + 1).lpad("0", 2)
                + "-" + Std.string(dt.getUTCDate()).lpad("0", 2)
                + "T" + Std.string(dt.getUTCHours()).lpad("0", 2)
                + ":" + Std.string(dt.getUTCMinutes()).lpad("0", 2)
                + ":" + Std.string(dt.getUTCSeconds()).lpad("0", 2)
                + (ms != 0 ? "." + Std.string(ms).lpad("0", 3) : "")
                + "Z\"";
		}
		else if (Reflect.isObject(value))
		{
			return encodeObject(value, style, depth + 1);
		}
        else if (Reflect.isEnumValue(value))
        {
            return '"' + (cast value : EnumValue).getName() + '"';
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
		
		while (klass != null)
		{
			var fieldsMeta = Meta.getFields(klass);
			for (fieldName in Reflect.fields(fieldsMeta))
			{
				if (Reflect.hasField(Reflect.field(fieldsMeta, fieldName), "jsonIgnore"))
				{
					r.remove(fieldName);
				}
			}
			klass = Type.getSuperClass(klass);
		}
		
		return r;
	}
}
