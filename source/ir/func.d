/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.func;
import ir.types.type;
import ir.mod;
import ir.io;
import ir.block;
import std.format;

enum CuFuncCallingConvention {
    /**
        The DLang calling convention (default)
    */
    d,

    /**
        Automatically select appropriate C calling convention for platform
    */
    cauto,

    /**
        CDECL calling convention, used on POSIX systems
    */
    cdecl,

    /**
        Windows calling convention, used on Windows.
    */
    windows
}

class CuFunc : CuScopedType {
private:
    struct CuFuncArg {
        string name;
        CuType param;

        void serialize(StreamWriter buffer) {
            buffer.write(name);
            buffer.write(param);
        }

        void deserialize(CuScopedReader buffer) {
            buffer.read(name);
            buffer.read(param);
        }
    }

    CuType returnType;
    CuFuncArg[] parameters;
    bool isVararg;
protected:

package(ir):
    this() { super(); this.typeId = CuTypeId.function_; }

    this(string name, CuType returnType) {
        super(name);
        this.typeId = CuTypeId.function_;
        this.returnType = returnType;
    }

    this(string name) {
        this(name, cuirCreateVoid());
    }

    CuFuncCallingConvention callingconv;
    CuBasicBlock[] blocks;

public:

    /**
        Adds an argument to the function
    */
    void addArg(CuType type, string name=null) {
        if (CuScopedType stype = cast(CuScopedType)type) {
            parameters ~= CuFuncArg(name, cuirReferToType(stype));
        } else {
            parameters ~= CuFuncArg(name, type);
        }
    }

    /**
        Gets the return type of this function
    */
    CuType getReturnType() {
        return returnType;
    }

    /**
        Sets the return type for this function
    */
    void setReturnType(CuType returnType) {
        this.returnType = returnType;
    }

    /**
        Gets the calling convention of this function
    */
    CuFuncCallingConvention getCallingConvention() {
        return callingconv;
    }

    /**
        Sets the calling convention for this function
    */
    void setCallingConvention(CuFuncCallingConvention callingconv) {
        this.callingconv = callingconv;
    }

    /**
        Gets the name of the type
    */
    override
    string getTypeName() {
        import std.format;
        string params = "";
        foreach(i, param; parameters) {
            if (i+1 < parameters.length) params ~= param.param.getTypeName()~",";
            else params ~= param.param.getTypeName();
        }

        return "%s %s(%s)".format(returnType.getTypeName(), name, params);
    }

    /**
        Gets whether a specified basic block is in the function
    */
    bool hasBlock(string name) {
        foreach(block; blocks) {
            if (block.getName() == name) return true; 
        }
        return false;
    }

    /**
        Gets the specified basic block, returns null if none is found
    */
    CuBasicBlock getBlock(string name) {
        foreach(ref block; blocks) {
            if (block.getName() == name) return block; 
        }
        return null;
    }

    /**
        Appends a basic block on to the function
    */
    CuBasicBlock appendBlock(string name) {
        if (this.hasBlock(name)) throw new Exception("Block name already taken");
        auto block = new CuBasicBlock(this, name);
        blocks ~= block;
        return block;
    }

    override
    void serialize(StreamWriter buffer) {
        super.serialize(buffer);
        buffer.write(returnType);
        buffer.write(name);
        buffer.write(parameters);
        buffer.write(blocks);
    }

    override
    void deserialize(CuScopedReader buffer) {
        super.deserialize(buffer);
        buffer.read(returnType);
        buffer.read(name);
        buffer.read(parameters);
        buffer.read(blocks);
    }

    
    override
    void resolve() {
        super.resolve();
        foreach(ref block; blocks) {
            block.setParent(this);
            block.resolve();
        }
    }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;

        string disasm;
        foreach(block; blocks) {
            disasm ~= "\n"~block.getStringPretty();
        }
        return "%s {%s}".format(getTypeName(), offsetByLines(disasm, 2));
    }
}