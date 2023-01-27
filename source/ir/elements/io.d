/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.elements.io;
import common.io.reader;
import ir.elements.assembly;
import std.traits;
import std.bitmanip;

/**
    A Cu reader which keeps the assembly in scope.
*/
class CuScopedReader : StreamReader {
public:
    CuAssembly assembly;

    this(CuAssembly assembly, Stream stream) {
        super(stream, Endian.littleEndian);
        this.assembly = assembly;
    }

    /**
        Read data from stream
    */
    void read(T)(ref T value) if ((isNumeric!T || isSomeChar!T) && isMutable!T) {
        ubyte[T.sizeof] buff;

        // TODO: Better error reporting
        this.tryRead(buff);

        switch(endianess) {
            case Endian.littleEndian:
                value = littleEndianToNative!T(buff);
                break;
            case Endian.bigEndian:
                value = bigEndianToNative!T(buff);
                break;
            default: assert(0);
        }
    }

    /**
        Read data from stream
    */
    void read(T)(ref T[] value) if (isBasicType!T) {
        uint length;
        this.read(length);
        value.length = length;

        if (endianess == endian) {
            
            // Fast path for basic types, pretends that the T[] array is a ubyte[] array
            // and just slaps the data in directly.
            this.tryReadEmplace(value, length*T.sizeof);
        } else {

            // Slow path with endianness conversion
            foreach(i; 0..length) {
                this.read(value[i]);
            }
        }
    }

    /**
        Read data from stream
    */
    override
    void read(ref string value) {
        super.read(value);
    }

    /**
        Read data from stream
    */
    override
    void read(ref wstring value) {
        super.read(value);
    }

    /**
        Read data from stream
    */
    override
    void read(ref dstring value) {
        super.read(value);
    }

    /**
        Read data from stream
    */
    override
    void read(ref bool value) {
        super.read(value);
    }

    /**
        Read data from stream
    */
    void read(T)(ref T[] value) if (StreamDeserializable!(T, CuScopedReader)) {
        uint length;
        this.read(length);
        value.length = length;

        foreach(i; 0..length) {
            static if(is(T == class)) value[i] = new T();
            this.read(value[i]);
        }
    }

    /**
        Read data from stream
    */
    void read(T)(ref T value) if (StreamSelectable!(T, CuScopedReader) || StreamDeserializable!(T, CuScopedReader)) {
        static if(StreamSelectable!(T, CuScopedReader)) {
            value = T.deserializeSelect(this);
        } else {
            static if(is(T == class)) value = new T();
            value.deserialize(this);
        }
    }
}