/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module ir.element;

public import common.io.reader;
public import common.io.writer;
import ir.io;

abstract
class CuElement {
public:
    /**
        Serialize the element to the specified buffer
    */
    abstract void serialize(StreamWriter writer);

    /**
        Deserialize the element from the specified buffer
    */
    abstract void deserialize(CuScopedReader reader);

    /**
        Resolve any extra information
    */
    abstract void resolve();

    /**
        Optional pretty printer function
    */
    string getStringPretty() { return ""; }
}