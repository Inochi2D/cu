module ir.types.structs;
import ir.types.basetype;
import std.bitmanip;

class CuIRStructType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] members;

    this(CuIRBaseType[] members) {
        super(TypeTag.struct_);
        this.members = members;
        this.recalcLength();
    }

    override
    string toString() {
        string strct = attribsToString()~"struct "~name~"(";
        foreach(i; 0..members.length) {
            strct ~= members[i].toString();
            if (i+1 < members.length) strct ~= ", ";
        }
        return strct~")";
    }

    /**
        Add a member to the compound type
    */
    void addMember(CuIRBaseType type) {
        members ~= type;
        this.recalcLength();
    }

    /**
        Recalculate the length of the type
    */
    final
    void recalcLength() {
        this.length = 0;
        foreach(member; members) this.length += member.length;
    }

    /**
        Binary representation for initial declaration
    */
    override
    ubyte[] toBinaryDecl() {
        ubyte[] decl = 
            [cast(ubyte)tag]~
            nativeToLittleEndian!uint(cast(uint)members.length);

        foreach(member; members) {
            decl ~= member.toBinaryDecl();
        }

        return decl;
    }
}

CuIRStructType cuirCreateStruct(CuIRBaseType[] members = null) { return new CuIRStructType(members); }
 