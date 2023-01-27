/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.elements.types.array;
import ir.elements.types.type;
import common.io;
import ir.elements.io;

class CuArray : CuType {
private:
    this(CuType elmType) {
        super(CuTypeId.array_);
    }

package(ir):
    this() { super(); }

public:
    /**
        The type of the array
    */
    CuType elementType;

    override
    void serialize(StreamWriter buffer) {
        super.serialize(buffer);
        elementType.serialize(buffer);
    }

    override
    void deserialize(CuScopedReader buffer) {
        super.deserialize(buffer);
        elementType.deserialize(buffer);
    }
}

/**
    Creates an array with the specified type
*/
CuArray cuirCreateArrayOf(CuType type) { return new CuArray(type); }

class CuStaticArray : CuArray {
private:
    this(CuType elementType) {
        super(elementType);
    }

package(ir):
    this() { super(); }

public:
    /**
        The length of the static array
    */
    size_t length;

    /**
        Gets size of static array in bytes
    */
    override
    size_t getSizeOf() {
        return length*elementType.getSizeOf();
    }
}