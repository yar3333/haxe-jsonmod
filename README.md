jsonmod
=======

JSON parser and encoder for Haxe. Based on TJSON library (by Jordan CM Wambaugh).

JSON format extended features:

 1. Single-quotes for strings.
 2. Identifiers not wrapped in quotes.
 3. C style comments support - `/*comment*/`.
 4. C++ style comments support - `//comment`.
 5. Dangling commas don't kill it (commas are even optional).


Features:

 * Typed parsing using `RTTI` (restore classes).
 * `@jsonIgnore` field meta to skip fields on serialization.
 * `Date` serialized as Float (used `Date.getTime()`).
 * In "typed" mode `Date` deserialized from Float (used `Date.fromTime()`).
 * Recursive self-references not supported (exception throws on serialization).


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
	@jsonIgnore // ignore `a` on serialization
	var a = 1;
	
	public var b = 2;
	
	public function new() {}
}

var str = Json.encode(new MyClass()); // "{b:2}"

// parse with classes support
var parsedObject = Json.parseTyped("{ a:20, b:10 }", MyClass); // MyClass { a:20, b:10 }

```
