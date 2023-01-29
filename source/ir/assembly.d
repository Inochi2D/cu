/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.assembly;
import ir.element;
import ir.mod;
import ir.types.type;
import std.exception : enforce;

public import common.io.writer;
public import common.io.reader;
public import common.io.stream;
public import ir.io;
import std.socket;

/**
    Flags describing an assembly
*/
enum CuAssemblyFlags : ushort {
    executable  = 0x01,
    library     = 0x02
}

/**
    Version of an assembly
*/
struct CuVersion {

    /**
        Major version
    */
    int major;

    /**
        Minor version
    */
    int minor;

    /**
        Patch version
    */
    int patch;

    string toString() const {
        import std.format : format;
        return "%s.%s.%s".format(major, minor, patch);
    }
}

enum CU_MAGIC_BYTES = "CUASM00";

struct CuAssemblyDependency {
    string fileName;
    CuVersion version_;

    void serialize(StreamWriter buffer) {
        buffer.write(fileName);
        buffer.write(version_.major);
        buffer.write(version_.minor);
        buffer.write(version_.patch);
    }

    void deserialize(CuScopedReader buffer) {
        buffer.read(fileName);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
    }
}

class CuAssembly : CuElement {
private:

public:
    /**
        Flags describing what type of assembly this is
    */
    CuAssemblyFlags flags;

    /**
        Name of the assembly
    */
    string name;

    /**
        Author of the assembly
    */
    string author;

    /**
        Copyright string of the assembly
    */
    string copyright;

    /**
        Version of the assembly
    */
    CuVersion version_;

    /**
        Assemblies this assembly depends on
    */
    CuAssemblyDependency[] dependencies;

    /**
        Modules exposed by the assembly
    */
    CuModule[] modules;

    override
    void serialize(StreamWriter buffer) {
        buffer.rawWrite(CU_MAGIC_BYTES);
        buffer.write(cast(ushort)flags);
        buffer.write(version_.major);
        buffer.write(version_.minor);
        buffer.write(version_.patch);
        buffer.write(name);
        buffer.write(author);
        buffer.write(copyright);
        buffer.write(dependencies);
        buffer.write(modules);
    }

    override
    void deserialize(CuScopedReader buffer) {
        enforce(buffer.rawRead!string(CU_MAGIC_BYTES.length) == CU_MAGIC_BYTES, "Not Cu Assembly");
        buffer.read(flags);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
        buffer.read(name);
        buffer.read(author);
        buffer.read(copyright);
        buffer.read(dependencies);
        buffer.read(modules);
        this.resolve();
    }

    /**
        Creates a Cu Assembly from a stream
    */
    static CuAssembly fromStream(Stream stream) {
        CuAssembly asm_ = new CuAssembly;
        asm_.deserialize(new CuScopedReader(asm_, stream));
        return asm_;
    }

    /**
        Creates a Cu Assembly from a file
    */
    static CuAssembly fromFile(string path) {
        import std.stdio : File;
        FileStream stream = new FileStream(File(path, "rb"));
        return CuAssembly.fromStream(stream);
    }

    /**
        Creates a Cu Assembly file (.cua)
    */
    void toFile(string file) {
        import std.stdio : File;
        import std.path : setExtension;
        string path = file.setExtension("cua");
        this.toStream(new FileStream(File(path, "wb")));
    }

    /**
        Writes the Cu Assembly to the specified stream
    */
    void toStream(Stream stream) {
        this.serialize(new StreamWriter(stream));
    }

    override
    void resolve() {
        foreach(ref mod; modules) {
            mod.resolve();
        }
    }

    bool isExectuable() {
        return (flags & CuAssemblyFlags.executable) == CuAssemblyFlags.executable;
    }

    bool isLibrary() {
        return (flags & CuAssemblyFlags.library) == CuAssemblyFlags.library;
    }

    CuScopedType findFromPath(string path) {
        return null;
    }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;
        import std.format : format;

        string oString = "version %s\nauthor \"%s\"\ncopyright \"%s\"\n".format(version_.toString(), author, copyright);
        foreach(mod; modules) {
            oString ~= mod.getStringPretty();
        }

        return "assembly \"%s\" {\n%s}".format(name, offsetByLines(oString, 2));
    }
}