package jsonmod;

using StringTools;

class JsonParser
{
	var pos : Int;
	var json : String;
	var lastSymbolQuoted : Bool;//true if the last symbol was in quotes.
    var fileName : String;
	var currentLine : Int;
	var cache : Array<Dynamic>;
	var floatRegex : EReg;
	var intRegex : EReg;
	var strProcessor : String->Dynamic;

	public function new(vjson:String, vfileName="JSON Data", ?stringProcessor:String->Dynamic)
    {
		json = vjson;
		fileName = vfileName;
		currentLine = 1;
        lastSymbolQuoted = false;
		pos = 0;
		floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
		intRegex = ~/^-?[0-9]+$/;
		strProcessor = stringProcessor == null
						? defaultStringProcessor
						: stringProcessor;
		cache = new Array();
    }

    public function doParse() : Dynamic
    {
    	try
		{
			//determine if objector array
			return switch (getNextSymbol())
			{
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}
		catch (e:String)
		{
			throw fileName + " on line " + currentLine + ": " + e;
		}
	}

	private function doObject() : Dynamic
	{
		var o : Dynamic = { };
		var val : Dynamic ='';
		var key : String;
		var isClassOb = false;
		cache.push(o);
		while(pos < json.length)
		{
			key=getNextSymbol();
			if (key == "," && !lastSymbolQuoted)continue;
			if (key == "}" && !lastSymbolQuoted){
				//end of the object. Run the TJ_unserialize function if there is one
				if (isClassOb && #if flash9 try o.TJ_unserialize != null catch(e:Dynamic) false #elseif (cs || java) Reflect.hasField(o, "TJ_unserialize") #else o.TJ_unserialize != null #end) {
					o.TJ_unserialize();
				}
				return o;
			}

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
					var cls =Type.resolveClass(v);
					if (cls == null) throw "Invalid class name - " + v;
					o = Type.createEmptyInstance(cls);
				}
				cache.pop();
				cache.push(o);
				isClassOb = true;
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

	private function doArray() : Dynamic
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

	private function convertSymbolToProperType(symbol) : Dynamic
	{
		if (lastSymbolQuoted)
		{
			//value was in quotes, so it's a string.
			//look for reference prefix, return cached reference if it is
			if (StringTools.startsWith(symbol, Json.OBJECT_REFERENCE_PREFIX))
			{
				var idx : Int = Std.parseInt(symbol.substr(Json.OBJECT_REFERENCE_PREFIX.length));
				return cache[idx];
			}
			return symbol;//just a normal string so return it
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
	
	private function looksLikeFloat(s:String) : Bool
	{
		if (floatRegex.match(s)) return true;

		if (intRegex.match(s))
		{
			var f = Std.parseFloat(s);
			if (f > 2147483647.0 || f < -2147483648) return true;
		}
		return false;
	}

	private function looksLikeInt(s:String) : Bool
	{
		return intRegex.match(s);
	}

	private function getNextSymbol()
	{
		lastSymbolQuoted=false;
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
                            if (pos >= json.length)
                              throw "Unfinished UTF8 character";
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
				{//end of symbol, return it
					pos--;
					return symbol;
				}
				else
				{
					symbol+=c;
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
					inSymbol=true;
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
	
	private function defaultStringProcessor(str:String) : Dynamic
	{
		return str;
	}
}
