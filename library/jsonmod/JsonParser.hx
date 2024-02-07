package jsonmod;

import haxe.EnumTools;
import haxe.Exception;
import haxe.rtti.Rtti;
import haxe.rtti.CType;
using StringTools;
using Lambda;

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

    public function parse(?klassWithRttiMeta:Class<Dynamic>) : Dynamic
    {
    	var type = klassWithRttiMeta != null ? CType.CClass(Type.getClassName(klassWithRttiMeta), new Array<CType>()) : null;
		
		try
		{
			switch (getNextSymbol())
			{
				case '{': return parseObject(type);
				case '[': return parseArray(type);
				case s: return convertSymbolToProperType(s, type);
			}
		}
		catch (e:String)
		{
			throw "JSON Data on line " + currentLine + ": " + e;
		}
	}
    
	function parseObject(type:CType) : Dynamic
	{
		var o : Dynamic;
		var rtti : Classdef = null;
        var mapValueType: CType = null;
        var dynamicType: CType = null;
		
		if (type != null)
		{
			switch (type)
			{
				case CType.CClass(name, params) if (name != "haxe.ds.Map"):
					var klass = Type.resolveClass(name);
					if (klass == null) throw "Can't resolve class '" + name + "'.";
					o = Type.createEmptyInstance(klass);
					rtti = Rtti.getRtti(klass);

                case CType.CClass(name, params) if (name == "haxe.ds.Map" && params != null && params.length == 2):
                    if (!params[0].match(CClass("String", []))) throw "Map with a String key is only supported (found '" + params[0] + "').";
                    mapValueType = params[1];
                    o = new Map<String, Dynamic>();

                case CType.CAbstract(name, params):
                    return parseObject(CType.CClass(name, params));

                case CType.CDynamic(t):
                    o = {};
                    dynamicType = t;
					
				default:
					throw "Expected " + type + ", but object found.";
			}
		}
		else
		{
			o = {};
		}
		
		var val : Dynamic;
		
		while(pos < json.length)
		{
			var key = getNextSymbol();
			if (key == "," && !lastSymbolQuoted) continue;
			if (key == "}" && !lastSymbolQuoted) return o;
			
			var separator = getNextSymbol();
			if (separator != ":")
			{
				throw "Expected ':' but got '" + separator + "' instead.";
			}
			
			var v = getNextSymbol();
			
			if (v == "{" && !lastSymbolQuoted)
			{
				val = parseObject(dynamicType ?? mapValueType ?? getFieldType(rtti, key));
			}
			else if (v == "[" && !lastSymbolQuoted)
			{
				val = parseArray(dynamicType ?? mapValueType ?? getFieldType(rtti, key));
			}
			else
			{
				val = convertSymbolToProperType(v, dynamicType ?? mapValueType ?? getFieldType(rtti, key));
			}

            if (mapValueType == null) Reflect.setField(o, key, val);
            else (cast o : Map<String, Dynamic>).set(key, val);
		}
		throw "Unexpected end of file. Expected '}'";
	}

	function parseArray(type:CType) : Dynamic
	{
		var a = new Array<Dynamic>();
		var itemType: CType = null;
		
		if (type != null)
		{
			switch (type)
			{
				case CType.CClass("Array", params):
					itemType = params[0];
					
				default:
					throw "Expected " + type + ", but array found.";
			}
		}
		
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
				val = parseObject(itemType);
			}
			else if (val == "[" && !lastSymbolQuoted)
			{
				val = parseArray(itemType);
			}
			else
			{
				val = convertSymbolToProperType(val, itemType);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	function convertSymbolToProperType(symbol:String, type:CType) : Dynamic
	{
		if (lastSymbolQuoted)
		{
			if (type == null) return symbol;
            return switch (type)
            { 
                case CType.CClass("Date", _): parseDate(symbol); 
                case CEnum(name, params): EnumTools.createByName(Type.resolveEnum(name), symbol);
                case _: symbol; 
            };
		}
		if (looksLikeFloat(symbol))
		{
			var f = Std.parseFloat(symbol);
			if (type == null) return f;
			return switch (type) { case CType.CClass("Date", _): Date.fromTime(f); case _: f; };
		}
		if (looksLikeInt(symbol))
		{
			var n = Std.parseInt(symbol);
			if (type == null) return n;
			return switch (type) { case CType.CClass("Date", _): Date.fromTime(n); case _: n; }
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
                        var hexValue : Int = 0;
						
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
                              hexValue += 10 + nc - 97;
                            else throw "Not a hex digit";
                        }
						
                        #if target.unicode
						symbol += String.fromCharCode(hexValue);
                        #else
                        var temp = new neko.Utf8();
                        temp.addChar(hexValue);
                        symbol += temp.toString();
                        #end
                        
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
	
	function getFieldType(rtti:Classdef, field:String) : CType
	{
		return rtti?.fields.find(x -> x.name == field)?.type;
	}

    static function parseDate(s:String) : Date
    {
        var reDate = ~/(\d{4})-(\d+)-(\d+)[ T](\d+):(\d+):(\d+(?:\.\d+)?)(Z|z|[-+]\d+:\d+)/;
        
        if (!reDate.match(s)) throw new Exception("Date format must be ISO (found: '" + s + "').");

        var secFloat = Std.parseFloat(reDate.matched(6));

        #if (js || flash || php || cpp || python)
        var f = DateTools.makeUtc
        (
            Std.parseInt(reDate.matched(1)), 
            Std.parseInt(reDate.matched(2)) - 1,
            Std.parseInt(reDate.matched(3)),
            Std.parseInt(reDate.matched(4)),
            Std.parseInt(reDate.matched(5)),
            Std.int(secFloat),
        );
        #else
        var tempDt = new Date
        (
            Std.parseInt(reDate.matched(1)), 
            Std.parseInt(reDate.matched(2)) - 1,
            Std.parseInt(reDate.matched(3)),
            Std.parseInt(reDate.matched(4)),
            Std.parseInt(reDate.matched(5)),
            Std.int(secFloat),
        );
        var f = tempDt.getTime() - tempDt.getTimezoneOffset() * 60000;
        #end
        f += Std.int(Math.round((secFloat - Std.int(secFloat)) * 1000));

        if (reDate.matched(7).startsWith("+"))
        {
            var hm = reDate.matched(7).substring(1).split(":");
            f -= Std.parseInt(hm[0]) * 3600000 + Std.parseInt(hm[1]) * 60000;
        }
        else
        if (reDate.matched(7).startsWith("-"))
        {
            var hm = reDate.matched(7).substring(1).split(":");
            f += Std.parseInt(hm[0]) * 3600000 + Std.parseInt(hm[1]) * 60000;
        }

        return Date.fromTime(f);
    }
}
