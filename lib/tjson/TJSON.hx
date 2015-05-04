
package tjson;
using StringTools;

class TJSON {    
	public static var OBJECT_REFERENCE_PREFIX = "@~obRef#";
	/**
	 * Parses a JSON string into a haxe dynamic object or array.
	 * @param String - The JSON string to parse
	 * @param String the file name to whic the JSON code belongs. Used for generating nice error messages.
	 */
	public static function parse(json:String, ?fileName:String="JSON Data", ?stringProcessor:String->Dynamic = null):Dynamic{
        var t = new TJSONParser(json, fileName, stringProcessor);
		return t.doParse();
	}

	/**
	 * Serializes a dynamic object or an array into a JSON string.
	 * @param Dynamic - The object to be serialized
	 * @param Dynamic - The style to use. Either an object implementing EncodeStyle interface or the strings 'fancy' or 'simple'.
	 */
	public static function encode(obj:Dynamic, ?style:Dynamic=null, useCache:Bool=true):String{
		var t = new TJSONEncoder(useCache);
		return t.doEncode(obj,style);
	}


}


class TJSONParser{
	var pos:Int;
	var json:String;
	var lastSymbolQuoted:Bool; //true if the last symbol was in quotes.
    var fileName:String;
	var currentLine:Int;
	var cache:Array<Dynamic>;
	var floatRegex:EReg;
	var intRegex:EReg;
	var strProcessor:String->Dynamic;

	public function new(vjson:String, ?vfileName:String="JSON Data", ?stringProcessor:String->Dynamic = null)
    {
		json = vjson;
		fileName = vfileName;
		currentLine = 1;
        lastSymbolQuoted = false;
		pos = 0;
		floatRegex = ~/^-?[0-9]*\.[0-9]+$/;
		intRegex = ~/^-?[0-9]+$/;	
		strProcessor = (stringProcessor==null? defaultStringProcessor : stringProcessor);
		cache = new Array();
    }

    public function doParse():Dynamic{
    	try{
			//determine if objector array
			return switch (getNextSymbol()) {
				case '{': doObject();
				case '[': doArray();
				case s: convertSymbolToProperType(s);
			}
		}catch(e:String){
			throw fileName + " on line " + currentLine + ": " + e;
		}
	}

	private function doObject():Dynamic{
		var o:Dynamic = { };
		var val:Dynamic ='';
		var key:String;
		var isClassOb:Bool = false;
		cache.push(o);
		while(pos < json.length){
			key=getNextSymbol();
			if(key == "," && !lastSymbolQuoted)continue;
			if(key == "}" && !lastSymbolQuoted){
				//end of the object. Run the TJ_unserialize function if there is one
				if( isClassOb && #if flash9 try o.TJ_unserialize != null catch( e : Dynamic ) false #elseif (cs || java) Reflect.hasField(o, "TJ_unserialize") #else o.TJ_unserialize != null #end  ) {
					o.TJ_unserialize();
				}
				return o;
			}

			var seperator = getNextSymbol();
			if(seperator != ":"){
				throw("Expected ':' but got '"+seperator+"' instead.");
			}

			var v = getNextSymbol();

			if(key == '_hxcls'){
				var cls =Type.resolveClass(v);
				if(cls==null) throw "Invalid class name - "+v;
				o = Type.createEmptyInstance(cls);
				cache.pop();
				cache.push(o);
				isClassOb = true;
				continue;
			}


			if(v == "{" && !lastSymbolQuoted){
				val = doObject();
			}else if(v == "[" && !lastSymbolQuoted){
				val = doArray();
			}else{
				val = convertSymbolToProperType(v);
			}
			Reflect.setField(o,key,val);
		}
		throw "Unexpected end of file. Expected '}'";
		
	}

	private function doArray():Dynamic{
		var a:Array<Dynamic> = new Array<Dynamic>();
		var val:Dynamic;
		while(pos < json.length){
			val=getNextSymbol();
			if(val == ',' && !lastSymbolQuoted){
				continue;
			}
			else if(val == ']' && !lastSymbolQuoted){
				return a;
			}
			else if(val == "{" && !lastSymbolQuoted){
				val = doObject();
			}else if(val == "[" && !lastSymbolQuoted){
				val = doArray();
			}else{
				val = convertSymbolToProperType(val);
			}
			a.push(val);
		}
		throw "Unexpected end of file. Expected ']'";
	}

