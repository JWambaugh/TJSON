
package tjson;

class TJSON {

	static var pos:Int;
	static var json:String;
	public static function parse(json:String):Dynamic{
		TJSON.json = json;
		pos = 0;
		var symbol:String;
		return doParse();
	}

	private static function doParse():Dynamic{
		//determine if objector array
		var s = getNextSymbol();
		if(s=='{'){
			return doObject();
		}

		if(s=='['){
			return doArray();
		}
		return null;
	}

	private static function doObject():Dynamic{
		var o = {};
		var val:Dynamic='';
		var key:String;
		while((key=getNextSymbol()) != ""){
			if(key==",")continue;
			if(key == "}"){
				return o;
			}
			var seperator = getNextSymbol();
			if(seperator != ":"){
				throw("Expected ':' but got '"+seperator+"' instead.");
			}

			var v = getNextSymbol();
			if(v=="{"){
				val = doObject();
			}else if(v=="["){
				val = doArray();
			}else{
				val = v;
			}

			Reflect.setField(o,key,val);
		}
		throw "Unexpected end of file. Expected '}'";
		
	}

	private static function doArray():Dynamic{
		var a=[];
		var val:String;
		while((val=getNextSymbol()) != ""){
			if(val == ','){
				continue;
			}
			if(val == ']'){
				return a;
			}
			if(val=="{"){
				val = doObject();
			}else if(val=="["){
				val = doArray();
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	private static function getNextSymbol(){
		var c:String = '';
		var inQuote:Bool = false;
		var quoteType:String="";
		var symbol:String = '';
		var inEscape:Bool = false;
		var inSymbol:Bool = false;
		var inLineComment = false;
		var inBlockComment = false;

		while(pos < json.length){
			c = json.charAt(pos++);

			if(inLineComment){
				if(c=="\n" || c=="\r"){
					inLineComment = false;
					pos++;
				}
				continue;
			}

			if(inBlockComment){
				if(c=="*" && json.charAt(pos) == "/"){
					inBlockComment = false;
					pos++;
				}
				continue;
			}

			if(inQuote){
				if(inEscape){
					//TODO: do this
				}else{
					if(c == "\\"){
						inEscape = true;
						continue;
					}
					if(c == quoteType){
						return symbol;
					}
					symbol+=c;
					continue;
				}
			}
			

			//handle comments
			else if(c == "/"){
				var c2 = json.charAt(pos);
				//handle single line comments.
				//These can even interrupt a symbol.
				if(c2 == "/"){
					inLineComment=true;
					pos++;
					continue;
				}
				//handle block comments.
				//These can even interrupt a symbol.
				else if(c2 == "*"){
					inBlockComment=true;
					pos++;
					continue;
				}
			}

			

			if (inSymbol){
				if(c==' ' || c=="\n" || c==',' || c==":" || c=="}" || c=="]"){ //end of symbol, return it
					pos--;
					return symbol;
				}else{
					symbol+=c;
					continue;
				}
				
			}
			else {
				if(c==' ' || c=="\t" || c=="\n" || c=="\r"){
					continue;
				}

				if(c=="{" || c=="}" || c=="[" || c=="]" || c=="," || c == ":"){
					return c;
				}



				if(c=="'" || c=='"'){
					inQuote = true;
					quoteType = c;
					continue;
				}else{
					inSymbol=true;
					symbol = c;
					continue;
				}


			}
		}
		return symbol;
	}

}