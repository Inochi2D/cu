module common.io.writer;
import common.io.stream;
import std.traits;
import std.bitmanip;

public import std.system : Endian, endian;

/**
    Compiletime enum which determines whether a class or struct type can be serialized

    StreamSerializable!T is true at compile time if:
        1. `T` has a member called `serialize`
        2. `serialize` can be called like a function
        3. `serialize` has exactly 1 parameter
        4. The type of that parameter can be cast to `StreamWriter`
        5. The return type is `void`
*/
enum StreamSerializable(T) = 
    __traits(hasMember, T, "serialize") && 
    isCallable!(T.serialize) &&
    Parameters!(T.serialize).length == 1 && 
    is(Parameters!(T.serialize)[0] : StreamWriter) &&
    is(ReturnType!(T.serialize) == void);

class StreamWriter {
private:
    Stream backingStream;
    Endian endianess;

public:
    this(Stream stream, Endian endianess = Endian.littleEndian) {
        this.backingStream = stream;
        this.endianess = endianess;
    }

    /**
        Write data to stream
    */
    void write(ushort value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(uint value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(ulong value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(short value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(int value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(long value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(float value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(double value) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    void write(T)(T value) if (is(T == enum)) {
        switch(endianess) {
            case Endian.littleEndian:
                backingStream.write(nativeToLittleEndian(value)[0..value.sizeof]);
                break;
            case Endian.bigEndian:
                backingStream.write(nativeToBigEndian(value)[0..value.sizeof]);
                break;
            default: assert(0);
        }
    }

    /**
        Write data to stream
    */
    void write(bool value) {
        backingStream.write(cast(ubyte[])[value]);
    }

    /**
        Write data to stream
    */
    void write(string value) {
        this.write(cast(uint)value.length);
        backingStream.write(cast(ubyte[])value);
    }

    /**
        Write data to stream
    */
    void write(char value) {
        backingStream.write(cast(ubyte[])[value]);
    }


    /**
        Write data to stream
    */
    void write(dchar value) {
        this.write(cast(ushort)value);
    }

    /**
        Write data to stream
    */
    void write(wchar value) {
        this.write(cast(uint)value);
    }

    /**
        Write data to stream
    */
    void write(T)(T[] value) {
        this.write(cast(uint)value.length);
        foreach(ref item; value) {
            this.write(item);
        }
    }

    /**
        Write data to stream
    */
    void write(T)(T value) if (StreamSerializable!T) {
        value.serialize(this);
    }


    /**
        Write data to stream
    */
    void rawWrite(T)(T[] value) if (isBasicType!T) {
        backingStream.write(cast(ubyte[])value);
    }

    /**
        Write data to stream
    */
    void rawWrite(string value) {
        backingStream.write(cast(ubyte[])value);
    }

    ref Stream getStream() {
        return backingStream;
    }
}