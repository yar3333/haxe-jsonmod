import haxe.ds.StringMap;
import utest.Assert;
import jsonmod.Json;

@:rtti
class ClassWithMap
{
    public var myMap = new Map<String, NestedClass>();

    public function new() {}
}

class MapTests extends utest.Test
{
    public function testMap()
    {
        var obj = new ClassWithMap();
        obj.myMap.set("myKey", new NestedClass());

        var encoded = Json.encode(obj);
        Assert.equals("{\"myMap\":{\"myKey\":{\"myvar\":\"this works\"}}}", encoded);

        var decoded = Json.parseTyped(encoded, ClassWithMap);
        Assert.isOfType(decoded, ClassWithMap);
        Assert.isOfType(decoded.myMap, StringMap);
        Assert.isOfType(decoded.myMap.get("myKey"), NestedClass);
    }
}