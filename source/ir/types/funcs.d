module ir.types.funcs;
import ir.types.basetype;
import ir.block;
import ir.builder;
import std.bitmanip;

class CuIRFuncType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] parameters;
    CuIRBaseType returnType;
    CuIRBlockRef[string] blocks;

    this(CuIRBaseType returnType, CuIRBaseType[] parameters) {
        super(TypeTag.function_);
        this.returnType = returnType; 
        this.parameters = parameters;
        this.name = name;
    }

    override
    string toString() {
        string func = "function "~returnType.toString()~" "~name~"(";
        foreach(i; 0..parameters.length) {
            func ~= parameters[i].toString();
            if (i+1 < parameters.length) func ~= ", ";
        }
        return attribsToString()~func~")";
    }

    /**
        Binary representation for initial declaration
    */
    override
    ubyte[] toBinaryDecl() {
        ubyte[] decl = 
            [cast(ubyte)tag]~
            nativeToLittleEndian!uint(cast(uint)name.length)~
            cast(ubyte[])name~
            nativeToLittleEndian!uint(cast(uint)parameters.length);

        foreach(param; parameters) {
            decl ~= param.toBinaryDecl();
        }

        return decl;
    }

    /**
        Gets a basic block within the function

        If none exists, one is created.
    */
    CuIRBuilder getBlock(string name) {
        if (name !in blocks) blocks[name] = new CuIRBlock(name, this);
        return new CuIRBuilder(blocks[name]);
    }

    /**
        Removes a block from the function
    */
    void removeBlock(string name) {
        if (name in blocks) blocks.remove(name);
    }
}

CuIRFuncType cuirCreateFunc(CuIRBaseType retVal, CuIRBaseType[] params = null) { return new CuIRFuncType(retVal, params); }