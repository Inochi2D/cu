module ir.elements.types.ptr;
import ir.elements.types.type;
import ir.elements.io;
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
