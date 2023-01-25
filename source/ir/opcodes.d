module ir.opcodes;
import ir.types;
import ir.value;
import std.uni : toLower;
import std.conv : text;
import ir.block;

enum CuIROpCode : ubyte {
    ADD,
    SUB,
    MUL,
    DIV,

    GEP,

    RET,
    CALL,
}

struct CuIRInstruction {
    /**
        The value (named type) returned from the instruction
    */
    CuIRValue* return_;

    /**
        The opcode of the instruction
    */
    CuIROpCode op;

    /**
        Operand Type
    */
    CuIRBaseType opType;

    /**
        Operands
    */
    CuIROperand[] operands;

    string toString() {
        string oString;
        if (return_) {
            oString ~= "%"~return_.getName()~" = ";
        }
        oString ~= op.text.toLower~" ";
        if (opType) oString ~= opType.toString() ~ " ";

        foreach(i, operand; operands) {
            
            switch(operand.type) {
                case CuIROperandType.Value:
                    oString ~= operand.value.getName() ? "%" ~ operand.value.getName() : operand.value.getValue();
                    break;
                case CuIROperandType.Reference:
                    oString ~= operand.ref_.getName();
                    break;
                default: assert(0);
            }

            if (i+1 < operands.length) oString ~= ", ";
        }
        return oString;
    }
}

enum CuIROperandType {
    Value,
    Reference
}

struct CuIROperand {
public:
    CuIROperandType type;
    union {
        CuIRValueRef value;
        CuIRBlockRef ref_;
    }

    this(CuIRValueRef value) {
        this.value = value;
        this.type = CuIROperandType.Value;
    }

    this(CuIRBlockRef ref_) {
        this.ref_ = ref_;
        this.type = CuIROperandType.Reference;
    }
}