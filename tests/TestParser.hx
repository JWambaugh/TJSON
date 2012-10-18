package ;

import tjson.TJSON;

import sys.io.File;

class TestParser extends haxe.unit.TestCase{

	public function new(){
		super();
	}



	public function testSimple(){
		var res =TJSON.parse("{key:'value'}");
		assertEquals("{ key => value }",Std.string(res));
	}

	public function testSimple2(){
		var res =TJSON.parse("{key1:'value', key2:'value 2'}");
		assertEquals("{ key1 => value, key2 => value 2 }",Std.string(res));
	}
	public function testComplex1(){
		var res =TJSON.parse("{key1:'value', key2:'value 2'
		 myOb:{subkey1:'subkey1 value!!! Yah'}, 'anArray':['happy', 323, {key:val}]}");
		assertEquals('{ key1 => value, key2 => value 2, myOb => { subkey1 => subkey1 value!!! Yah }, anArray => [happy,323,{ key => val }] }',Std.string(res));
	}

	public function testComplexWithComments(){
		var res =TJSON.parse("{key1:'value',/* block comment*/ key2:'value 2'
			//this is a line comment.

		 myOb:{subkey1:'subkey1 value!!! Yah'}, 'anArray':['happy', 323, {key:val}]}");
		assertEquals('{ key1 => value, key2 => value 2, myOb => { subkey1 => subkey1 value!!! Yah }, anArray => [happy,323,{ key => val }] }',Std.string(res));
	}


	public function testArray1(){
		var res =TJSON.parse("[1,2,3,4,5,6,'A string']");
		assertEquals("[1,2,3,4,5,6,A string]",Std.string(res));
	}

	public function testEscapeSequences(){
		var res =TJSON.parse("['Back slash: \\\\ Tab: \\t NewLine: \\n CR: \\r SQ: \\' DQ: \\\" ']");
		assertEquals("[Back slash: \\ Tab: \t NewLine: \n CR: \r SQ: ' DQ: \" ]",Std.string(res));
	}

	public function testNewlineInString(){
		var res =TJSON.parse("['This is a string.
			It has a newline in the middle of it! This is not normally allowed. But TJSON allows for it!']");
		assertEquals("[This is a string.
			It has a newline in the middle of it! This is not normally allowed. But TJSON allows for it!]",Std.string(res));
	}

	public function testFile(){
		var data = File.getContent("tests/testJSON.json");
		trace(Std.string(TJSON.parse(data)));
	}
}