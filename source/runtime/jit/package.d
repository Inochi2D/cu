/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module runtime.jit;
import runtime;
import ir.assembly;

import llvm.functions.load;
import llvm.types : LLVMContextRef;
import runtime.jit.compiler;
import llvm;

import std.file;
import std.path;
import std.format;
import std.exception;

enum CuJITOptions : uint {
    none = 0,
    /**
        Compile entire assembly and its dependencies in one go
    */
    aotCompile      = 0b00000000_00000000_00000000_00000001,

    /**
        Disable using search paths to resolve dependencies
    */
    noFileSearch    = 0b00000001_00000000_00000000_00000000,
}

/**
    A JIT compiler runtime for Cu
*/
class CuJITRuntime : CuRuntime {
private:
    LLVMContextRef ctx;
    CuJITCompiler compiler;
    CuJITOptions options;

    // Assembly searching
    string[] searchPaths;
    CuAssembly function(string)[] resolvers;
    CuAssembly[string] loadedAssemblies;
    string getAssemblyStr(CuAssembly assembly) { return "%s v%s".format(assembly.info.name, assembly.info.version_); }
    string getAssemblyStr(CuAssemblyDependency assembly) { return "%s v%s".format(assembly.name, assembly.version_); }

    void solveDependencies(CuAssembly solveFor) {
        searchLoop: foreach(CuAssemblyDependency dependency; solveFor.info.dependencies) {
            if (dependency.name in loadedAssemblies) {

                // Throw an error if versions mismatch
                if (dependency.version_.toString() != loadedAssemblies[dependency.name].info.version_.toString()) {
                    throw new Exception(
                        "Mismatching versions for dependency of %0$s, %0$s wants %1$s, %2$s is already loaded".format(
                            solveFor.info.name,
                            getAssemblyStr(dependency),
                            getAssemblyStr(loadedAssemblies[dependency.name]),
                        )
                    );
                }

                // Otherwise continue on our merry day.
                // We already have the dependency
                continue searchLoop;
            }

            if ((options & CuJITOptions.noFileSearch) != CuJITOptions.noFileSearch) {
                
                // If search paths are enabled, search through those
                foreach(path; searchPaths) {
                    string targetPath = buildPath(path, dependency.name.setExtension("cua"));
                    if (exists(targetPath) && isFile(targetPath)) {
                        this.loadAssembly(CuAssembly.fromFile(targetPath));
                        continue searchLoop;
                    }
                }
            }

            // Finally try the user registered resolvers
            foreach(resolver; resolvers) {
                CuAssembly resolved = resolver(dependency.name);
                if (resolved) {
                    this.loadAssembly(resolved);
                    continue searchLoop;
                }
            }

            // Assembly not found
            throw new Exception(
                "Dependency %s was not found in search paths or providers.".format(
                    getAssemblyStr(dependency),
                )
            );
        }
    }

public:
    this(CuJITOptions options = CuJITOptions.none) {
        LLVM.load();
        this.ctx = LLVMContextCreate();
        this.compiler = new CuJITCompiler(this);
        this.options = options;

        // TODO: Better search path system
        this.searchPaths = [
            ".", 
            "lib/"
        ];
    }

    /**
        Add search path to dependency resolution
    */
    void addSearchPath(string path) {
        this.searchPaths ~= path;
    }

    /**
        Add user defined resolver to dependency resolution
    */
    void addResolver(CuAssembly function(string) resolver) {
        this.resolvers ~= resolver;
    }

    /**
        Loads an assembly in to the current runtime
    */
    override
    void loadAssembly(CuAssembly assembly) {
        enforce(assembly.info.name !in loadedAssemblies, "Assembly %s already loaded".format(getAssemblyStr(assembly)));
        loadedAssemblies[assembly.info.name] = assembly;
        this.solveDependencies(assembly);

        compiler.load(assembly);
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
        return loadedAssemblies.values;
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