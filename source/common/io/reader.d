/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module common.io.reader;
import common.io.stream;
import std.traits;
import std.bitmanip;
import std.exception : enforce;

public import std.system : Endian, endian;

/**
    Compiletime enum which determines whether a class or struct type can be deserialized

    StreamDeserializable!T is true at compile time if:
        1. `T` has a member called `deserialize`
        2. `deserialize` can be called like a function
        3. `deserialize` has exactly 1 parameter
        4. The type of that parameter can be cast to `StreamReader`
        5. The return type is `void`
*/
enum StreamDeserializable(T, StreamReaderT = StreamReader) = 
    __traits(hasMember, T, "deserialize") && 
    isCallable!(T.deserialize) &&
    Parameters!(T.deserialize).length == 1 && 
    is(Parameters!(T.deserialize)[0] == StreamReaderT) &&
    is(ReturnType!(T.deserialize) == void);

/**
    Compiletime enum which determines whether a class or struct type can be selected
    This is for when you need to determine which subclass to parse as.

    StreamDeserializable!T is true at compile time if:
        1. `T` has a static member called `deserializeSelect`
        2. `deserialize` can be called like a function
        3. `deserialize` has exactly 1 parameter
        4. The type of that parameter can be cast to `StreamReader`
        5. The return type is `T`
*/
enum StreamSelectable(T, StreamReaderT = StreamReader) = 
    hasStaticMember!(T, "deserializeSelect") && 
    isCallable!(T.deserializeSelect) &&
    Parameters!(T.deserializeSelect).length == 1 && 
    is(Parameters!(T.deserializeSelect)[0] == StreamReaderT) &&
    is(ReturnType!(T.deserializeSelect) == T);

class StreamReader {
protected:
    Stream backingStream;
    Endian endianess;

    void tryRead(ubyte[] buf) {
        enforce(backingStream.read(buf) == buf.length, "Stream ended prematurely");
    }

    void tryReadEmplace(T)(T[] buf, size_t bytes) {
        ubyte[] b = (cast(ubyte[])buf)[0..bytes];
        enforce(backingStream.read(b) == bytes, "Stream ended prematurely");
    }
public:
    this(Stream stream, Endian endianess = Endian.littleEndian) {
        this.backingStream = stream;
        this.endianess = endianess;
    }

    /**
        Read data from stream
    */
    void read(T)(ref T value) if (isNumeric!T) {
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
    void read(ref string value) {
        uint length;
        this.read!uint(length);
        
        // Skip empty strings
        if (length == 0) return;

        value.length = length;
        this.tryRead(cast(ubyte[])value);
    }

    /**
        Read data from stream
    */
    void read(ref wstring value) {
        uint length;
        this.read!uint(length);
        
        // Skip empty strings
        if (length == 0) return;
        
        value.length = length;
        foreach(c; 0..value.length) {
            ushort v;
            this.read(v);
            (cast(ushort*)value.ptr)[c] = cast(wchar)v;
        }
    }


    /**
        Read data from stream
    */
    void read(ref dstring value) {
        uint length;
        this.read!uint(length);
        
        // Skip empty strings
        if (length == 0) return;
        
        value.length = length;
        foreach(c; 0..value.length) {
            uint v;
            this.read(v);
            (cast(uint*)value.ptr)[c] = cast(dchar)v;
        }
    }

    /**
        Read data from stream
    */
    void read(ref bool value) {
        ubyte[1] buff;
        this.tryRead(buff);
        value = cast(bool)buff[0];
    }


    /**
        Read data from stream
    */
    void read(T)(ref T[] value) if (isBasicType!T) {
        uint length;
        this.read(length);
        value.length = length;
        
        // Skip empty arrays
        if (length == 0) return;

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
    void read(T)(ref T[] value) if (StreamDeserializable!T) {
        uint length;
        this.read(length);
        value.length = length;

        foreach(i; 0..length) {
            this.read(value[i]);
        }
    }

    /**
        Read data from stream
    */
    void read(T)(ref T value) if (StreamSelectable!T) {
        value = T.deserializeSelect(this);
    }

    /**
        Read data from stream
    */
    void read(T)(ref T value) if (StreamDeserializable!T) {
        value.deserialize(this);
    }

    /**
        Peek at upcoming value
    */
    void peek(T)(ref T value) {
        auto pos = backingStream.tell();
        this.read(value);
        backingStream.seek(pos);
    }

    /**
        Skip specified amount of bytes
    */
    void skip(size_t length) {
        backingStream.seek(length, SeekPosition.relative);
    }

    /**
        Read data from stream
    */
    T[] rawRead(T)(size_t length) if (isBasicType!T) {
        ubyte[] data = new ubyte[](length);
        this.tryRead(data);
        return cast(T[])(cast(void[])data);
    }

    /**
        Read data from stream
    */
    T rawRead(T)(size_t length) if(is(T == string)) {
        ubyte[] data = new ubyte[](length);
        this.tryRead(data);
        return cast(T)data;
    }

    ref Stream getStream() {
        return backingStream;
    }
}