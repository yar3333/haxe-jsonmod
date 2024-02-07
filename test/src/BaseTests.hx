import utest.Assert;
import jsonmod.Json;
import sys.io.File;

@:rtti
class TestClass
{
	var priv = 'this is private';
	
	public var pub = 'this is public';
	public var subObj : NestedClass;
	public var list : Array<String>;
	@jsonIgnore
	public var dontSerialize = 'this wont be serialized';
    public var aDate : Date;
    public var timestamp : Float;
	public var varProp(default, null) : String = "this is varProp";
	
	public function new()
	{
		subObj = new NestedClass();
		list = new Array();
        aDate = Date.now();
        timestamp = aDate.getTime();
		list.push("hello");
	}
	
	public function test()
	{
		return "yep";
	}
	
	public function setPriv(v:String)
	{
		priv = v;
	}
	
	public function getPriv()
	{
		return priv;
	}
}




class BaseTests extends utest.Test
{
	public function testSimple()
	{
		var res = Json.parse("{key:'value'}");
		Assert.equals('value', res.key);
		
		var res = Json.parse("[]");
		Assert.isOfType(res, Array);
		Assert.equals(0, res.length);
		
		var res = Json.parse("123");
		Assert.equals(123, res);
		
		var res = Json.parse("123.4");
		Assert.equals(123.4, res);
		
		var res = Json.parse('"123.4"');
		Assert.equals("123.4", res);
		
		var res = Json.parse("true");
		Assert.equals(true, res);
		
        var res = Json.parse("false");
		Assert.equals(false, res);
		
		var res = Json.parse("null");
		Assert.equals(null, res);
	}
	
