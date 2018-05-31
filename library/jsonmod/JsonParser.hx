package jsonmod;

import haxe.rtti.Meta;
import haxe.rtti.Rtti;
import haxe.rtti.CType;
using StringTools;

class JsonParser
{
	var floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
	var intRegex = ~/^-?[0-9]+$/;
	
	var pos = 0;
	var lastSymbolQuoted = false;
	var currentLine = 1;

	var json : String;

	public function new(json:String)
    {
		this.json = json;
    }

    public function doParse() : Dynamic
    {
    	try
		{
			return switch (getNextSymbol())
			{
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}
		catch (e:String)
		{
			throw "JSON Data on line " + currentLine + ": " + e;
		}
	}
    
	public function doParseTyped<T:{}>(destObj:T) : T
	{
		var untypedSomething = doParse();
		mapObject(untypedSomething, destObj);
		return destObj;
	}

	function doObject() : Dynamic
	{
		var o : Dynamic = {};
		var val : Dynamic;
		
		while(pos < json.length)
		{
			var key = getNextSymbol();
			if (key == "," && !lastSymbolQuoted) continue;
			if (key == "}" && !lastSymbolQuoted) return o;
			
			var seperator = getNextSymbol();
			if (seperator != ":")
			{
				throw "Expected ':' but got '"+seperator+"' instead.";
			}
			
			var v = getNextSymbol();
			
			if (key == '_hxcls')
			{
				if (v.startsWith('Date@'))
				{
					o = Date.fromTime(Std.parseInt(v.substr(5)));
				}
				else
				{
					var cls = Type.resolveClass(v);
					if (cls == null) throw "Invalid class name - " + v;
					o = Type.createEmptyInstance(cls);
				}
				continue;
			}
			
			if (v == "{" && !lastSymbolQuoted)
			{
				val = doObject();
			}
			else if (v == "[" && !lastSymbolQuoted)
			{
				val = doArray();
			}
			else
			{
				val = convertSymbolToProperType(v);
			}
			Reflect.setField(o, key, val);
		}
		throw "Unexpected end of file. Expected '}'";
	}

	function doArray() : Dynamic
	{
		var a = new Array<Dynamic>();
		var val : Dynamic;
		while (pos < json.length)
		{
			val = getNextSymbol();
			if (val == ',' && !lastSymbolQuoted)
			{
				continue;
			}
			else if (val == ']' && !lastSymbolQuoted)
			{
				return a;
			}
			else if (val == "{" && !lastSymbolQuoted)
			{
				val = doObject();
			}
			else if (val == "[" && !lastSymbolQuoted)
			{
				val = doArray();
			}
			else
			{
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	function convertSymbolToProperType(symbol) : Dynamic
	{
		if (lastSymbolQuoted)
		{
			return symbol;
		}
		if (looksLikeFloat(symbol))
		{
			return Std.parseFloat(symbol);
		}
		if (looksLikeInt(symbol))
		{
			return Std.parseInt(symbol);
		}
		if (symbol.toLowerCase() == "true")
		{
			return true;
		}
		if (symbol.toLowerCase() == "false")
		{
			return false;
		}
		if (symbol.toLowerCase() == "null")
		{
			return null;
		}
		
		return symbol;
	}
	
	function looksLikeFloat(s:String) : Bool
	{
		if (floatRegex.match(s)) return true;
		
		if (intRegex.match(s))
		{
			var f = Std.parseFloat(s);
			if (f > 2147483647 || f < -2147483648) return true;
		}
		return false;
	}

	function looksLikeInt(s:String) : Bool
	{
		return intRegex.match(s);
	}

	function getNextSymbol() : String
	{
		lastSymbolQuoted = false;
		
		var c = '';
		var inQuote = false;
		var quoteType = "";
		var symbol = '';
		var inEscape = false;
		var inSymbol = false;
		var inLineComment = false;
		var inBlockComment = false;
		
		while(pos < json.length)
		{
			c = json.charAt(pos++);
			if (c == "\n" && !inSymbol) currentLine++;
			if (inLineComment)
			{
				if (c == "\n" || c == "\r")
				{
					inLineComment = false;
					pos++;
				}
				continue;
			}
			
			if (inBlockComment)
			{
				if (c == "*" && json.charAt(pos) == "/")
				{
					inBlockComment = false;
					pos++;
				}
				continue;
			}
			
			if (inQuote)
			{
				if (inEscape)
				{
					inEscape = false;
					if (c == "'" || c == '"')
					{
						symbol += c;
						continue;
					}
					if (c == "t")
					{
						symbol += "\t";
						continue;
					}
					if (c == "n")
					{
						symbol += "\n";
						continue;
					}
					if (c == "\\")
					{
						symbol += "\\";
						continue;
					}
					if (c == "r")
					{
						symbol += "\r";
						continue;
					}
					if (c == "/")
					{
						symbol += "/";
						continue;
					}
					
					if (c == "u")
					{
                        var hexValue = 0;
						
                        for (i in 0...4)
                        {
                            if (pos >= json.length) throw "Unfinished UTF8 character";
							
			                var nc = json.charCodeAt(pos++);
                            hexValue = hexValue << 4;
                            if (nc >= 48 && nc <= 57)// 0..9
                              hexValue += nc - 48;
                            else if (nc >= 65 && nc <= 70)// A..F
                              hexValue += 10 + nc - 65;
                            else if (nc >= 97 && nc <= 102)// a..f
                              hexValue += 10 + nc - 95;
                            else throw "Not a hex digit";
                        }
                        
						var utf = new haxe.Utf8();
						utf.addChar(hexValue);
						symbol += utf.toString();
                        
						continue;
					}
					
					throw "Invalid escape sequence '\\" + c + "'";
				}
				else
				{
					if (c == "\\")
					{
						inEscape = true;
						continue;
					}
					if (c == quoteType)
					{
						return symbol;
					}
					symbol += c;
					
					continue;
				}
			}
			
			//handle comments
			else if (c == "/")
			{
				var c2 = json.charAt(pos);
				//handle single line comments.
				//These can even interrupt a symbol.
				if (c2 == "/")
				{
					inLineComment = true;
					pos++;
					continue;
				}
				//handle block comments.
				//These can even interrupt a symbol.
				else if (c2 == "*")
				{
					inBlockComment = true;
					pos++;
					continue;
				}
			}
			
			if (inSymbol)
			{
				if (c == ' ' || c == "\n" || c == "\r" || c == "\t" || c == ',' || c == ":" || c == "}" || c == "]")
				{
					pos--;
					return symbol;
				}
				else
				{
					symbol += c;
					continue;
				}
			}
			else
			{
				if (c == ' ' || c == "\t" || c == "\n" || c == "\r")
				{
					continue;
				}
				
				if (c == "{" || c == "}" || c == "[" || c == "]" || c == "," || c == ":")
				{
					return c;
				}
				
				if (c == "'" || c == '"')
				{
					inQuote = true;
					quoteType = c;
					lastSymbolQuoted = true;
					continue;
				}
				else
				{
					inSymbol = true;
					symbol = c;
					continue;
				}
			}
		}// end of while. We have reached EOF if we are here.
		
		if (inQuote)
		{
			throw "Unexpected end of data. Expected ( " + quoteType + " )";
		}
		
		return symbol;
	}
	
	function mapObject(src:Dynamic, dest:{}) : Dynamic
	{
		var klass = Type.getClass(dest);
		var rtti = Rtti.getRtti(klass);
		
		switch (Type.typeof(src))
		{
			case Type.ValueType.TObject:
				for (fieldName in getInstanceFieldsToMap(dest))
				{
					if (Reflect.hasField(src, fieldName))
					{
						var value:Dynamic = Reflect.field(src, fieldName);
						
						var rttiField = rtti.fields.filter(function(x) return x.name == fieldName).first();
						
						switch (rttiField.type)
						{
							case CType.CClass(name, params):
								if (name == "Array")
								{
									Reflect.setField(dest, fieldName, mapArray(value, params));
								}
								else
								if (name == "String")
								{
									Reflect.setField(dest, fieldName, value);
								}
								else
								if (name == "Date")
								{
									Reflect.setField(dest, fieldName, Date.fromTime(value));
								}
								else
								{
									var subKlass = Type.resolveClass(name);
									Reflect.setField(dest, fieldName, mapObject(value, Type.createInstance(subKlass, [])));
								}
								
							default:
								Reflect.setField(dest, fieldName, Reflect.field(src, fieldName));
						}
					}
				}
				
			default:
				throw "Parsed value must be object.";
		}
		
		return dest;
	}
	
	function mapArray(src:Array<Dynamic>, params:List<CType>) : Array<Dynamic>
	{
		if (params.length != 1) return src;
		
		var subType = params.first();
		switch (subType)
		{
			case CType.CClass(name, params):
				if (name == "String") return src;
				if (name == "Array") return src.map(function(item) return mapArray(item, params));
				var klass = Type.resolveClass(name);
				return src.map(function(item) return mapObject(item, Type.createInstance(klass, [])));
				
			default:
				return src;
		}
	}
	
	function getInstanceFieldsToMap(obj:{}) : Array<String>
	{
		var klass = Type.getClass(obj);
		
		var r = Type.getInstanceFields(klass);
		
		var fieldsMeta = Meta.getFields(klass);
		for (fieldName in Reflect.fields(fieldsMeta))
		{
			if (Reflect.hasField(Reflect.field(fieldsMeta, fieldName), "jsonIgnore"))
			{
				r.remove(fieldName);
			}
		}
		
		return r;
	}
}
