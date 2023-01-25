module ir.types.interfaces;
import ir.types.basetype;
import std.bitmanip;


class CuIRInterfaceType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] members;

    this(CuIRBaseType[] members) {
        super(TypeTag.interface_);
        this.members = members;
        this.recalcLength();
    }

    override
    string toString() {
        string strct = attribsToString()~"interface "~name~"(";
        foreach(i; 0..members.length) {
            strct ~= members[i].toString();
            if (i+1 < members.length) strct ~= ", ";
        }
        return strct~")";
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
        Add a member to the compound type
    */
    void addMember(CuIRBaseType type) {
        members ~= type;
        this.recalcLength();
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

CuIRInterfaceType cuirCreateInterface(CuIRBaseType[] members = null) { return new CuIRInterfaceType(members); }