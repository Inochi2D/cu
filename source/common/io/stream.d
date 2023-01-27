module common.io.stream;
import std.stdio : SEEK_CUR, SEEK_SET, SEEK_END, File;

enum SeekPosition {
    start = SEEK_SET,
    relative = SEEK_CUR,
    end = SEEK_END
}

/**
    A buffer
*/
abstract class Stream {
public:
    abstract bool hasLength();
    abstract size_t getLength();

    abstract bool canSeek();
    abstract void seek(ptrdiff_t pos, SeekPosition offset=SeekPosition.start);

    abstract bool canTell();
    abstract size_t tell();

    abstract bool canRead();
    abstract int read(ref ubyte[] buffer);

    abstract bool canWrite();
    abstract void write(ubyte[] buffer);
}

class MemoryStream : Stream {
private:
    ubyte[] backingStream;
    size_t cursor = 0;

public:
    this(ref ubyte[] backing) {
        this.backingStream = backing;
    }

    this() {
        this.backingStream = new ubyte[](0);
    }

    override bool hasLength() { return true; }
    override bool canSeek() { return true; }
    override bool canTell() { return true; }
    override bool canRead() { return true; }
    override bool canWrite() { return true; }

    override size_t getLength() { return backingStream.length; }
    override size_t tell() { return cursor; }

    override 
    void seek(ptrdiff_t pos, SeekPosition offset=SeekPosition.start) {
        switch (offset) {
            case SeekPosition.start:
                cursor = offset;
                break;
            case SeekPosition.end:
                cursor = getLength()-offset;
                break;
            case SeekPosition.relative:
                cursor += offset;
                break;
            default: assert(0);
        }
    }

    override
    int read(ref ubyte[] buffer) {
        size_t runLength = buffer.length;

        // EOF
        if (cursor >= backingStream.length) return -1;

        // Less than full length
        if (cursor+buffer.length >= backingStream.length) {

            // Recalc runlength and read
            runLength = backingStream.length-(cursor+buffer.length);
            buffer[0..runLength] = backingStream[cursor..$];

            cursor += runLength;
            return cast(int)runLength;
        }

        // Full length
        buffer[0..$] = backingStream[cursor..cursor+runLength];
        cursor += runLength;
        return cast(int)runLength;
    }

    override
    void write(ubyte[] buffer) {

        // Resize backing buffer if need be 
        if (cursor+buffer.length >= backingStream.length) {
            backingStream.length = cursor+buffer.length+1;
        }

        // Write to backing buffer
        backingStream[cursor..cursor+buffer.length] = buffer[0..$];
        cursor += buffer.length;
    }

    /**
        Returns the backing stream of the memory stream
    */
    ref ubyte[] getBackingStream() {
        return backingStream;
    }
}

class FileStream : Stream {
private:
    File file;
    size_t size = 0;
    size_t cursor = 0;

public:
    this(File file) {
        this.file = file;

        // Get initial length of file
        file.seek(0, SEEK_END);
        this.size = file.tell();

        // Seek back to start
        file.seek(0, SEEK_SET);
    }

    override bool hasLength() { return true; }
    override bool canSeek() { return true; }
    override bool canTell() { return true; }
    override bool canRead() { return true; }
    override bool canWrite() { return true; }

    override size_t getLength() { return size; }
    override size_t tell() { return cursor; }

    override 
    void seek(ptrdiff_t pos, SeekPosition offset=SeekPosition.start) {
        switch (offset) {
            case SeekPosition.start:
                cursor = pos;
                file.seek(pos, SEEK_SET);
                break;
            case SeekPosition.end:
                cursor = getLength()-pos;
                file.seek(pos, SEEK_END);
                break;
            case SeekPosition.relative:
                cursor += pos;
                file.seek(pos, SEEK_CUR);
                break;
            default: assert(0);
        }
    }

    override
    int read(ref ubyte[] buffer) {
        size_t runLength = buffer.length;

        // EOF
        if (cursor >= size) return -1;

        // Less than full length
        if (cursor+buffer.length >= size) {

            // Recalc runlength and read
            runLength = size-(cursor+buffer.length-1);
            file.rawRead(buffer[0..runLength]);

            cursor += runLength;
            return cast(int)runLength;
        }

        // Full length
        file.rawRead(buffer[0..runLength]);
        cursor += runLength;
        return cast(int)runLength;
    }

    override
    void write(ubyte[] buffer) {

        // Resize backing buffer if need be 
        if (cursor+buffer.length >= size) {
            size = cursor+buffer.length+1;
        }

        // Write to backing buffer
        file.rawWrite(buffer[0..$]);
        cursor += buffer.length;
    }
}