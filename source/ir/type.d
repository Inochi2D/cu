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
    u8          = 0x06,
    u16         = 0x07,
    u32         = 0x08,
    u64         = 0x09,
    usize       = 0x0A,
    
    f16         = 0x10,
    f32         = 0x11,
    f64         = 0x12,

    ptr_        = 0x20,
    function_   = 0x21,
    delegate_   = 0x22,
    struct_     = 0xF0,
    class_      = 0xF1,
    interface_  = 0xF2,
}

enum TypeAttribute : uint {
    none_       = 0x00,
    private_    = 0b00000000_00000000_00000000_00000001,
    public_     = 0b00000000_00000000_00000000_00000010,
    gshared_    = 0b00000000_00000000_00000000_00000100,
    static_     = 0b00000000_00000000_00000000_00001000,

    final_      = 0b00000000_00000000_00000001_00000000,
    virtual_    = 0b00000000_00000000_00000010_00000000,
    abstract_   = 0b00000000_00000000_00000100_00000000,
}

class CuIRBaseType {
private:
    string tagName;

protected:
    final
    string attribsToString() {
        if (cast(uint)attribs == 0) return "";
        string attribStr;

        if ((attribs & TypeAttribute.private_) == TypeAttribute.private_) attribStr = "private ";
        if ((attribs & TypeAttribute.public_) == TypeAttribute.public_) attribStr = "public ";
        if ((attribs & TypeAttribute.gshared_) == TypeAttribute.gshared_) attribStr ~= "gshared ";
        if ((attribs & TypeAttribute.static_) == TypeAttribute.static_) attribStr ~= "static ";
        if ((attribs & TypeAttribute.final_) == TypeAttribute.final_) attribStr ~= "final ";
        if ((attribs & TypeAttribute.virtual_) == TypeAttribute.virtual_) attribStr ~= "virtual ";


        return "["~attribStr[0..$-1]~"]";
    }

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

    /**
        Type attributes
    */
    TypeAttribute attribs;

    this(TypeTag tag, string name = "", TypeAttribute attrib = TypeAttribute.public_) {
        this.tag = tag;
        this.attribs = attribs;
        this.tagName = tag.text;
        this.name = name;

        // Pointers and compounds
        switch(this.tag) {
            case TypeTag.void_:

                // Special case, void needs to be renamed
                this.tagName = "void";
                break;
                
            case TypeTag.class_:

                // Special case, void needs to be renamed
                this.tagName = "class";
                break;

            case TypeTag.struct_:

                // Special case, void needs to be renamed
                this.tagName = "struct";
                break;

            case TypeTag.interface_:

                // Special case, void needs to be renamed
                this.tagName = "interface";
                break;

            case TypeTag.i8:
            case TypeTag.u8:
                this.length = 1;
                break;

            case TypeTag.i16:
            case TypeTag.u16:
            case TypeTag.f16:
                this.length = 2;
                break;

            case TypeTag.i32:
            case TypeTag.u32:
            case TypeTag.f32:
                this.length = 4;
                break;

            case TypeTag.i64:
            case TypeTag.u64:
            case TypeTag.f64:
                this.length = 8;
                break;
            
            case TypeTag.isize:
            case TypeTag.usize:
            case TypeTag.ptr_:
            case TypeTag.function_:
                this.length = size_t.sizeof;
                break;

            case TypeTag.delegate_:
                this.length = size_t.sizeof*2;
                break;

            default: break;
        }
    }

    string getName() {
        if (name.length > 0) return tagName~" "~name;
        else return tagName;
    }

    CuIRBaseType setName(string name) {
        this.name = name;
        return this;
    }

    CuIRBaseType setAttributes(TypeAttribute attribs) {
        this.attribs = attribs;
        return this;
    }

    /**
        Gets string representation of name
    */
    override
    string toString() {
        return attribsToString()~getName();
    }

    /**
        Binary representation for initial declaration
    */
    ubyte[] toBinaryDecl() {
        return nativeToLittleEndian(cast(uint)attribs)[0..4]~[cast(ubyte)tag];
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
public:
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

@("IR Compound Types")
unittest {
    auto struct_ = cuirCreateStruct(
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    CuIRInterfaceType iface = cast(CuIRInterfaceType)cuirCreateInterface([
        cuirCreateFunc(cuirCreateVoid()).setName("myFunc")
    ]).setName("MyInterface");

    CuIRClassType baseClass = cast(CuIRClassType)cuirCreateClass(
        [
            cuirCreateF16(),
            cuirCreateFunc(cuirCreateF32(), [cuirCreateF32(), cuirCreateF32()]).setName("atan2")
        ]
    ).setName("BaseClass").setAttributes(TypeAttribute.abstract_ | TypeAttribute.public_);

    CuIRClassType subClass = cast(CuIRClassType)cuirCreateClass(
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(struct_)
        ],
        baseClass,
        [iface]
    ).setName("SubClass").setAttributes(TypeAttribute.public_);

    assert(struct_.toString() == "struct (f16, i8)");
    assert(baseClass.toString() == "[public]class BaseClass(f16, function f32 atan2(f32, f32))");
    assert(iface.toString() == "interface MyInterface(function void myFunc())");
    assert(subClass.toString() == "[public]class:(class BaseClass,interface MyInterface) SubClass(f16, i8, struct (f16, i8)*)");
}

class CuIRFuncType : CuIRBaseType {
public:
    /**
        List of members
    */
    CuIRBaseType[] parameters;
    CuIRBaseType returnType;

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
}

CuIRFuncType cuirCreateFunc(CuIRBaseType retVal, CuIRBaseType[] params = null) { return new CuIRFuncType(retVal, params); }

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
}

CuIRFuncType cuirCreateDelegate(CuIRBaseType retVal, CuIRBaseType[] params = null) { return new CuIRDelegateType(retVal, params); }

@("IR Functions & Delegates")
unittest {

    auto typ1 = cuirCreateDelegate(
        cuirCreateVoid(),
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    typ1.name = "uwu";

    auto typ2 = cuirCreateFunc(
        cuirCreateI32(),
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(typ1)
        ]
    );

    assert(typ1.toString() == "delegate void uwu(f16, i8)");
    assert(typ2.toString() == "function i32 (f16, i8, delegate void uwu(f16, i8)*)");
}