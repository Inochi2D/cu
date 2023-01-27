/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.elements.types.type;
import ir.elements.element;
import ir.elements.types.array;
import ir.elements.assembly;
import ir.elements.mod;
import ir.elements.func;

import std.format;
import ir.elements.io;
import core.int128;

enum CuTypeId : uint {
    void_       = 0x01,
    null_       = 0x02,

    byte_       = 0x0A,
    short_      = 0x0B,
    int_        = 0x0C,
    long_       = 0x0D,
    usize_      = 0x0E,
    bool_       = 0x0F,

    ubyte_      = 0x10,
    ushort_     = 0x11,
    uint_       = 0x12,
    ulong_      = 0x13,
    ssize_      = 0x14,

    float_      = 0x1A,
    double_     = 0x1B,

    char_       = 0x20,
    wchar_      = 0x21,
    dchar_      = 0x22,

    string_     = 0x2A,
    wstring_    = 0x2B,
    dstring_    = 0x2C,

    struct_     = 0xA0,
    union_      = 0xA1,
    interface_  = 0xA2,
    class_      = 0xA3,

    function_   = 0xAA,
    delegate_   = 0xAB,

    array_      = 0xB0,
    sarray_     = 0xB1,
    ptr_        = 0xB2,

    // Special type that references another type
    refToType   = 0xF0,
}

enum CuTypeAttributes {
    none        = 0x00,
    public_     = 0x01,
    private_    = 0x02,

}

class CuType : CuElement {
protected:
    CuAssembly assembly;

    CuTypeId typeId;
    CuTypeAttributes attribs = CuTypeAttributes.none;

    this(CuTypeId id) {
        this.typeId = id;
    }

package(ir):
    // For serialization
    this() { }

public:
    /**
        Gets the type id of the type
    */
    CuTypeId getTypeId() {
        return typeId;
    }

    /**
        Gets the name of the type id
    */
    string getTypeName() {
        import std.conv : text;
        return typeId.text[0..$-1];
    }

    /**
        Returns the size of a type
    */
    size_t getSizeOf() {
        switch(typeId) {
            case CuTypeId.void_:
                return 0;

            case CuTypeId.ubyte_:
            case CuTypeId.byte_:
            case CuTypeId.bool_:
            case CuTypeId.char_:
                return 1;

            case CuTypeId.ushort_:
            case CuTypeId.short_:
            case CuTypeId.wchar_:
                return 2;

            case CuTypeId.uint_:
            case CuTypeId.int_:
            case CuTypeId.dchar_:
            case CuTypeId.float_:
                return 4;

            case CuTypeId.ulong_:
            case CuTypeId.long_:
            case CuTypeId.double_:
                return 8;

            case CuTypeId.ptr_:
            case CuTypeId.usize_:
            case CuTypeId.ssize_:
            case CuTypeId.function_:
                return size_t.sizeof;

            case CuTypeId.array_:
            case CuTypeId.dstring_:
            case CuTypeId.wstring_:
            case CuTypeId.string_:

                // Arrays in D and Cu are fat pointers that consist of a
                // size_t length and T* pointer, size_t = size of a pointer
                // on the compiled for platform.
                return size_t.sizeof*2;

            default: return 0;
        }
    }

    /**
        Gets whether it's possible to cast between types
    */
    bool canCastTo(CuType other) {
        // Can cast to self, silly but *shrug*
        if (other.typeId == this.typeId) return true;

        switch(other.typeId) {

            // can't cast to void
            case CuTypeId.void_:
                return false;

            // Can cast between numeric types
            // Can also cast a pointer to a numeric type
            case CuTypeId.bool_:
            case CuTypeId.ubyte_:
            case CuTypeId.uint_:
            case CuTypeId.ushort_:
            case CuTypeId.ulong_:
            case CuTypeId.usize_:
            case CuTypeId.byte_:
            case CuTypeId.int_:
            case CuTypeId.short_:
            case CuTypeId.long_:
            case CuTypeId.ssize_:
            case CuTypeId.float_:
            case CuTypeId.double_:

                // Can only cast self to numeric types
                // If other is numeric type
                switch(this.typeId) {
                    case CuTypeId.bool_:
                    case CuTypeId.ubyte_:
                    case CuTypeId.uint_:
                    case CuTypeId.ushort_:
                    case CuTypeId.ulong_:
                    case CuTypeId.usize_:
                    case CuTypeId.byte_:
                    case CuTypeId.int_:
                    case CuTypeId.short_:
                    case CuTypeId.long_:
                    case CuTypeId.ssize_:
                    case CuTypeId.float_:
                    case CuTypeId.double_:
                        return true;

                    // Special case, can only cast pointers to types that can actually contain them
                    case CuTypeId.ptr_:
                        if (this.typeId == CuTypeId.ssize_) return true;
                        if (this.typeId == CuTypeId.usize_) return true;
                        if (size_t.sizeof == 4 && this.typeId == CuTypeId.uint_) return true;
                        if (size_t.sizeof == 4 && this.typeId == CuTypeId.int_) return true;
                        if (size_t.sizeof == 8 && this.typeId == CuTypeId.ulong_) return true;
                        if (size_t.sizeof == 8 && this.typeId == CuTypeId.long_) return true;

                        return false;

                    default: return false;
                }

            // Can cast chars and bytes between eachother (UTF-8)
            case CuTypeId.char_:
                if (this.typeId == CuTypeId.ubyte_) return true;
                if (this.typeId == CuTypeId.byte_) return true;
                return false;

            // Can cast dchars and shorts between eachother (UTF-16)
            case CuTypeId.wchar_:
                if (this.typeId == CuTypeId.ushort_) return true;
                if (this.typeId == CuTypeId.short_) return true;
                return false;

            // Can cast wchars and ints between eachother (UTF-32)
            case CuTypeId.dchar_:
                if (this.typeId == CuTypeId.uint_) return true;
                if (this.typeId == CuTypeId.int_) return true;
                return false;

            // You can cast an untyped null pointer to a typed null pointer,
            // if you really want to.
            case CuTypeId.ptr_:
                if (this.typeId == CuTypeId.null_) return true;
                return false;
            
            // This should not be called, special logic is implemented
            // for each other subtype
            default: return false;
        }
    }

