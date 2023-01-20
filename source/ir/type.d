module ir.type;
import std.conv : text;
import std.bitmanip;

enum TypeTag : ubyte {
    void_       = 0x00,

    i8          = 0x01,
    i16         = 0x02,
    i32         = 0x03,
    i64         = 0x04,
    isize       = 0x05,
    
    f16         = 0x10,
    f32         = 0x11,
    f64         = 0x12,

    ptr_        = 0x20,
    func        = 0x21,
    struct_     = 0xF0,
}

class CuIRBaseType {
public:
    /**
        Length of the type in bytes
    */
    size_t length;

    /**
        Name of the type
    */
    string name;

    /**
        Type tag
    */
    TypeTag tag;

    this(TypeTag tag) {
        this.tag = tag;
        this.name = tag.text;

        // Pointers and compounds
        switch(this.tag) {
            case TypeTag.void_:

                // Special case, void needs to be renamed
                this.name = "void";
                break;
            case TypeTag.struct_:

                // Special case, void needs to be renamed
                this.name = "struct";
                break;

            case TypeTag.i8:
                this.length = 1;
                break;

            case TypeTag.i16:
            case TypeTag.f16:
                this.length = 2;
                break;

            case TypeTag.i32:
            case TypeTag.f32:
                this.length = 4;
                break;

            case TypeTag.i64:
            case TypeTag.f64:
                this.length = 8;
                break;
            
            case TypeTag.isize:
            case TypeTag.ptr_:
            case TypeTag.func:
                this.length = size_t.sizeof;
                break;

            default: break;
        }
    }

    this(string name) {
        this(TypeTag.struct_);
        this.name = name;
    }

    /**
        Gets string representation of name
    */
    override
    string toString() {
        return name;
    }

    /**
        Binary representation for initial declaration
    */
    ubyte[] toBinaryDecl() {
        return [tag];
    }
}

CuIRBaseType cuirCreateVoid() { return new CuIRBaseType(TypeTag.void_); }
CuIRBaseType cuirCreateI8() { return new CuIRBaseType(TypeTag.i8); }
CuIRBaseType cuirCreateI16() { return new CuIRBaseType(TypeTag.i16); }
CuIRBaseType cuirCreateI32() { return new CuIRBaseType(TypeTag.i32); }
CuIRBaseType cuirCreateI64() { return new CuIRBaseType(TypeTag.i64); }
CuIRBaseType cuirCreateISize() { return new CuIRBaseType(TypeTag.isize); }

CuIRBaseType cuirCreateF16() { return new CuIRBaseType(TypeTag.f16); }
CuIRBaseType cuirCreateF32() { return new CuIRBaseType(TypeTag.f32); }
CuIRBaseType cuirCreateF64() { return new CuIRBaseType(TypeTag.f64); }

@("IR Base Type")
unittest {
    assert(cuirCreateVoid().toString() == "void");
    assert(cuirCreateI8().toString() == "i8");
    assert(cuirCreateI16().toString() == "i16");
    assert(cuirCreateI32().toString() == "i32");
    assert(cuirCreateI64().toString() == "i64");

}

class CuIRPointerType : CuIRBaseType {
    /**
        The inner type of the type, 
    */
    CuIRBaseType pointerTo;

    /**
        Creates a new pointer type
    */
    this(CuIRBaseType baseType) {
        super(TypeTag.ptr_);
        this.pointerTo = baseType;
        this.name = baseType.name;
    }

    override
    string toString() {
        // if (pointerTo.tag == TypeTag.struct_)
        //     return pointerTo.name~"*";
        return pointerTo.toString()~"*";
    }

    /**
        Binary representation for initial declaration
    */
    override
    ubyte[] toBinaryDecl() {
        return [cast(ubyte)tag]~pointerTo.toBinaryDecl();
    }
}

/// Create pointer type
CuIRPointerType cuirPointerTo(CuIRBaseType type) { return new CuIRPointerType(type); }

@("IR Pointer Types")
unittest {
    assert(cuirPointerTo(cuirCreateI64()).toString(), "i64*");
    assert(cuirPointerTo(cuirPointerTo(cuirCreateI64())).toString(), "i64**");
}

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
        string strct = "struct (";
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

@("IR Compound Types")
unittest {
    import std.stdio : writeln;

    auto typ1 = cuirCreateStruct(
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    auto typ2 = cuirCreateStruct(
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(typ1)
        ]
    );

    writeln(typ1, "\n", typ2);
}

class CuIRFuncType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] parameters;
    CuIRBaseType returnType;

    this(CuIRBaseType returnType, CuIRBaseType[] parameters) {
        super(TypeTag.func);
        this.returnType = returnType; 
        this.parameters = parameters;
        this.name = name;
    }

    override
    string toString() {
        string func = returnType.toString()~"(";
        foreach(i; 0..parameters.length) {
            func ~= parameters[i].toString();
            if (i+1 < parameters.length) func ~= ", ";
        }
        return func~")";
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
}

CuIRFuncType cuirCreateFunc(CuIRBaseType retVal, CuIRBaseType[] params = null) { return new CuIRFuncType(retVal, params); }

@("IR Compound Types")
unittest {
    import std.stdio : writeln;

    auto typ1 = cuirCreateFunc(
        cuirCreateVoid(),
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    auto typ2 = cuirCreateFunc(
        cuirCreateI32(),
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(typ1)
        ]
    );

    writeln(typ1, "\n", typ2);
}