	private function convertSymbolToProperType(symbol):Dynamic{
		if(lastSymbolQuoted) {
			//value was in quotes, so it's a string.
			//look for reference prefix, return cached reference if it is
			if(StringTools.startsWith(symbol,TJSON.OBJECT_REFERENCE_PREFIX)){
				var idx:Int = Std.parseInt(symbol.substr(TJSON.OBJECT_REFERENCE_PREFIX.length));
				return cache[idx];
			}
			return symbol; //just a normal string so return it
		}
		if(looksLikeFloat(symbol)){
			return Std.parseFloat(symbol);
		}
		if(looksLikeInt(symbol)){
			return Std.parseInt(symbol);
		}
		if(symbol.toLowerCase() == "true"){
			return true;
		}
		if(symbol.toLowerCase() == "false"){
			return false;
		}
		if(symbol.toLowerCase() == "null"){
			return null;
		}
		
		return symbol;
	}


	private function looksLikeFloat(s:String):Bool{
		return floatRegex.match(s) || (
			intRegex.match(s) && {
				var intStr = intRegex.matched(0);
				if (intStr.charCodeAt(0) == "-".code)
					intStr > "-2147483648";
				else
					intStr > "2147483647";
			}
		);
	}

	private function looksLikeInt(s:String):Bool{
		return intRegex.match(s);
	}

	private function getNextSymbol(){
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
			if(c == "\n" && !inSymbol)
				currentLine++;
			if(inLineComment){
				if(c == "\n" || c == "\r"){
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
						symbol += "\t";
						continue;
					}
					if(c=="n"){
						symbol += "\n";
						continue;
					}
					if(c=="\\"){
						symbol += "\\";
						continue;
					}
					if(c=="r"){
						symbol += "\r";
						continue;
					}
					if(c=="/"){
						symbol += "/";
						continue;
					}

					if(c=="u"){
                        var hexValue = 0;

                        for (i in 0...4){
                            if (pos >= json.length)
                              throw "Unfinished UTF8 character";
			                var nc = json.charCodeAt(pos++);
                            hexValue = hexValue << 4;
                            if (nc >= 48 && nc <= 57) // 0..9
                              hexValue += nc - 48;
                            else if (nc >= 65 && nc <= 70) // A..F
                              hexValue += 10 + nc - 65;
                            else if (nc >= 97 && nc <= 102) // a..f
                              hexValue += 10 + nc - 95;
                            else throw "Not a hex digit";
                        }
                        
						var utf = new haxe.Utf8();
						utf.addChar(hexValue);
						symbol += utf.toString();
                        
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


	private function defaultStringProcessor(str:String):Dynamic{
		return str;
	}
}


class TJSONEncoder{

	var cache:Array<Dynamic>;
	var uCache:Bool;

	public function new(useCache:Bool=true){
		uCache = useCache;
		if(uCache)cache = new Array();
	}

	public function doEncode(obj:Dynamic, ?style:Dynamic=null){
		if(!Reflect.isObject(obj)){
			throw("Provided object is not an object.");
		}
		var st:EncodeStyle;
		if(Std.is(style, EncodeStyle)){
			st = style;
		}
		else if(style == 'fancy'){
			st = new FancyStyle();
		}
		else st = new SimpleStyle();
		var buffer = new StringBuf();
		if(Std.is(obj,Array) || Std.is(obj,List)) {
			buffer.add(encodeIterable( obj, st, 0));

		} else if(Std.is(obj, haxe.ds.StringMap)){
			buffer.add(encodeMap(obj, st, 0));
		} else {
			cacheEncode(obj);
			buffer.add(encodeObject(obj, st, 0));
		}
		return buffer.toString();
	}

	private function encodeObject( obj:Dynamic,style:EncodeStyle,depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginObject(depth));
		var fieldCount = 0;
		var fields:Array<String>;
		var dontEncodeFields:Array<String> = null;
		var cls = Type.getClass(obj);
		if (cls != null) {
			fields = Type.getInstanceFields(cls);
		} else {
			fields = Reflect.fields(obj);
		}
		//preserve class name when serializing class objects
		//is there a way to get c outside of a switch?
		switch(Type.typeof(obj)){
			case TClass(c):
				if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
				else buffer.add(style.firstEntry(depth));
				buffer.add('"_hxcls"'+style.keyValueSeperator(depth));
				buffer.add(encodeValue( Type.getClassName(c), style, depth));

				if( #if flash9 try obj.TJ_noEncode != null catch( e : Dynamic ) false #elseif (cs || java) Reflect.hasField(obj, "TJ_noEncode") #else obj.TJ_noEncode != null #end  ) {
					dontEncodeFields = obj.TJ_noEncode();
				}
			default:
		}

		for (field in fields){
			if(dontEncodeFields!=null && dontEncodeFields.indexOf(field)>=0)continue;
			var value:Dynamic = Reflect.field(obj,field);
			var vStr:String = encodeValue(value, style, depth);
			if(vStr!=null){
				if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
				else buffer.add(style.firstEntry(depth));
				buffer.add('"'+field+'"'+style.keyValueSeperator(depth)+vStr);
			}
			
		}
		

		
		buffer.add(style.endObject(depth));
		return buffer.toString();
	}


	private function encodeMap( obj:Map<Dynamic, Dynamic>,style:EncodeStyle,depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginObject(depth));
		var fieldCount = 0;
		for (field in obj.keys()){
			if(fieldCount++ > 0) buffer.add(style.entrySeperator(depth));
			else buffer.add(style.firstEntry(depth));
			var value:Dynamic = obj.get(field);
			buffer.add('"'+field+'"'+style.keyValueSeperator(depth));
			buffer.add(encodeValue(value, style, depth));
		}
		buffer.add(style.endObject(depth));
		return buffer.toString();
	}


	private function encodeIterable(obj:Iterable<Dynamic>, style:EncodeStyle, depth:Int):String {
		var buffer = new StringBuf();
		buffer.add(style.beginArray(depth));
		var fieldCount = 0;
		for (value in obj){
			if(fieldCount++ >0) buffer.add(style.entrySeperator(depth));
			else buffer.add(style.firstEntry(depth));
			buffer.add(encodeValue( value, style, depth));
			
		}
		buffer.add(style.endArray(depth));
		return buffer.toString();
	}

	private function cacheEncode(value:Dynamic):String{
		if(!uCache)return null;

		for(c in 0...cache.length){
			if(cache[c] == value){
				return '"'+TJSON.OBJECT_REFERENCE_PREFIX+c+'"';
			}
		}
		cache.push(value);
		return null;
	}

	private function encodeValue( value:Dynamic, style:EncodeStyle, depth:Int):String {
		if(Std.is(value, Int) || Std.is(value,Float)){
				return(value);
		}
		else if(Std.is(value,Array) || Std.is(value,List)){
			var v: Array<Dynamic> = value;
			return encodeIterable(v,style,depth+1);
		}
		else if(Std.is(value,List)){
			var v: List<Dynamic> = value;
			return encodeIterable(v,style,depth+1);

		}
		else if(Std.is(value,haxe.ds.StringMap)){
			return encodeMap(value,style,depth+1);

		}
		else if(Std.is(value,String)){
			return('"'+Std.string(value).replace("\\","\\\\").replace("\n","\\n").replace("\r","\\r").replace('"','\\"')+'"');
		}
		else if(Std.is(value,Bool)){
			return(value);
		}
		else if(Reflect.isObject(value)){
			var ret = cacheEncode(value);
			if(ret != null) return ret;
			return encodeObject(value,style,depth+1);
		}
		else if(value == null){
			return("null");
		}
		else{
			return null;
		}
	}

}


interface EncodeStyle{
	