    override
    void serialize(StreamWriter buffer) {
        buffer.write(cast(uint)typeId);
    }

    override
    void deserialize(CuScopedReader buffer) {
        assembly = buffer.assembly;
        buffer.read(cast(uint)typeId);
    }

    override void resolve() { }

    override string getStringPretty() { return getTypeName(); }

    /**
        Selector function
    */
    static CuType deserializeSelect(CuScopedReader reader) {
        CuTypeId id;
        reader.peek(id);
        switch(id) {
            case CuTypeId.array_:
                CuArray arr = new CuArray();
                reader.read(arr);
                return arr;

            case CuTypeId.sarray_:
                CuStaticArray arr = new CuStaticArray();
                reader.read(arr);
                return arr;
            

            case CuTypeId.function_:
                CuFunc func = new CuFunc();
                reader.read(func);
                return func;
            
            default:
                reader.skip(CuTypeId.sizeof);
                return new CuType(id);
        }
    }
}

CuType cuirCreateByte() { return new CuType(CuTypeId.byte_); }
CuType cuirCreateShort() { return new CuType(CuTypeId.short_); }
CuType cuirCreateInt() { return new CuType(CuTypeId.int_); }
CuType cuirCreateLong() { return new CuType(CuTypeId.long_); }
CuType cuirCreateSSize() { return new CuType(CuTypeId.ssize_); }

CuType cuirCreateUByte() { return new CuType(CuTypeId.ubyte_); }
CuType cuirCreateUShort() { return new CuType(CuTypeId.ushort_); }
CuType cuirCreateUInt() { return new CuType(CuTypeId.uint_); }
CuType cuirCreateULong() { return new CuType(CuTypeId.ulong_); }
CuType cuirCreateUSize() { return new CuType(CuTypeId.usize_); }

CuType cuirCreateFloat() { return new CuType(CuTypeId.float_); }
CuType cuirCreateDouble() { return new CuType(CuTypeId.double_); }

CuType cuirCreateNull() { return new CuType(CuTypeId.null_); }
CuType cuirCreateVoid() { return new CuType(CuTypeId.void_); }

CuType cuirCreateChar() { return new CuType(CuTypeId.char_); }
CuType cuirCreateWChar() { return new CuType(CuTypeId.wchar_); }
CuType cuirCreateDChar() { return new CuType(CuTypeId.dchar_); }
CuType cuirCreateString() { return new CuType(CuTypeId.string_); }
CuType cuirCreateWString() { return new CuType(CuTypeId.wstring_); }
CuType cuirCreateDString() { return new CuType(CuTypeId.dstring_); }

package(ir) CuType cuirCreateFromTypeId(CuTypeId id) { return new CuType(id); }


/**
    Reference to a Scoped Type
*/
class CuReferenceTo : CuType {
private:
    string pathToResolve;
    CuTypeId typeIdToResolve;

    this(CuScopedType referenceTo) {
        super(CuTypeId.array_);
        this.referenceTo = referenceTo;
    }

package(ir):
    this() { super(); }

public:
    /**
        The type of the array
    */
    CuScopedType referenceTo;

    override
    void serialize(StreamWriter buffer) {
        super.serialize(buffer);
        buffer.write(cast(uint)referenceTo.getTypeId());
        buffer.write(referenceTo.getPath());
    }

    override
    void deserialize(CuScopedReader buffer) {
        super.deserialize(buffer);
        buffer.read(typeIdToResolve);
        buffer.read(pathToResolve);
    }

    override
    void resolve() {
        referenceTo = assembly.findFromPath(pathToResolve);
    }
}

CuReferenceTo cuirReferToType(CuScopedType other) {
    return new CuReferenceTo(other);
}

enum CuTypeScope {
    module_,
    vtable_,
    compound_
}

class CuScopedType : CuType {
package(ir):
    this() { super(); }
public:
    this(string name) {
        super();
        this.name = name;
    }
    
    CuTypeScope scope_;
    union {
        /**
            The parent module
        */
        CuModule module_;

        /**
            The parent compound
        */
        //CuCompoundType compound_;

        /**
            The parent class
        */
        //CuClass class_;
    }

    /**
        Name of the scoped type
    */
    string name;

    /**
        Returns the path to the scoped type.
    */
    string getPath() {
        switch(scope_) {
            case CuTypeScope.module_:
                return "%s.%s".format(module_.getPath(), name);
            // case CuTypeScope.compound_:
            //     return "%s.%s".format(compound_.getPath(), name);
            default: return name;
        }
    }
}