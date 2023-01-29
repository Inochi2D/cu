/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module runtime.jit.compiler;
import runtime.jit;
import llvm;
import std.string : fromStringz, toStringz;
import std.exception : enforce;
import ir.assembly;
import std.format;
import runtime.jit.mapper;

class CuJITCompiler {
private:
    struct CuAssemblyMapping {
        CuAssembly assembly;
        LLVMModuleRef module_;

        string toString() {
            return assembly.info.name~" v. "~assembly.info.version_.toString();
        }
    }

    CuJITTypeMapper mapper;
    CuJITRuntime runtime;
    LLVMExecutionEngineRef engine;
    CuAssemblyMapping[string] loadedModules;

public:
    this(CuJITRuntime runtime) {
        this.runtime = runtime;
        this.mapper = new CuJITTypeMapper();
        char* error;

        auto mod = LLVMModuleCreateWithName("a");
        enforce(!LLVMCreateExecutionEngineForModule(&engine, mod, &error), error.fromStringz);
        enforce(!LLVMRemoveModule(engine, mod, &mod, &error), error.fromStringz);
        LLVMDisposeModule(mod);
    }

    /**
        Load assembly in to JIT compiler
    */
    void load(CuAssembly assembly) {
        CuAssemblyMapping mapping;
        mapping.assembly = assembly;
        mapping.module_ = LLVMModuleCreateWithNameInContext(assembly.info.name.toStringz, runtime.getLLVMContext());
        loadedModules[assembly.info.name] = mapping;
        
        LLVMAddModule(engine, mapping.module_);
    }

    /**
        Unloads an assembly from the JIT
    */
    void unload(CuAssembly assembly) {
        LLVMModuleRef mod;
        enforce(!LLVMRemoveModule(engine, loadedModules[assembly.info.name].module_, &mod, &error), error.fromStringz);
        LLVMDisposeModule(mod);
    }

    /**
        Returns a reference to the underlying execution engine
    */
    LLVMExecutionEngineRef getEngine() {
        return engine;
    }
}