	public function testComplex()
	{
		var data = '/* 
			Json test file
			this file is used for testing the Json parser.
			Json is the Tolerant JSON parser.
			*/
			{
				keyWithNoString:
				{
					\'keyWithSingleQuote\' : "value with a
					newline in the middle!"
					, k2:300
					"key with spaces": "key 3"
				}
				// this is a single line comment

				"arrayWithNoCommaBeforeIt": [ 1,-3.2, 2,.45, { oneKey:oneValue } ]
				, arrayWithObj:
					[
						{ key:aValue }
						{ key2:aValue2 }
					]
				, boolValue: true
				,"falseValue": false

				,"test":"\\/blah"

,"utf":"\\u0410\\u0411\\u0412\\u0413\\u0414 \\u0430\\u0431\\u0432\\u0433\\u0434"
,"arrayWithEmptyString":[
                	"test1"
                	,""
                ]
			}';
		var o = Json.parse(data);
		//trace(Std.string(o));
		Assert.equals("value with a
					newline in the middle!", o.keyWithNoString.keyWithSingleQuote);
		Assert.equals(300, Reflect.field(o.keyWithNoString,'k2'));
		Assert.equals("key 3", Reflect.field(o.keyWithNoString,'key with spaces'));
		Assert.equals(-3.2, o.arrayWithNoCommaBeforeIt[1]);
		Assert.equals(1.0, o.arrayWithNoCommaBeforeIt[0]);
		Assert.equals(0.45, o.arrayWithNoCommaBeforeIt[3]);
		Assert.equals("aValue2", o.arrayWithObj[1].key2);
		Assert.equals(true, o.boolValue);
		Assert.equals(false, o.falseValue);
		Assert.equals("АБВГД абвгд", o.utf);
	}
	
	public function testEncodeObject()
	{
		var case0 = '{"key":"value","key2":{"anotherKey":"another\\nValue"}}';
		var case1 = '{"key2":{"anotherKey":"another\\nValue"},"key":"value"}';
        Assert.allows([case0, case1], Json.encode({key:'value', key2:{ anotherKey:"another\nValue" }}));
	}
	
	public function testEncodeArray()
	{
		Assert.equals('[1,2,3,4,[10,10,{"myKey":"My\\nValue"}]]', Json.encode([1, 2, 3, 4,[10, 10,{ myKey:"My\nValue" }]]));
	}
	
	public function testEncodeMap()
	{
		Assert.equals('{"key":{"newKey":"value"},"key2":{"anotherKey":"another\\nValue"}}',
		    Json.encode([ "key" => [ "newKey" => "value" ], "key2" => [ "anotherKey" => "another\nValue" ] ]));
	}
	
	public function testEncodeList()
	{
		var list = new Array<Dynamic>();
		list.push("test");
		list.push({ key:'myObject', intval:31 });
		list.push([1, 2, 3, 4]);
		var sublist = new Array<Dynamic>();
		sublist.push(1);
		sublist.push("two");
		sublist.push(new Array<Dynamic>());
		list.push(sublist);
		Assert.equals('["test",{"key":"myObject","intval":31},[1,2,3,4],[1,"two",[]]]', Json.encode(list));
	}
	
	public function testFullCircleObject()
	{
		var origObj =
		{
			 '1':'a'
			,'2':'b'
			,anArray:
			 [{
				 objectKey:'objectValue'
				,anotherKey:'anotherValue'
			 }]
			, anotherArray:
			[
				"this is a string in a sub array"
				,"next will be a float"
					
			]
		};
		
		//test simple style
		var jsonString = Json.encode(origObj);
		var generatedObj = Json.parse(jsonString);
		Assert.equals('a',Reflect.field(generatedObj,'1'));

		Assert.equals('anotherValue',Reflect.field(Reflect.field(generatedObj,'anArray')[0],'anotherKey'));

		//test fancy style
		var jsonString = Json.encode(origObj, JsonEncodeStyle.Fancy);
		var generatedObj = Json.parse(jsonString);
		Assert.equals('a',Reflect.field(generatedObj,'1'));
		Assert.equals('anotherValue',Reflect.field(Reflect.field(generatedObj,'anArray')[0],'anotherKey'));
	}
	
	public function testCrazyCharacters()
	{
		var origObj = {
			"str":"!@#$%^&*()_+\"'/.,\\;':{}"
		}
		var jsonString = Json.encode(origObj);
		var generatedObj = Json.parse(jsonString);
		Assert.equals(origObj.str, generatedObj.str);
	}
	
    public function testUtf8Chars()
    {
      var s = '{"str":"\\u0410\\u0411\\u0412\\u0413\\u0414 \\u0430\\u0431\\u0432\\u0433\\u0434"}';
      var o = Json.parse(s);
      Assert.equals(o.str, "АБВГД абвгд");
    }
	
    public function testInt()
    {
    	var intStr = "{v:500}";
    	var o = Json.parse(intStr);
    	Assert.equals(500, o.v);
    	Assert.isOfType(o.v, Int);
		
    	var intStr = "{v:2147483647}";
    	var o = Json.parse(intStr);
    	Assert.equals(2147483647, o.v);
    	Assert.isOfType(o.v, Int);
		
    	var intStr = "{v:-2147483648}";
    	var o = Json.parse(intStr);
    	Assert.equals(-2147483648, o.v);
    	Assert.isOfType(o.v, Int);
		
    	var intStr = "{v:5000000000}";
    	var o = Json.parse(intStr);
    	Assert.equals(5000000000.0, o.v);
    	Assert.isOfType(o.v, Float);
		
    	var intStr = "{v:-5000000000}";
    	var o = Json.parse(intStr);
    	Assert.equals(-5000000000.0, o.v);
    	Assert.isOfType(o.v, Float);
    }
	
	public function testChars()
	{
		var data = File.getContent('files/chars.json');
		var d = Json.parse(data);
		//just making sure it parses without errors
		Assert.equals(1, 1);
	}
	
	public function testFullCircle2()
	{
		var test = Json.parse('{
		  object : customer,
		  created : 1378868740,
		  id : cus_2YAHJPoReA8KA8,
		  livemode : false,
		  description : test,
		  email : null,
		  "[":"a quoted string"
		  "{":"A multiline
		  			string"
		}');
		var string1 = Json.encode(test);
		var data = Json.parse(string1);
		var string2 = Json.encode(data);
		
		Assert.equals(string1, string2);
	}
	
	public function testNull()
	{
		var obj = { "nullVal":null, 'non-null':'null', "array":[null, 1]};
		var data = Json.encode(obj);
		Assert.allows(['{"nullVal":null,"non-null":"null","array":[null,1]}', "{\"non-null\":\"null\",\"nullVal\":null,\"array\":[null,1]}"], data);
		
		var obj2 = Json.parse('{"nullVal":null ,"non-null":"null","array":[null,1]}');
		var data2 = Json.encode(obj2);
		Assert.allows(['{"nullVal":null,"non-null":"null","array":[null,1]}', "{\"non-null\":\"null\",\"nullVal\":null,\"array\":[null,1]}"], data2);
	}
	
	public function testClassObject()
	{
		var obj = new TestClass();
		obj.setPriv("this works");
		
		//serialize class object
		var json = Json.encode(obj);
		//trace(json);
		//unserialize class object
		var ob2 = Json.parseTyped(json, TestClass);
		
		Assert.equals("yep", ob2.test());
		Assert.equals(obj.getPriv(), ob2.getPriv());
		
		//confirm that they are seperate instances
		obj.setPriv('newString');
		Assert.isFalse(obj.getPriv() == ob2.getPriv());
		Assert.equals("this works", obj.subObj.myvar);
		
        //test Date object serialization/unserialization
        Assert.isTrue(ob2.aDate != null);
        Assert.isOfType(ob2.aDate, Date);
        Assert.equals(ob2.timestamp, obj.timestamp);
        Assert.equals(ob2.aDate.getTime(), obj.timestamp);
        
        //test TJ_noEncode
        Assert.equals("this wont be serialized", obj.dontSerialize);
        Assert.equals(null, ob2.dontSerialize);
	}
}
