/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.elements.value;
import ir.elements.element;
import ir.elements.types.type;

import std.traits;
import std.format;
import ir.elements.io;

class CuValue : CuElement {
private:
    this() { }

package:
    CuType type;
    string name;

public:

    this(CuType type, string name=null) {
        this.type = type;
        this.name = name;
    }

    override
    void serialize(StreamWriter buffer) {

        // Write initial value (none)
        buffer.write(false);

        // Write type
        if (CuScopedType stype = cast(CuScopedType)type) {
            buffer.write(cuirReferToType(stype));
        } else {
            buffer.write(type);
        }

        // write name
        buffer.write(name);
    }

    override
    void deserialize(CuScopedReader buffer) {
        buffer.read(type);
        buffer.read(name);
    }

    static CuValue deserializeSelect(CuScopedReader buffer) {
        CuValue outValue;
        bool hasInitialValue;
        buffer.read(hasInitialValue);

        if (hasInitialValue) {
            CuTypeId id;
            buffer.peek(id);

            switch(id) {
                case CuTypeId.ubyte_:
                    outValue = new CuImmediateValue!ubyte();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.ushort_:
                    outValue = new CuImmediateValue!ushort();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.uint_:
                    outValue = new CuImmediateValue!uint();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.ulong_:
                    outValue = new CuImmediateValue!ulong();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.bool_:
                    outValue = new CuImmediateValue!bool();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.byte_:
                    outValue = new CuImmediateValue!byte();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.short_:
                    outValue = new CuImmediateValue!short();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.int_:
                    outValue = new CuImmediateValue!int();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.long_:
                    outValue = new CuImmediateValue!long();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.float_:
                    outValue = new CuImmediateValue!float();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.double_:
                    outValue = new CuImmediateValue!double();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.char_:
                    outValue = new CuImmediateValue!char();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.wchar_:
                    outValue = new CuImmediateValue!wchar();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.dchar_:
                    outValue = new CuImmediateValue!dchar();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.string_:
                    outValue = new CuImmediateValue!string();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.wstring_:
                    outValue = new CuImmediateValue!wstring();
                    outValue.deserialize(buffer);
                    break;
                case CuTypeId.dstring_:
                    outValue = new CuImmediateValue!dstring();
                    outValue.deserialize(buffer);
                    break;
                default: throw new Exception("Type can not be immediate.");
            }
            return outValue;
        }

        // Normal CuValue
        outValue = new CuValue();
        outValue.deserialize(buffer);
        return outValue;
    }

    override void resolve() {
        type.resolve();
    }

    bool isImmediate() { return false; }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;
        import std.format : format;
        if (name.length > 0) {
            return "%s %s".format(type.getStringPretty(), name);
        }
        return type.getStringPretty();
    }

    string getName() {
        return name;
    }

    void setName(string name) {
        this.name = name;
    }

    CuType getType() {
        return type;
    }

    void setType(CuType type) {
        this.type = type;
    }
}

CuValue cuirCreateValue(CuType type, string name=null) {
    return new CuValue(type, name);
}

enum CanBeImmediateValue(T) =
    is(T == ubyte) ||
    is(T == ushort) ||
    is(T == uint) ||
    is(T == ulong) ||
    is(T == bool) ||
    is(T == byte) ||
    is(T == short) ||
    is(T == int) ||
    is(T == long) ||
    is(T == float) ||
    is(T == double) ||
    is(T == char) ||
    is(T == wchar) ||
    is(T == dchar) ||
    is(T == string) ||
    is(T == wstring) ||
    is(T == dstring);

class CuImmediateValue(T) : CuValue if (CanBeImmediateValue!T) {
private:
    this() { }

    this(T value, string name=null) {
        static if (is(T == size_t)) super(cuirCreateFromTypeId(CuTypeId.usize_));
        else static if (is(T == ptrdiff_t)) super(cuirCreateFromTypeId(CuTypeId.ssize_));
        else {
            mixin("super(cuirCreateFromTypeId(CuTypeId.%s_));".format(T.stringof));
        }
        this.name = name;
        this.value = value;
    }

public:
    T value;

    override
    void serialize(StreamWriter buffer) {
        // Write initial value (none)
        buffer.write(true);
        buffer.write(type);
        buffer.write(value);
    }

    override
    void deserialize(CuScopedReader buffer) {
        buffer.read(type);
        buffer.read(value);
    }

    override void resolve() {
        type.resolve();
    }

    override
    bool isImmediate() { return true; }

    override
    string getStringPretty() {
        import compiler.common.utils : offsetByLines;
        import std.format : format;
        if (name.length > 0) {
            return "%s %s = %s".format(type.getStringPretty(), name, value);
        } else {
            return "%s".format(value);
        }
    }
}

CuValue cuirCreateValueImmediate(T)(T value, string name=null) {
    return new CuImmediateValue!T(value, name);
}