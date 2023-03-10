/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.types.ptr;
import ir.types.type;
import ir.io;
import common.io;

class CuPointer : CuType {
private:
    this(CuType pointerTo) {
        super(CuTypeId.array_);
        this.pointerTo = pointerTo;
    }

package(ir):
    this() { super(); }

public:
    /**
        The type of the array
    */
    CuType pointerTo;

    override
    void serialize(StreamWriter buffer) {
        super.serialize(buffer);
        buffer.write(pointerTo);
    }

    override
    void deserialize(CuScopedReader buffer) {
        super.deserialize(buffer);
        buffer.read(pointerTo);
    }
}

/**
    Creates an array with the specified type
*/
CuPointer cuirCreatePointerTo(CuType type) { return new CuPointer(type); }
