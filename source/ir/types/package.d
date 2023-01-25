module ir.types;

public import ir.types.basetype;
public import ir.types.classes;
public import ir.types.delegates;
public import ir.types.funcs;
public import ir.types.interfaces;
public import ir.types.structs;









//
//                      UNIT TESTS
//

@("IR Base Type")
unittest {
    assert(cuirCreateVoid().toString() == "void");
    assert(cuirCreateI8().toString() == "i8");
    assert(cuirCreateI16().toString() == "i16");
    assert(cuirCreateI32().toString() == "i32");
    assert(cuirCreateI64().toString() == "i64");
}

@("IR Pointer Types")
unittest {
    assert(cuirPointerTo(cuirCreateI64()).toString(), "i64*");
    assert(cuirPointerTo(cuirPointerTo(cuirCreateI64())).toString(), "i64**");
}

@("IR Compound Types")
unittest {
    auto struct_ = cuirCreateStruct(
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    CuIRInterfaceType iface = cast(CuIRInterfaceType)cuirCreateInterface([
        cuirCreateFunc(cuirCreateVoid()).setName("myFunc")
    ]).setName("MyInterface");

    CuIRClassType baseClass = cast(CuIRClassType)cuirCreateClass(
        [
            cuirCreateF16(),
            cuirCreateFunc(cuirCreateF32(), [cuirCreateF32(), cuirCreateF32()]).setName("atan2")
        ]
    ).setName("BaseClass").setAttributes(TypeAttribute.abstract_ | TypeAttribute.public_);

    CuIRClassType subClass = cast(CuIRClassType)cuirCreateClass(
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(struct_)
        ],
        baseClass,
        [iface]
    ).setName("SubClass").setAttributes(TypeAttribute.public_);

    assert(struct_.toString() == "struct (f16, i8)");
    assert(baseClass.toString() == "[public]class BaseClass(f16, function f32 atan2(f32, f32))");
    assert(iface.toString() == "interface MyInterface(function void myFunc())");
    assert(subClass.toString() == "[public]class:(class BaseClass,interface MyInterface) SubClass(f16, i8, struct (f16, i8)*)");
}

@("IR Functions & Delegates")
unittest {
    auto typ1 = cuirCreateDelegate(
        cuirCreateVoid(),
        [
            cuirCreateF16(), 
            cuirCreateI8()
        ]
    );

    typ1.name = "uwu";

    auto typ2 = cuirCreateFunc(
        cuirCreateI32(),
        [
            cuirCreateF16(), 
            cuirCreateI8(),
            cuirPointerTo(typ1)
        ]
    );

    assert(typ1.toString() == "delegate void uwu(f16, i8)");
    assert(typ2.toString() == "function i32 (f16, i8, delegate void uwu(f16, i8)*)");
}