jsonmod
=======

JSON parser and encoder for Haxe. Based on TJSON library (by Jordan CM Wambaugh).

Supported JSON format:

 1. Single-quotes for strings.
 2. Identifiers not wrapped in quotes.
 3. C style comments support - `/*comment*/`.
 4. C++ style comments support - `//comment`.
 5. Dangling commas don't kill it (commas are even optional).


Features:

 * Typed parsing using `RTTI` (support classes, `Array` and `Date`).
 * `@jsonIgnore` field meta.
 * `Date` serialized/deserialized as Float (`Date.getTime()`/`Date.fromTime()`).
 * Recursive self-references not supported (exception throws on encoding).


Basic using
-----------

```haxe
import jsonmod.Json;
...
// parse string to object
var data = "{ key:'value' }";
var object = Json.parse(data);

// encode object to string
var json = Json.encode(object);
```


Advanced using
--------------

```haxe
@:rtti // need for Json.parseTyped() to detect field types
class MyClass
{
	@jsonIgnore
	var a = 1;
	
	public var b = 2;
	
	public function new() {}
}

var objToEncode = new MyClass();
objToEncode.b = 10;
var str = Json.encode(objToEncode); // "{b:10}"

// parse with classes support
var parsedObject = Json.parseTyped(str, new MyClass()); // MyClass { a:1, b:10 }

```
