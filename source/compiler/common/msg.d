module compiler.common.msg;
import compiler.common.utils;
import compiler.parser.token;
import compiler.parser.ast;
import std.conv;

enum MessageSeverity {
    Warning,
    Error,
    Deprecation
}

struct StrArea {
public:
    size_t start;
    size_t end;
    bool large;
    bool endCovered;



    static StrArea getAppropriateStringArea(string source, Token tk) {
        // Get line start
        immutable(size_t) start = source.getCharOfLine(tk.line);
        immutable(size_t) length = source.getLengthOfLine(start);

        size_t areaStart = start;
        size_t areaEnd = start+length;

        if (length > 80) {
            bool atEnd = false;
            areaStart = tk.start-40;
            areaEnd = tk.start+80;

            // Force to be on the right line
            if (areaStart <= start) areaStart = start;


            if (areaEnd >= start+length) { 
                areaEnd = start+length;
                atEnd = true;
            }
            return StrArea(areaStart, areaEnd, true, atEnd);
        }
        return StrArea(areaStart, areaEnd, false, true);
    }
}

/**
    A copper compiler message
*/
class CompileMessage {
public:
    /**
        Severity of message
    */
    MessageSeverity severity;

    /**
        The message
    */
    string msg;

    /**
        The token of the message occurance
    */
    Token* token;

    /**
        The source code
    */
    string source;

    /**
        File the message occured
    */
    string file;

    /**
        Line the message occured.
    */
    size_t line;

    /**
        The message
    */
    string prettyMsg() {
        return cuPrettyPrintLineMessage(source, *token, msg);
    }

    /**
        Constructs new exception
    */
    this(string source, MessageSeverity severity, Token* tk, string msg, string file = __FILE__, size_t line = __LINE__)
    {
        this.token = tk;
        this.source = source;
        this.msg = msg;
        this.file = file;
        this.line = line;
    }

    /**
        Constructs new exception
    */
    this(Node* n, MessageSeverity severity, string msg, string file = __FILE__, size_t line = __LINE__)
    {
        this(n.token.source, severity, &n.token, msg, file, line);
    }
}

/**
    Creates an error message
*/
CompileMessage cuCreateError(Node* n, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(n, MessageSeverity.Error, msg, file, line);
}

/**
    Creates an error message
*/
CompileMessage cuCreateError(string src, Token* tk, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(src, MessageSeverity.Error, tk, msg, file, line);
}

/**
    Creates a warning message
*/
CompileMessage cuCreateWarning(Node* n, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(n, MessageSeverity.Warning, msg, file, line);
}

/**
    Creates a warning message
*/
CompileMessage cuCreateWarning(string src, Token* tk, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(src, MessageSeverity.Warning, tk, msg, file, line);
}

/**
    Creates a deprecation message
*/
CompileMessage cuCreateDeprecation(Node* n, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(n, MessageSeverity.Deprecation, msg, file, line);
}

/**
    Creates a deprecation message
*/
CompileMessage cuCreateDeprecation(string src, Token* tk, string msg, string file = __FILE__, size_t line = __LINE__) {
    return new CompileMessage(src, MessageSeverity.Deprecation, tk, msg, file, line);
}

/**
    Helper function that pretty prints line messages
*/
string cuPrettyPrintLineMessage(string source, Token tk, string msg) {
    StrArea area = StrArea.getAppropriateStringArea(source, tk);
    size_t tokenOffset = tk.start-area.start;

    // Generate cursor:
    string prefix = tk.line.text ~ ": " ~ (area.large ? "..." : "");

    string cursor = "^".offsetBy(prefix.length+tokenOffset);
    string err = tk.pos.text.offsetBy(prefix.length+tokenOffset) ~ ": " ~ msg;

    string sep = "=".repeat(64);

    return sep ~ "\n" ~ prefix ~ source[area.start..area.end] ~ (!area.endCovered ? "..." : "") ~ "\n" ~ cursor ~ "\n" ~ err;
}