/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.elements.mod;
import ir.elements.element;

public import common.io.writer;
public import common.io.reader;
import ir.elements.types.type;
import ir.elements.value;
import ir.elements.io;
import ir.elements.func;

class CuModule : CuElement {
private:

public:
    /**
        Name of the module
    */
    string name;

    /**
        The parent of the module (if any)
    */
    CuModule parent;

    /**
        The children of the module (if any)
    */
    CuModule[] submodules;

    /**
        global functions
    */
    CuFunc[] functions;

    /// Empty constructor
    this() { }

    /// Named submodule constructor
    this(string name) {
        this.name = name;
    }

    override
    void serialize(StreamWriter buffer) {
        buffer.write(name);
        buffer.write(submodules);
        buffer.write(functions);
    }

    override
    void deserialize(CuScopedReader buffer) {
        buffer.read(name);
        buffer.read(submodules);
        buffer.read(functions);
    }

    override
    void resolve() {
        foreach(ref mod; submodules) {
            mod.parent = this;
            mod.resolve();
        }

        foreach(ref func; functions) {
            func.resolve();
        }
    }

    /**
        Gets the specified submodule

        Returns null if the submodule is not found.
    */
    CuModule getSubmodule(string name) {
        foreach(ref mod; submodules) {
            if (mod.name == name) return mod;
        }
        return null;
    }


    /**
        Gets the specified submodule

        Creates a new module if the submodule is not found.
    */
    CuModule getOrCreateSubmodule(string name) {
        CuModule mod = getSubmodule(name);
        if (!mod) {
            mod = new CuModule(name);
            this.submodules ~= mod;
        }
        return mod;
    }

    CuFunc createFunction(string name, CuType returnType=cuirCreateVoid()) {
        auto func = new CuFunc(name, returnType);

        // Don't allow conflicting function defs
        foreach(efunc; functions) {
            if (efunc.getTypeName() == func.getTypeName()) throw new Exception("Conflicting function definition!");
        }

        // Add function to function table
        functions ~= func;
        return func;
    }

    /**
        Gets the path of this module
    */
    string getPath() {
        return parent ? parent.getPath()~"."~name : name;
    }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;
        import std.format : format;
        
        string oString;
        foreach(mod; submodules) {
            oString ~= "\n"~mod.getStringPretty();
        }
        foreach(decl; functions) {
            oString ~= "\n"~decl.getStringPretty();
        }

        return "module \"%s\" {%s}".format(name, offsetByLines(oString, 2));
    }
}