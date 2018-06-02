import jsonmod.Json;

@:rtti
class BaseClass
{
	public var varA = "a";
	
	@jsonIgnore
	public var varB = "b";
	
	public function new() {}
}

@:rtti
class ChildClass extends BaseClass
{
	public var varC = "c";
	
	@jsonIgnore
	public var varD = "d";
}

class ExtTests extends haxe.unit.TestCase
{
	public function testSimple()
	{
		var obj = new ChildClass();
		var s = Json.encode(obj);
		var obj2 = Json.parseTyped(s, ChildClass);
		
		assertTrue(Std.is(obj2, ChildClass));
		assertEquals(null, obj2.varD);
		assertEquals(null, obj2.varB);
		assertEquals("a", obj2.varA);
		assertEquals("c", obj2.varC);
	}
}
