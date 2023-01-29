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
    /**
        Qualifying name for the dependency
    */
    string name;
    
    /**
        Version of the dependency
    */
    CuVersion version_;

    void serialize(StreamWriter buffer) {
        buffer.write(name);
        buffer.write(version_.major);
        buffer.write(version_.minor);
        buffer.write(version_.patch);
    }

    void deserialize(CuScopedReader buffer) {
        buffer.read(name);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
    }

    void deserialize(StreamReader buffer) {
        buffer.read(name);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
    }
}

struct CuAssemblyInfo {

    /**
        Flags describing what type of assembly this is
    */
    CuAssemblyFlags flags;

    /**
        Cu Assembly name in format of (Name.cua)
    */
    string name;

    /**
        Name of the assembly
    */
    string humanName;

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

    void serialize(StreamWriter buffer) {
        buffer.write(cast(ushort)flags);
        buffer.write(version_.major);
        buffer.write(version_.minor);
        buffer.write(version_.patch);
        buffer.write(name);
        buffer.write(humanName);
        buffer.write(author);
        buffer.write(copyright);
        buffer.write(dependencies);
    }

    void deserialize(CuScopedReader buffer) {
        buffer.read(flags);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
        buffer.read(name);
        buffer.read(humanName);
        buffer.read(author);
        buffer.read(copyright);
        buffer.read(dependencies);
    }

    void deserialize(StreamReader buffer) {
        buffer.read(flags);
        buffer.read(version_.major);
        buffer.read(version_.minor);
        buffer.read(version_.patch);
        buffer.read(name);
        buffer.read(humanName);
        buffer.read(author);
        buffer.read(copyright);

        uint dependencyCount;
        buffer.read(dependencyCount);
        foreach(i; 0..dependencyCount) {
            CuAssemblyDependency dep;
            dep.deserialize(buffer);
            dependencies ~= dep;
        }
        
    }
}

class CuAssembly : CuElement {
private:

public:
    /**
        Information about an assembly
    */
    CuAssemblyInfo info;

    /**
        Modules exposed by the assembly
    */
    CuModule[] modules;

    override
    void serialize(StreamWriter buffer) {
        buffer.rawWrite(CU_MAGIC_BYTES);
        buffer.write(info);
        buffer.write(modules);
    }

    override
    void deserialize(CuScopedReader buffer) {
        enforce(buffer.rawRead!string(CU_MAGIC_BYTES.length) == CU_MAGIC_BYTES, "Not Cu Assembly");
        buffer.read(info);
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
        Gets information about cu assembly from a stream
    */
    static CuAssemblyInfo infoFromStream(Stream stream) {
        CuAssemblyInfo info;
        info.deserialize(new StreamReader(stream));
        return info;
    }

    /**
        Gets information about cu assembly from a file
    */
    static CuAssemblyInfo infoFromFile(string path) {
        import std.stdio : File;
        FileStream stream = new FileStream(File(path, "rb"));
        return CuAssembly.infoFromStream(stream);
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
        return (info.flags & CuAssemblyFlags.executable) == CuAssemblyFlags.executable;
    }

    bool isLibrary() {
        return (info.flags & CuAssemblyFlags.library) == CuAssemblyFlags.library;
    }

    CuScopedType findFromPath(string path) {
        return null;
    }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;
        import std.format : format;

        string oString = "version %s\nauthor \"%s\"\ncopyright \"%s\"\n".format(info.version_.toString(), info.author, info.copyright);
        foreach(mod; modules) {
            oString ~= mod.getStringPretty();
        }

        return "assembly \"%s (%s)\" {\n%s}".format(info.name, info.humanName, offsetByLines(oString, 2));
    }
}