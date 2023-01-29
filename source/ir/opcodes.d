/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.opcodes;
import std.uni : toLower;
import std.conv : text;
import ir.element;
import ir.block;
import ir.value;
import ir.types.type;
import ir.io;
import ir.assembly;
import std.file;

enum CuOpCode : ubyte {
    ADD     = 0x01,
    SUB     = 0x02,
    MUL     = 0x03,
    DIV     = 0x04,

    GEP     = 0x10,

    RET     = 0x20,
    CALL    = 0x21,

    JMP     = 0x50,
}

struct CuIRInstruction {
    /**
        Return value
    */
    CuValue value;

    /**
        The opcode of the instruction
    */
    CuOpCode op;

    /**
        Operand Type
    */
    CuType opType;

    /**
        Operands
    */
    CuIROperand[] operands;
    
    /**
        Serialize the element to the specified buffer
    */
    void serialize(StreamWriter buffer) {
        buffer.write(cast(bool)(value !is null));
        if (value) {
            buffer.write(value);
        }

        buffer.write(op);
        buffer.write(opType);
        buffer.write(operands);
    }

    /**
        Deserialize the element from the specified buffer
    */
    void deserialize(CuScopedReader buffer) {
        bool hasReturnValue;
        buffer.read(hasReturnValue);
        
        if (hasReturnValue) {
            buffer.read(value);
        }

        buffer.read(op);
        buffer.read(opType);
        buffer.read(operands);
    }

    /**
        Resolve any extra information
    */
    void resolve(CuBasicBlock block) {
        foreach(ref operand; operands) {
            operand.resolve(block);
        }
    }

    string disassemble() {
        string oString;
        if (value) {
            oString ~= "%"~value.getName()~" = ";
        }
        oString ~= op.text.toLower~" ";
        if (opType) oString ~= opType.getStringPretty() ~ " ";

        foreach(i, operand; operands) {
            
            switch(operand.type) {
                case CuIROperandType.Value:
                    oString ~= operand.value.getName() ? "%" ~ operand.value.getName() : operand.value.getStringPretty();
                    break;
                case CuIROperandType.Reference:
                    oString ~= operand.blockRef.getName();
                    break;
                default: assert(0);
            }

            if (i+1 < operands.length) oString ~= ", ";
        }
        return oString;
    }
}

enum CuIROperandType : ubyte {
    Value = 0x01,
    Reference = 0x02
}

struct CuIROperand {
private:
    CuAssembly assembly;
    string nameToResolve;

public:
    CuIROperandType type;
    union {
        CuValue value;
        CuBasicBlock blockRef;
    }

    this(CuValue value) {
        this.value = value;
        this.type = CuIROperandType.Value;
    }

    this(CuBasicBlock blockRef) {
        this.blockRef = blockRef;
        this.type = CuIROperandType.Reference;
    }

    /**
        Serialize the element to the specified buffer
    */
    void serialize(StreamWriter buffer) {
        buffer.write(cast(ubyte)type);
        switch(type) {
            case CuIROperandType.Value:
                if (value.isImmediate()) {
                    buffer.write(true);
                    buffer.write(value);
                } else {
                    buffer.write(false);
                    buffer.write(value.getName());
                }
                break;
            case CuIROperandType.Reference:
                buffer.write(blockRef.getName());
                break;
            default: assert(0);
        }
    }

    /**
        Deserialize the element from the specified buffer
    */
    void deserialize(CuScopedReader buffer) {
        this.assembly = buffer.assembly;
        buffer.read(type);

        switch(type) {
            case CuIROperandType.Value:
                bool isImmediate;
                buffer.read(isImmediate);

                if (isImmediate) {
                    buffer.read(value);
                } else {
                    buffer.read(nameToResolve);
                }
                break;
            case CuIROperandType.Reference:
                buffer.read(nameToResolve);
                break;
            default: assert(0);
        }
    }

    /**
        Resolve any extra information
    */
    void resolve(CuBasicBlock block) {
        switch(type) {
            case CuIROperandType.Value:

                // Not immediate if null
                if (!value) {
                    value = block.findValueInBlock(nameToResolve);
                }
                break;
            case CuIROperandType.Reference:
                blockRef = block.getParent().getBlock(nameToResolve);
                break;
            default: assert(0);
        }
    }
}