	public function beginObject(depth:Int):String;
	public function endObject(depth:Int):String;
	public function beginArray(depth:Int):String;
	public function endArray(depth:Int):String;
	public function firstEntry(depth:Int):String;
	public function entrySeperator(depth:Int):String;
	public function keyValueSeperator(depth:Int):String;

}

class SimpleStyle implements EncodeStyle{
	public function new(){

	}
	public function beginObject(depth:Int):String{
		return "{";
	}
	public function endObject(depth:Int):String{
		return "}";
	}
	public function beginArray(depth:Int):String{
		return "[";
	}
	public function endArray(depth:Int):String{
		return "]";
	}
	public function firstEntry(depth:Int):String{
		return "";
	}
	public function entrySeperator(depth:Int):String{
		return ",";
	}
	public function keyValueSeperator(depth:Int):String{
		return ":";
	}
	
}


class FancyStyle implements EncodeStyle{
	public var tab(default, null):String;
	public function new(tab:String = "    "){
		this.tab = tab;
		charTimesNCache = [""];
	}
	public function beginObject(depth:Int):String{
		return "{\n";
	}
	public function endObject(depth:Int):String{
		return "\n"+charTimesN(depth)+"}";
	}
	public function beginArray(depth:Int):String{
		return "[\n";
	}
	public function endArray(depth:Int):String{
		return "\n"+charTimesN(depth)+"]";
	}
	public function firstEntry(depth:Int):String{
		return charTimesN(depth+1)+' ';
	}
	public function entrySeperator(depth:Int):String{
		return "\n"+charTimesN(depth+1)+",";
	}
	public function keyValueSeperator(depth:Int):String{
		return " : ";
	}
	private var charTimesNCache:Array<String>;
	private function charTimesN(n:Int):String{
		return if (n < charTimesNCache.length) {
			charTimesNCache[n];
		} else {
			charTimesNCache[n] = charTimesN(n-1) + tab;
		}
	}
	
}




