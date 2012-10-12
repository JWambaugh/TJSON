TJSON
=====

The tolerant JSON parser for HaXe

TJSON is a project to create a JSON parser that is (hopefully) as tolerant as JavaScript is when it comes to JavaScript object notation.
It will support all the current JSON standard, along with the following tollerances added:

1. Support single-quotes for strings
2. Keys don't have to be wapped in quotes
3. C style comments support - /*comment*/
4. C++ style comments support - //comment
5. Dangling commas won't kill it
