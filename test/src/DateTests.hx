import utest.Assert;
import jsonmod.Json;

@:rtti
class ClassWithDate
{
    public var dt: Date;

    public function new() {}
}

class DateTests extends utest.Test
{
    public function testDate()
    {
        var obj = new ClassWithDate();
        obj.dt = new Date(2000, 0, 1, 0, 0, 0);
        var encoded = Json.encode(obj);

        var decoded = Json.parseTyped(encoded, ClassWithDate);
        Assert.isOfType(decoded, ClassWithDate);
        Assert.isOfType(decoded.dt, Date);

        Assert.equals(decoded.dt.getTime(), new Date(2000, 0, 1, 0, 0, 0).getTime());
    }
}