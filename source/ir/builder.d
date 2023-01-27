module ir.builder;
import ir.elements.block;
import ir.elements.types.type;
import ir.elements.value;
import ir.opcodes;

import std.conv : text;

class CuIRBuilder {
private:
    CuBasicBlock block;
    size_t bCounter;

    CuValue consumeValue(CuValue t) {
        if (t) {
            t.setName(t.getName()~(bCounter++).text);
        }
        return t;
    }
public:
    this(CuBasicBlock block) {
        this.block = block;
    }

    /**
        Returns the block
    */
    CuBasicBlock getBlock() {
        return block;
    }

    CuValue buildAdd(CuValue a, CuValue b) { 
        CuValue retVal = new CuValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.ADD, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuValue buildMul(CuValue a, CuValue b) { 
        CuValue retVal = new CuValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.MUL, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuValue buildSub(CuValue a, CuValue b) { 
        CuValue retVal = new CuValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.SUB, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuValue buildDiv(CuValue a, CuValue b) { 
        CuValue retVal = new CuValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.DIV, 
            a.getType(), 
            [
                CuIROperand(a),
                CuIROperand(b),
            ]
        );
        return retVal;
    }

    CuValue buildRet(CuValue a) { 
        CuValue retVal = new CuValue(a.getType());
        consumeValue(retVal);

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.RET, 
            a.getType(), 
            [
                CuIROperand(a)
            ]
        );
        return retVal;
    }

    CuValue buildRet() { 
        CuValue retVal = new CuValue(cuirCreateVoid());

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.RET, 
            cuirCreateVoid(), 
            []
        );
        return retVal;
    }

    CuValue buildJump(CuBasicBlock newblock) { 
        CuValue retVal = new CuValue(cuirCreateVoid());

        block.instructions ~= CuIRInstruction(
            retVal, 
            CuOpCode.JMP, 
            cuirCreateVoid(), 
            [
                CuIROperand(newblock)
            ]
        );
        return retVal;
    }

    override
    string toString() {
        return block.getName() ~ ":\n" ~ block.toString();
    }
}