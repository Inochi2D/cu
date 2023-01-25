module ir.builder;
import ir.block;
import ir.types;
import ir.opcodes;
import ir.value;

import std.conv : text;

class CuIRBuilder {
private:
    CuIRBlockRef block;
    size_t bCounter;

    CuIRValueRef consumeValue(CuIRValueRef t) {
        if (t) {
            t.setName(t.getName()~(bCounter++).text);
            bCounter++;
        }
        return t;
    }
public:
    this(CuIRBlock* block) {
        this.block = block;
    }

    /**
        Returns the block
    */
    CuIRBlockRef getBlock() {
        return block;
    }

    CuIRValueRef buildAdd(CuIRValueRef a, CuIRValueRef b) { 
        CuIRValueRef retVal = new CuIRValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.ADD, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuIRValueRef buildMul(CuIRValueRef a, CuIRValueRef b) { 
        CuIRValueRef retVal = new CuIRValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.MUL, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuIRValueRef buildSub(CuIRValueRef a, CuIRValueRef b) { 
        CuIRValueRef retVal = new CuIRValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.SUB, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuIRValueRef buildDiv(CuIRValueRef a, CuIRValueRef b) { 
        CuIRValueRef retVal = new CuIRValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.DIV, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuIRValueRef buildRet(CuIRValueRef a) { 
        CuIRValueRef retVal = new CuIRValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.RET, 
            a.getType(), 
            [
                CuIROperand(a)
            ]
        );
        return retVal;
    }

    CuIRValueRef buildRet() { 
        CuIRValueRef retVal = new CuIRValue(cuirTypeCreateVoid());

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuIROpCode.RET, 
            cuirTypeCreateVoid(), 
            []
        );
        return retVal;
    }

    override
    string toString() {
        return block.getName() ~ ":\n" ~ block.toString();
    }
}