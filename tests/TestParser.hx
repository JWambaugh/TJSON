package ;

import tjson.TJSON;

import sys.io.File;

class ChildClass{
	public var myvar:String;
	public var parent:TestClass;
	public function new(parent:TestClass){
		this.parent = parent;
		myvar = "this works";
	}
}

class TestClass{
	private var priv:String = 'this is private';
	public var pub:String = 'this is public';
	public var subObj:ChildClass;
	public var list:List<String>;

	public function new(){
		subObj = new ChildClass(this);
		list = new List();
		list.push("hello");
	}
	public function test(){
		return "yep";
	}
	public function setPriv(v:String){
		priv = v;
	}
	public function getPriv(){
		return priv;
	}
}
//{"priv":"this is private","pub":"this is public","_hxcls":"TestClass"}


class TestParser extends haxe.unit.TestCase{

	public function new(){
		super();
	}



	public function testSimple(){
		var res =TJSON.parse("{key:'value'}");
		assertEquals('value',res.key);

		var res = TJSON.parse("[]");
		assertTrue(Std.is(res, Array));
		assertEquals(0, res.length);

		var res = TJSON.parse("123");
		assertEquals(123, res);

		var res = TJSON.parse("123.4");
		assertEquals(123.4, res);

		var res = TJSON.parse('"123.4"');
		assertEquals("123.4", res);

		var res = TJSON.parse("true");
		assertEquals(true, res);
		var res = TJSON.parse("false");
		assertEquals(false, res);

		var res = TJSON.parse("null");
		assertEquals(null, res);
	}


