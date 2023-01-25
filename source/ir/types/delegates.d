module ir.types.delegates;
import ir.types;
import ir.builder;
import std.bitmanip;
import ir.block;

class CuIRDelegateType : CuIRFuncType {
public:
    this(CuIRBaseType returnType, CuIRBaseType[] parameters) {
        super(returnType, parameters);
        this.tag = TypeTag.delegate_;
    }

    override
    string toString() {
        string func = "delegate "~returnType.toString()~" "~name~"(";
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
    override
    CuIRBuilder getBlock(string name) {
        if (name !in blocks) blocks[name] = new CuIRBlock(name, this);
        return new CuIRBuilder(blocks[name]);
    }
}

CuIRFuncType cuirCreateDelegate(CuIRBaseType retVal, CuIRBaseType[] params = null) { return new CuIRDelegateType(retVal, params); }
