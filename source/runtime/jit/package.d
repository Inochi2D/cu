module runtime.jit;
import runtime;
import ir.assembly;

import llvm.functions.load;
import llvm.types : LLVMContextRef;
import runtime.jit.compiler;
import llvm;

enum CuJITOptions : uint {
    none = 0,
    aotCompile = 0b00000000_00000000_00000000_00000001,
}

/**
    A JIT compiler runtime for Cu
*/
class CuJITRuntime : CuRuntime {
private:
    LLVMContextRef ctx;
    CuJITCompiler compiler;
    CuAssembly[] loaded;
    CuJITOptions options;

public:
    this(CuJITOptions options = CuJITOptions.none) {
        LLVM.load();
        this.ctx = LLVMContextCreate();
        this.compiler = new CuJITCompiler();
        this.options = options;
    }

    /**
        Loads an assembly in to the current runtime
    */
    override
    void loadAssembly(CuAssembly assembly) {
        loaded ~= assembly;
    }

    /**
        Gets a function within the assembly
    */
    override
    void* getFunc(string name) {
        return null;
    }   

    /**
        Runs the first loaded assembly with a main function.
    */
    override
    int run(string[] args) {
        return 0;
    }

    /**
        Returns a list of loaded assemblies
    */
    override
    CuAssembly[] getLoadedAssemblies() {
        return loaded;
    }

    /**
        Gets whether JIT compilation is supported
    */
    override
    bool isJIT() { return true; }

    /**
        Gets the underlying LLVM context for the runtime
    */
    LLVMContextRef getLLVMContext() {
        return ctx;
    }
}