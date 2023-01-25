module ir.value;
import ir.types;
import std.traits;
import ir.block;
import std.conv : text;
import std.math;

union CuIRValueOpqaue {
    byte        i8;
    short       i16;
    int         i32;
    long        i64;
    ubyte       u8;
    ushort      u16;
    uint        u32;
    ulong       u64;
    float       f32;
    double      f64;
    size_t      ptr;
    CuIRValue*  ref_;
}

struct CuIRValue {
private:
    CuIRBaseType type;
    string name;
    
    string valueStr;
    CuIRBlockRef blockRef;

public:
    this(CuIRBaseType type, string name=null) {
        this.type = type;
        this.name = name;
    }

    void setName(string name) {
        this.name = name;
    }

    string getName() {
        return this.name;
    }

    CuIRBaseType getType() {
        return type;
    }

    void setValue(string valueStr) {
        this.valueStr = valueStr;
    }

    void setValue(CuIRBlockRef blockRef) {
        this.blockRef = blockRef;
    }

    string getValue() {
        if (blockRef) return blockRef.getName();
        return valueStr;
    }
}

CuIRValueRef cuirCreateInt(T)(T value) if(isIntegral!T) {
    auto rvalue = new CuIRValue(cuirTypeCreateISized(T.sizeof*8));
    rvalue.setValue(value.text);
    return rvalue;
}

CuIRValueRef cuirCreateUInt(T)(T value) if(isIntegral!T) {
    auto rvalue = new CuIRValue(cuirTypeCreateUSized(T.sizeof*8));
    rvalue.setValue(value.text);
    return rvalue;
}

alias CuIRValueRef = CuIRValue*;