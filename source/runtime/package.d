/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module runtime;

import ir.assembly;

abstract class CuRuntime {
public:
    /**
        Loads an assembly in to the current runtime
    */
    abstract void loadAssembly(CuAssembly assembly);

    /**
        Gets a function within the assembly
    */
    abstract void* getFunc(string name);

    /**
        Runs the first loaded assembly with a main function.
    */
    abstract int run(string[] args);

    /**
        Returns a list of loaded assemblies
    */
    abstract CuAssembly[] getLoadedAssemblies();

    /**
        Gets whether JIT compilation is supported
    */
    abstract bool isJIT();
}