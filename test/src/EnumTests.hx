import utest.Assert;
import jsonmod.Json;

@:rtti
enum Colors
{
    red;
    green;
    blue;
}

@:rtti
class ClassWithEnum
{
    public var myEn = Colors.blue;

    public function new() {}
}

class EnumTests extends utest.Test
{
    public function testEnum()
    {
        var obj = new ClassWithEnum();
        var encoded = Json.encode(obj);
        Assert.equals("{\"myEn\":\"blue\"}", encoded);

        var decoded = Json.parseTyped(encoded, ClassWithEnum);
        Assert.isOfType(decoded, ClassWithEnum);
        Assert.equals(Colors.blue, decoded.myEn);
    }
}