import utest.Assert;
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

class ExtTests extends utest.Test
{
	public function testSimple()
	{
		var obj = new ChildClass();
		var s = Json.encode(obj);
		var obj2 = Json.parseTyped(s, ChildClass);
		
		Assert.isOfType(obj2, ChildClass);
		Assert.equals(null, obj2.varD);
		Assert.equals(null, obj2.varB);
		Assert.equals("a", obj2.varA);
		Assert.equals("c", obj2.varC);
	}
}
