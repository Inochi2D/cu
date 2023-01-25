module ir.types.basetype;
import std.conv : text;
import std.bitmanip;

enum TypeTag : ubyte {
    void_       = 0x00,

    isized_     = 0x01,
    usized_     = 0x02,
    
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
            
            case TypeTag.usized_:
            case TypeTag.isized_:
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

    this(TypeTag tag, size_t size) {
        this.length = size;
        this.tag = tag;
        this.tagName = "i"~size.text;
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

CuIRBaseType cuirTypeCreateVoid() { return new CuIRBaseType(TypeTag.void_); }
CuIRBaseType cuirTypeCreateI8()  { return new CuIRBaseType(TypeTag.isized_, 8); }
CuIRBaseType cuirTypeCreateI16() { return new CuIRBaseType(TypeTag.isized_, 16); }
CuIRBaseType cuirTypeCreateI32() { return new CuIRBaseType(TypeTag.isized_, 32); }
CuIRBaseType cuirTypeCreateI64() { return new CuIRBaseType(TypeTag.isized_, 64); }
CuIRBaseType cuirTypeCreateU8()  { return new CuIRBaseType(TypeTag.usized_, 8); }
CuIRBaseType cuirTypeCreateU16() { return new CuIRBaseType(TypeTag.usized_, 16); }
CuIRBaseType cuirTypeCreateU32() { return new CuIRBaseType(TypeTag.usized_, 32); }
CuIRBaseType cuirTypeCreateU64() { return new CuIRBaseType(TypeTag.usized_, 64); }

CuIRBaseType cuirTypeCreateISized(size_t size) { return new CuIRBaseType(TypeTag.isized_, size); }
CuIRBaseType cuirTypeCreateUSized(size_t size) { return new CuIRBaseType(TypeTag.usized_, size); }

CuIRBaseType cuirTypeCreateF32() { return new CuIRBaseType(TypeTag.f32); }
CuIRBaseType cuirTypeCreateF64() { return new CuIRBaseType(TypeTag.f64); }

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
