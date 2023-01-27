/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module compiler.common.utils;
import std.conv;
import std.string;

string offsetBy(string text, size_t offset) {
    string offsetStr = "";
    foreach(i; 0..offset) offsetStr ~= " ";
    return offsetStr ~ text;
}

string repeat(string text, size_t times) {
    string output = "";
    foreach(i; 0..times) {
        output ~= text;
    }
    return output;
}

string offsetByLines(string text, size_t offset) {
    import std.string : splitLines;
    string outLines;
    string[] lines = splitLines(text);
    foreach(line; lines) {
        outLines ~= line.offsetBy(offset) ~ "\n";
    }
    return outLines;
}

string escape(char c) {
    switch(c) {
        case('\n'):
            return "<newline>";
        default:
            return ""~c;
    }
}

size_t getCharOfLine(string source, size_t line) {
    size_t linechar = 0;
    size_t lines = 0;
    while (lines < line) {
        if (source[linechar] == '\n') lines++;
        linechar++;
    }
    return linechar;
}

size_t getLengthOfLine(string source, size_t start) {
    size_t chars = 0;
    size_t i = start;
    while (i < source.length && source[i] != '\n') { chars++; i++; }
    return chars;
}