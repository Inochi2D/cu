module ir.types.classes;
import ir.types.basetype;
import ir.types.interfaces;
import std.bitmanip;

class CuIRClassType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] members;
    CuIRClassType extends;
    CuIRInterfaceType[] implements;

    this(CuIRBaseType[] members, CuIRClassType extends = null, CuIRInterfaceType[] implements = null) {
        super(TypeTag.class_);
        this.members = members;
        this.extends = extends;
        this.implements = implements;
        this.recalcLength();
    }

    override
    string toString() {
        string strct = attribsToString()~"class";
        
        if (extends || implements.length > 0) strct ~= ":(";
        if (extends) strct ~= extends.getName();
        if (implements.length > 0) {
            if (extends) strct ~= ",";
            foreach(i; 0..implements.length) {
                strct ~= implements[i].getName();
                if (i+1 < implements.length) strct ~= ",";
            }
        }
        if (extends || implements) strct ~= ")";
        

        strct ~= " "~name~"(";
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

        if (extends) {
            extends.recalcLength();
            this.length += extends.length;
        }

        if (implements) foreach(impl; implements) {
            impl.recalcLength();
            this.length += impl.length;
        }
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

CuIRClassType cuirCreateClass(CuIRBaseType[] members = null, CuIRClassType extends = null, CuIRInterfaceType[] implements = null) { return new CuIRClassType(members, extends, implements); }