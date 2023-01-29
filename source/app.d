module app;
import std.stdio;
import commandr;
import runtime.jit;
import ir.assembly;
import std.complex;
import core.stdc.stdlib : exit;
import std.format;

version(unittest) { /* No main in unit tests */ } else {


// Main function
int main(string[] args) {
	auto app = new Program("cu", "1.0");
	auto apparg =
		app.summary("Cu runtime application")
		.author("Luna the Foxgirl")
		.add(new Command("run", "Runs the specified assembly")
			.add(new Argument("file", "Cu program to run"))
			.add(new Argument("args", "Arguments to pass to the program").optional.repeating))
		.add(new Command("t", "Exports test assembly"))
		.parse(args);

	// Attempt runtime
	try {
		apparg.on("run", (ProgramArgs args) {

			// Execute Cu program
			CuJITRuntime runtime = new CuJITRuntime();
			auto assembly = CuAssembly.fromFile(args.arg("file"));
			if (!assembly.isExectuable()) {
				throw new Exception("%s is not executable".format(args.arg("file")));
			}

			runtime.loadAssembly(assembly);
			int ret = runtime.run(args.argAll("args"));
			exit(ret);
		}).on("t", (args) {
			exportTestAssembly();
			exit(0);
		});
	} catch (Exception ex) {
		stderr.writeln(ex.msg);
		debug throw ex;
		else return -1;
	}
	
	app.printHelp();
	return 0;
}

// Test assembly export
void exportTestAssembly() {
	import std.file : readText;
	import common.io;
	import ir.mod;
	import ir.assembly : CuAssembly, CuAssemblyFlags;
	import ir.value;
	import ir.func;
	import ir.types.type;
	import ir.builder;
	CuAssembly asm_ = new CuAssembly();
	asm_.info.name = "TestAssembly.cua";
	asm_.info.version_ = CuVersion(1, 0, 0);
	asm_.info.humanName = "uwu";
	asm_.info.flags = CuAssemblyFlags.executable;
	CuModule m_std = new CuModule("std");
	m_std.getOrCreateSubmodule("stdio");
	asm_.modules ~= m_std;

	auto func = m_std.createFunction("a", cuirCreateVoid());



	CuIRBuilder builder = new CuIRBuilder(func.appendBlock("begin"));
	auto v = builder.buildAdd(cuirCreateValueImmediate(5), cuirCreateValueImmediate(5));
	v = builder.buildAdd(v, cuirCreateValueImmediate(5));
	v = builder.buildAdd(v, cuirCreateValueImmediate(5));
	v = builder.buildSub(v, cuirCreateValueImmediate(5));

	CuIRBuilder builder2 = new CuIRBuilder(func.appendBlock("other"));
	builder2.buildRet();
	
	builder.buildJump(builder2.getBlock());

	writeln(asm_.getStringPretty());
	asm_.toFile("test");
}
}
