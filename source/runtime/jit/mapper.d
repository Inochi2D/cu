/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module runtime.jit.mapper;
import llvm;
import ir.types.type;

/**
    System which maps Cu types to LLVM IR types
*/
class CuJITTypeMapper {
private:
    LLVMTypeRef[CuScopedType] mappings;

public:

}