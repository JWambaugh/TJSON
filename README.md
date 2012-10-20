TJSON
=====

The tolerant JSON parser for HaXe

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

	import TJSON;

Then you can read JSON data with:

	var jsonData = "{key:'value'}";
	var object = TJSON.parse(jsonData);
	trace(object.key); // outputs 'value'

It's that easy!