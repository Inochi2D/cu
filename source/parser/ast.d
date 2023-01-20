module parser.ast;
import parser.token;
import parser.utils;
import std.conv;
import std.format;
import std.stdio;

alias ASTAttribute = ubyte;

/// Anything that isn't a seperate id.
enum ASTAttribute astX = 0;

/// The scope of a class
enum ASTAttribute astClass = 1;

/// The scope of a struct
enum ASTAttribute astStruct = 2;

/// The scope of a function
enum ASTAttribute astFunction = 3;

/// The scope of a metafunction
enum ASTAttribute astMetaFunction = 4;

/// The body of a scope
enum ASTAttribute astBody = 5;

/// A Statement
enum ASTAttribute astStatement = 10;

/// A Declaration
enum ASTAttribute astDeclaration = 11;

/// An assignment
enum ASTAttribute astAssignment = 12;

/// Comparison
enum ASTAttribute astComparison = 13;

/// A branch. (if, else if, else)
enum ASTAttribute astBranch = 20;

/// A while loop.
enum ASTAttribute astWhile = 21;

/// A for loop.
enum ASTAttribute astFor = 22;

/// A foreach loop
enum ASTAttribute astForeach = 23;

/// A unit test
enum ASTAttribute astUnit = 24;

/// Returning a value
enum ASTAttribute astReturn = 25;

/// A call to a function
enum ASTAttribute astFunctionCall = 26;

/// An expression
enum ASTAttribute astExpression = 30;

/// A list of parameters
enum ASTAttribute astParameterList = 31;

/// A list of parameter values
enum ASTAttribute astParameters = 32;

/// Return type of a function.
enum ASTAttribute astReturnType = 33;

/// An identifier
enum ASTAttribute astIdentifier = 40;

/// Extends
enum ASTAttribute astExtends = 100;

/// Attribute
enum ASTAttribute astAttributeList = 200;

/// Heap Constructor
enum ASTAttribute astHeapConstruct = 252;

/// Stack Constructor
enum ASTAttribute astStackConstruct = 253;

/// Constructor Declaration
enum ASTAttribute astConstructor = 254;

/// Module
enum ASTAttribute astModule = 255;

string getString(ASTAttribute id) {
    switch(id) {
        case (astClass):
            return "<class>";
        case (astStruct):
            return "<struct>";
        case (astFunction):
            return "<func>";
        case (astMetaFunction):
            return "<meta>";
        case (astBody):
            return "<body>";
        case (astStatement):
            return "<stmt>";
        case (astDeclaration):
            return "<decl>";
        case (astAssignment):
            return "<assign>";
        case (astComparison):
            return "<comp>";
        case (astBranch):
            return "<branch>";
        case (astWhile):
            return "<while>";
        case (astFor):
            return "<for>";
        case (astForeach):
            return "<foreach>";
        case (astUnit):
            return "<unit>";
        case (astReturn):
            return "<return>";
        case (astFunctionCall):
            return "<func call>";
        case (astExpression):
            return "<expr>";
        case (astParameterList):
            return "<paramdef list>";
        case (astParameters):
            return "<params>";
        case (astIdentifier):
            return "<iden>";
        case (astExtends):
            return "<extends>";
        case (astAttributeList):
            return "<attrib list>";
        case (astModule):
            return "<module>";
        case (astStackConstruct):
            return "<stack constructor>";
        case (astHeapConstruct):
            return "<heap constructor>";
        case (astConstructor):
            return "<constructor>";

        // Just so I don't miss it.
        case (astX):
        default:
            return null;
    }
}


/// A node in the Abstract Syntax Tree
struct Node {
private:
    size_t children;

public:

    /// Constructor
    this(Token token, ASTAttribute attrib = astX) {
        this.token = token;
        this.name = token.lexeme;
        this(attrib);
    }


    /// Constructor
    this(ASTAttribute attrib) {
        this.attrib = attrib;
    }

    /// At node to children at start
    void addStart(Node* node) {
        if (node is null) return;
        if (firstChild is null && lastChild is null) {
            lastChild = node;
        }

        if (firstChild !is null) {
            firstChild.left = node;
            node.right = firstChild;
        }
        firstChild = node;

        node.parent = &this;
        children++;
    }

    /// Add node to children at end
    void add(Node* node) {
        if (node is null) return;
        if (firstChild is null) {
            firstChild = node;
        }

        if (lastChild !is null) {
            lastChild.right = node;
            node.left = lastChild;
        }
        lastChild = node;

        node.parent = &this;
        children++;
    }

    /// Count of children this node is parent to.
    size_t childrenCount() {
        return children;
    }

    /// AST Attribute
    ASTAttribute attrib;

    /// The token associated with this node
    Token token;

    /// The first child the node is parent to
    Node* firstChild;

    /// The last child the node is parent to
    Node* lastChild;

    /// The node to the left of this node
    Node* left;

    /// The node to the right of this node
    Node* right;

    /// Parent to this node
    Node* parent;

    /// Temporary debug lexeme
    string name;

    string toString(size_t indent = 0) {
        string rgt = right !is null ? right.toString(indent) : "";
        string chd = children > 0 ? " "~firstChild.toString(indent+1) : "";

        /// TODO: This ugly code needs some serious rewriting.
        string txt = token.lexeme != "" ? token.lexeme : "";
        string typ = token.id != tkUnknown ? token.id.text : "<arb>";
        string attribstr = attrib.getString() !is null ? attrib.getString()~" " : "";

        string offs = (chd.length > 0 ? "\n" ~ "".offsetBy(indent*2) : "");
        string offsrc = (right !is null ? "," : "");
        string offsr = offsrc ~ (right !is null ? "".offsetBy(indent*2) : "");

        return ("\n%s(%s%s%s%s)%s%s").format("".offsetBy(indent*2), attribstr, txt, chd, offs, offsr, rgt);
    }
}
