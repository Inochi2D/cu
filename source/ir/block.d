module ir.block;
import ir.types.funcs;
import ir.types.delegates;
import ir.opcodes;

struct CuIRBlock {
private:
    string name;
    bool isFunc;
    union {
        CuIRFuncType func;
        CuIRDelegateType dg;
    }

public:
    CuIRInstruction[] instructions;

    this(string name, CuIRFuncType func) {
        this.name = name;
        this.isFunc = true;
        this.func = func;
    }

    this(string name, CuIRDelegateType dg) {
        this.name = name;
        this.isFunc = false;
        this.dg = dg;
    }

    string getName() {
        return name;
    }

    string toString() {
        string oString = "";
        foreach(instr; instructions) {
            oString ~= "\t"~instr.toString()~"\n";
        }
        return oString;
    }
}

alias CuIRBlockRef = CuIRBlock*;