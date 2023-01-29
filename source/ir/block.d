/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.block;
import ir.element;
import ir.func;
import ir.io;
import ir.value;
import ir.opcodes;
import std.format;

class CuBasicBlock : CuElement {
private:
    string name;
    CuFunc parent;

package(ir):
    this() { }

    void setParent(CuFunc parent) {
        this.parent = parent;
    }

    this(CuFunc parent, string name) {
        this.parent = parent;
        this.name = name;
    }

public:
    CuIRInstruction[] instructions;

    string getName() {
        return name;
    }

    CuFunc getParent() {
        return parent;
    }
    
    /**
        Serialize the element to the specified buffer
    */
    override
    void serialize(StreamWriter buffer) {
        buffer.write(name);
        buffer.write(instructions);
    }

    /**
        Deserialize the element from the specified buffer
    */
    override
    void deserialize(CuScopedReader buffer) {
        buffer.read(name);
        buffer.read(instructions);
    }

    /**
        Resolve any extra information
    */
    override
    void resolve() {
        foreach(instruction; instructions) {
            instruction.resolve(this);
        }
    }

    /**
        Optional pretty printer function
    */
    override
    string getStringPretty() { 
        import compiler.common.utils : offsetByLines;
        return "%s:\n%s".format(name, offsetByLines(getInstructionAsm(), 2));
    }

    string getInstructionAsm() {
        string oString = "";
        foreach(instr; instructions) {
            oString ~= instr.disassemble()~"\n";
        }
        return oString;
    }

    CuValue findValueInBlock(string name) {
        foreach(ref instruction; instructions) {
            if (instruction.value && instruction.value.getName() == name) return instruction.value;
        }
        return null;
    }
}

// alias CuIRBlockRef = CuIRBlock*;