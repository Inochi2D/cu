import std.stdio;
import compiler.parser;
import std.file : readText;

version(unittest) {
	// No main in unit tests
} else {
	void main(string[] args)
	{
		Parser p = new Parser;
		foreach(f; args[1..$]) {
			auto parsed = p.parse(readText(f));
			writeln(parsed.toString());
		}
	}
}
