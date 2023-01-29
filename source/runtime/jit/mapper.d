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