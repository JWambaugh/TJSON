
package tjson;

class TJSON {

	static var pos:Int;
	static var json:String;
	static var lastSymbolQuoted:Bool; //true if the last symbol was in quotes.
	static inline var floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
	static inline var intRegex = ~/^-?[0-9]+$/;
	
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
		var o:Dynamic = { };
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
				val = convertSymbolToProperType(v);
			}
			Reflect.setField(o,key,val);
		}
		throw "Unexpected end of file. Expected '}'";
		
	}

	private static function doArray():Dynamic{
		var a:Array<Dynamic>=new Array<Dynamic>();
		var val:Dynamic;
		while((val=getNextSymbol()) != ""){
			if(val == ','){
				continue;
			}
			else if(val == ']'){
				return a;
			}
			else if(val=="{"){
				val = doObject();
			}else if(val=="["){
				val = doArray();
			}else{
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	private static function convertSymbolToProperType(symbol):Dynamic{
		if(lastSymbolQuoted) return symbol; //things is quotes are always strings
		if(looksLikeFloat(symbol)){
			return Std.parseFloat(symbol);
		}
		if(looksLikeInt(symbol)){
			return Std.parseInt(symbol);
		}
		if(symbol.toLowerCase() =="true"){
			return true;
		}
		if(symbol.toLowerCase() =="false"){
			return false;
		}
		return symbol;
	}


	private static function looksLikeFloat(s:String):Bool{
		if(floatRegex.match(s)){
			return true;
		}
		return false;
	}

	private static function looksLikeInt(s:String):Bool{
		
		if(intRegex.match(s)){
			return true;
		}
		return false;
	}

	private static function getNextSymbol(){
		lastSymbolQuoted=false;
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
					inEscape = false;
					if(c=="'" || c=='"'){
						symbol += c;
						continue;
					}
					if(c=="t"){
						symbol +="\t";
						continue;
					}
					if(c=="n"){
						symbol +="\n";
						continue;
					}
					if(c=="\\"){
						symbol +="\\";
						continue;
					}
					if(c=="r"){
						symbol +="\r";
						continue;
					}

					throw "Invalid escape sequence '\\"+c+"'";
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
				if(c==' ' || c=="\n" || c=="\r" || c=="\t" || c==',' || c==":" || c=="}" || c=="]"){ //end of symbol, return it
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
					lastSymbolQuoted = true;
					continue;
				}else{
					inSymbol=true;
					symbol = c;
					continue;
				}


			}
		} // end of while. We have reached EOF if we are here.
		if(inQuote){
			throw "Unexpected end of data. Expected ( "+quoteType+" )";
		}
		return symbol;
	}

}