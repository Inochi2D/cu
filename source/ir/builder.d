/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.builder;
import ir.block;
import ir.types.type;
import ir.value;
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

    void buildRet() {
        block.instructions ~= CuIRInstruction(
            null, 
            CuOpCode.RET, 
            cuirCreateVoid(), 
            []
        );
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