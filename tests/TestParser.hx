package ;

import tjson.TJSON;

//import sys.io.File;

class TestParser extends haxe.unit.TestCase{

	public function new(){
		super();
	}



	public function testSimple(){
		var res =TJSON.parse("{key:'value'}");
		assertEquals('value',res.key);
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
	}

	public function testEncodeObject(){
		assertEquals('{"key2":{"anotherKey":"another\\nValue"},"key":"value"}',TJSON.encode({key:'value',key2:{anotherKey:"another\nValue"}}));
	}
	public function testEncodeArray(){
		assertEquals('[1,2,3,4,[10,10,{"myKey":"My\\nValue"}]]',TJSON.encode([1,2,3,4,[10,10,{myKey:"My\nValue"}]]));
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
			"str":"!@#$%^&*()_+\"'/.,\\;':"
		}
		var jsonString = TJSON.encode(origObj);
		var generatedObj = TJSON.parse(jsonString);
		assertEquals(origObj.str, generatedObj.str);
	}
	
}