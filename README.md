TJSON
=====

The tolerant JSON parser and encoder for HaXe

TJSON is a project to create a JSON parser that is as tolerant as JavaScript is when it comes to JavaScript object notation, if not more error-tolerant.
It supports all the current JSON standard, along with the following tollerances added:

1. Support single-quotes for strings
2. Keys don't have to be wrapped in quotes
3. C style comments support - /*comment*/
4. C++ style comments support - //comment
5. Dangling commas don't kill it (commas  are even optional)

As of 1.1.0, TJSON also includes an encoder that encodes anonymous Haxe objects and arrays into JSON!

Usage
=====

Install TJSON
-------------

Install via haxlib by running the following in your command line:

	haxelib install tjson


Include TJSON in your build
---------------------------
Be sure to add the following to your .hxml file:

	-lib tjson


Use in your code
----------------

Import TJSON class with:

	import tjson.TJSON;

Then you can read JSON data with:

	var jsonData = "{key:'value'}";
	var object = TJSON.parse(jsonData);
	trace(object.key); // outputs 'value'

It's that easy!

*New in 1.1.0* Encode Haxe objects into a JSON string with:

	var objectToEncode={
		myKey:'myValue'
	};
	var json = TJSON.encode(objectToEncode);  // {"myKey":"myValue"}

The encoder currently supports two different encoding styles. The default is 'simple', which contains no whitespace. If you want more human-readable output, try the 'fancy' style:

	var objectToEncode={
		myKey:'myValue'
	};
	var json = TJSON.encode(objectToEncode, 'fancy');
	/*
	{
		"myKey" : "myValue"
	}
	*/

Of course, the encoder can also encode arrays:

	var myArray = [1,32,43,54];
	var json = TJSON.encode(myArray);

License
=======

Copyright (c) 2012, Jordan CM Wambaugh
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