	public function testComplex(){
		var data = '/* 
			TJSON test file
			this file is used for testing the TJSON parser.
			TJSON is the Tolerant JSON parser.
			*/
			{
				keyWithNoString:{
					\'keyWithsinglequote\' : "value with a 
					newline in the middle!"
					,k2:300
					"key with spaces": "key 3"
				}
				// this is a single line comment

				"arrayWithNoCommaBeforeIt":[1,-3.2,2,.45, {
					oneKey:oneValue
				}]
				,arrayWithObj:      
					[
					{key:aValue}
					{key2:aValue2}
					]
				,boolValue: true
				,"falseValue": false

				,"test":"\\/blah"

                ,"utf":"\\u0410\\u0411\\u0412\\u0413\\u0414 \\u0430\\u0431\\u0432\\u0433\\u0434"
                ,"arrayWithEmptyString":[
                	"test1"
                	,""
                ]



			}';
		var o = TJSON.parse(data);
		//trace(Std.string(o));
		assertEquals("value with a 
					newline in the middle!", o.keyWithNoString.keyWithsinglequote);
		assertEquals(300,Reflect.field(o.keyWithNoString,'k2'));
		assertEquals("key 3",Reflect.field(o.keyWithNoString,'key with spaces'));
		assertEquals(-3.2, o.arrayWithNoCommaBeforeIt[1]);
		assertEquals(1.0, o.arrayWithNoCommaBeforeIt[0]);
		assertEquals(0.45, o.arrayWithNoCommaBeforeIt[3]);
		assertEquals("aValue2",o.arrayWithObj[1].key2);
		assertEquals(true,o.boolValue);
		assertEquals(false,o.falseValue);
		assertEquals("АБВГД абвгд",o.utf);
	}

	public function testEncodeObject(){
		assertEquals('{"key2":{"anotherKey":"another\\nValue"},"key":"value"}',TJSON.encode({key:'value',key2:{anotherKey:"another\nValue"}}));
	}
	
	public function testEncodeArray(){
		assertEquals('[1,2,3,4,[10,10,{"myKey":"My\\nValue"}]]',TJSON.encode([1,2,3,4,[10,10,{myKey:"My\nValue"}]]));
	}
	public function testEncodeMap(){
		assertEquals('{"key":{"newKey":"value"},"key2":{"anotherKey":"another\\nValue"}}',
		    TJSON.encode([ "key" => [ "newKey" => "value" ], "key2" => [ "anotherKey" => "another\nValue" ] ]));
	}

	public function testEncodeList(){
		var list = new List<Dynamic>();
		list.add("test");
		list.add({key:'myObject',intval:31});
		list.add([1,2,3,4]);
		var sublist = new List<Dynamic>();
		sublist.add(1);
		sublist.add("two");
		sublist.add(new List<Dynamic>());
		list.add(sublist);
		assertEquals('["test",{"key":"myObject","intval":31},[1,2,3,4],[1,"two",[]]]',TJSON.encode(list));
	}

	public function testFullCircleObject(){
		var origObj={
			'1':'a'
			,'2':'b'
			,anArray:[
				{
					objectKey:'objectValue'
					,anotherKey:'anotherValue'
				}
			]
			,anotherArray:[
					"this is a string in a sub array"
					,"next will be a float"
					
				]
		};
		//test simple style
		var jsonString = TJSON.encode(origObj);
		var generatedObj = TJSON.parse(jsonString);
		assertEquals('a',Reflect.field(generatedObj,'1'));

		assertEquals('anotherValue',Reflect.field(Reflect.field(generatedObj,'anArray')[0],'anotherKey'));

		//test fancy style
		var jsonString = TJSON.encode(origObj,'fancy');
		var generatedObj = TJSON.parse(jsonString);
		assertEquals('a',Reflect.field(generatedObj,'1'));
		assertEquals('anotherValue',Reflect.field(Reflect.field(generatedObj,'anArray')[0],'anotherKey'));

	}

	public function testCrazyCharacters(){
		var origObj = {
			"str":"!@#$%^&*()_+\"'/.,\\;':{}"
		}
		var jsonString = TJSON.encode(origObj);
		var generatedObj = TJSON.parse(jsonString);
		assertEquals(origObj.str, generatedObj.str);
	}

    public function testUtf8Chars(){
      var s = '{"str":"\\u0410\\u0411\\u0412\\u0413\\u0414 \\u0430\\u0431\\u0432\\u0433\\u0434"}';
      var o = TJSON.parse(s);
      assertEquals(o.str, "АБВГД абвгд");
    }

    public function testInt(){
    	var intStr = "{v:500}";
    	var o = TJSON.parse(intStr);
    	assertEquals(500, o.v);
    	assertTrue(Std.is(o.v, Int));

    	var intStr = "{v:2147483647}";
    	var o = TJSON.parse(intStr);
    	assertEquals(2147483647, o.v);
    	assertTrue(Std.is(o.v, Int));

    	var intStr = "{v:-2147483648}";
    	var o = TJSON.parse(intStr);
    	assertEquals(-2147483648, o.v);
    	assertTrue(Std.is(o.v, Int));

    	var intStr = "{v:5000000000}";
    	var o = TJSON.parse(intStr);
    	assertEquals(5000000000.0, o.v);
    	assertTrue(Std.is(o.v, Float));

    	var intStr = "{v:-5000000000}";
    	var o = TJSON.parse(intStr);
    	assertEquals(-5000000000.0, o.v);
    	assertTrue(Std.is(o.v, Float));
    }

	public function testChars(){
		var data = File.getContent('tests/chars.json');
		var d = TJSON.parse(data);
		//just making sure it parses without errors
		assertEquals(1,1);
	}

	public function testFullCircle2(){
		var test = tjson.TJSON.parse('{
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
		var string1 = tjson.TJSON.encode(test);
		var data = tjson.TJSON.parse(string1);
		var string2 = TJSON.encode(data);

		assertEquals(string1,string2);
	}

	public function testNull(){
		var obj= {"nullVal":null ,'non-null':'null',"array":[null,1]};
		var data:String = TJSON.encode(obj);
		assertEquals('{"non-null":"null","nullVal":null,"array":[null,1]}',data);
		
		var obj2= TJSON.parse('{"nullVal":null ,"non-null":"null","array":[null,1]}');
		var data2:String = TJSON.encode(obj2);
		assertEquals('{"non-null":"null","nullVal":null,"array":[null,1]}',data2);
	}

	public function testClassObject(){
		var obj = new TestClass();
		obj.setPriv("this works");

		//serialize class object
		var json = TJSON.encode(obj);
		// trace(json);
		//unserialize class object
		var ob2:TestClass = TJSON.parse( json );
		
		assertEquals("yep",ob2.test());
		assertEquals(obj.getPriv(), ob2.getPriv());


		//confirm that they are seperate instances
		obj.setPriv('newString');
		assertFalse(obj.getPriv() == ob2.getPriv());
		assertEquals("this works",obj.subObj.myvar);
		assertEquals(ob2, ob2.subObj.parent);
	}

	public function testObjectReferences(){
		var arr:Array<TestClass> = new Array();
		var ob1:TestClass = new TestClass();
		arr.push(new TestClass());
		arr.push(new TestClass());
		arr.push(ob1);
		arr.push(new TestClass());

		arr.push(ob1);
		arr.push(new TestClass());

		var json = TJSON.encode(arr);
		// trace(json);
		var res = TJSON.parse(json);
		assertEquals(res[4],res[2]);
	}
	
}
