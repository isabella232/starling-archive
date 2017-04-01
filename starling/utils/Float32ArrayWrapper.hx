package starling.utils;
import flash.utils.ByteArray;
import flash.utils.Endian;
import haxe.io.Bytes;
import lime.utils.UInt32Array;
import openfl.utils.ArrayBuffer;
import openfl.utils.Float32Array;
import openfl.utils.ByteArray.ByteArrayData;

@:forward(clear, fastReadFloat, fastWriteBytes, fastWriteFloat, fastWriteUnsignedInt, readFloat, readUnsignedInt, resize, writeBytes, writeFloat, writeUnsignedInt, bytesAvailable, endian, length, position)
abstract Float32ArrayWrapper(Float32ArrayWrappedData) from Float32ArrayWrappedData to Float32ArrayWrappedData
{
    public function new()
    {
        this = new Float32ArrayWrappedData();
    }
    
    @:noCompletion @:to public inline function toByteArray():ByteArray
    {
        return this.data;
    }
    
    @:noCompletion @:to public inline function toBytes():Bytes
    {
        return @:privateAccess Bytes.ofData(this.data);
    }
    
    @:noCompletion @:arrayAccess private inline function get(index:Int):Int
    {
        return this.data[index];
    }
    
    @:noCompletion @:arrayAccess private inline function set(index:Int, value:Int):Int
    {
        return this.data[index] = value;
    }
}

class Float32ArrayWrappedData
{
    public var data(default, null):ByteArray;
    #if (js && bytearray_wrap)
    private var float32Array:Float32Array;
    private var uint32Array:UInt32Array;
    #end

    public function new()
    {
        data = new ByteArray();
        #if (js && bytearray_wrap)
        var buffer:ArrayBuffer = data.toArrayBuffer();
        float32Array = untyped __js__("new Float32Array({0})", buffer);
        uint32Array = untyped __js__("new Uint32Array({0})", buffer);
        #end
    }
    
    public inline function clear()
    {
        data.clear();
    }
    
    public #if (js || flash) inline #end function readFloat():Float
    {
        #if (js && bytearray_wrap)
        data.position += 4;
        return float32Array[Std.int((data.position - 4) / 4)];
        #elseif flash
        return data.readFloat();
        #elseif cpp
        data.position += 4;
        return untyped __global__.__hxcpp_memory_get_float((data:ByteArrayData).b, data.position - 4);
        #else
        data.position += 4;
        return (data:ByteArrayData).getFloat(data.position - 4);
        #end
    }
    
    public inline function readUnsignedInt():Int
    {
        #if (js && bytearray_wrap)
        return uint32Array[Std.int(data.position / 4)];
        #else
        return data.readUnsignedInt();
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe @:skipReflection
    #end
    public #if (!cs && !unsafe) inline #end function writeBytes(bytes:ByteArray, offset:Int=0, length:Int=0)
    {
        #if (cs && unsafe)
        @:privateAccess (data:ByteArrayData).__resize (data.position + length);
        untyped __cs__("fixed(byte *dst = {0}, src = {1}){", this.data.b, bytes.b);
        untyped __cs__("byte *d = dst + {0}, s = src + {1}", this.data.position, offset);
        for (i in 0 ... length)
        {
            untyped __cs__("*d = *s");
            untyped __cs__("d++;s++");
        }
        untyped __cs__("}");
        this.data.position += length;
        #else
        data.writeBytes(bytes, offset, length);
        #if (js && bytearray_wrap)
        createTypedArrays();
        #end
        #end
    }

    public #if (js || flash) inline #end function writeFloat(value:Float):Void
    {
        #if (js && bytearray_wrap)
        float32Array[Std.int(data.position / 4)] = value;
        data.position += 4;
        #elseif flash
        data.writeFloat(value);
        #elseif cpp
        untyped __global__.__hxcpp_memory_set_float((data:ByteArrayData).b, data.position, value);
        data.position += 4;
        #else
        (data:ByteArrayData).setFloat (data.position, value);
        data.position += 4;
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe @:skipReflection
    #end
    public #if (!cs && !unsafe) inline #end function fastReadFloat(ptr:UInt8Ptr):Float
    {
        #if (cs && unsafe)
        var r:Float = untyped __cs__("*(float*)&ptr[{0}]", data.position);
        data.position += 4;
        return r;
        #else
        return readFloat();
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe @:skipReflection
    #end
    public #if flash inline #end function fastWriteBytes(ptr:UInt8Ptr, bytes:Float32ArrayWrapper, offset:Int, length:Int)
    {
        #if (cs && unsafe)
        
        #if 0
        if (length % 4 != 0)
            throw "length should be multiple of 4";
        #end
        
        untyped __cs__("fixed(byte *src = bytes.data.b){");
        untyped __cs__("uint *d = (uint*)({0} + {1}), s = (uint*)(src + {2})", ptr, this.data.position, offset);
        for (i in 0 ... untyped __cs__("(int)({0} / 4)", length))
        {
            untyped __cs__("*d = *s");
            untyped __cs__("d++;s++");
        }
        untyped __cs__("}");
        this.data.position += length;
        #elseif flash
        data.writeBytes(bytes, offset, length);
        #elseif (js && bytearray_wrap)
        var pos:Int = Std.int(this.data.position / 4);
        var srcPos:Int = Std.int(offset / 4);
        for (i in 0 ... Std.int(length / 4))
            float32Array[pos++] = (bytes:Float32ArrayWrappedData).float32Array[srcPos++];
        this.data.position += length;
        #else
        (data:ByteArrayData).blit(position, (bytes:ByteArrayData), offset, length);
        this.data.position += length;
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe @:skipReflection
    #end
    public #if (!cs && !unsafe) inline #end function fastWriteFloat(ptr:UInt8Ptr, v:Float):Void
    {
        #if (cs && unsafe)
        untyped __cs__("float *fptr = (float*)(ptr + {0})", this.data.position);
        untyped __cs__("*fptr = (float)v");
        data.position += 4;
        #else
        writeFloat(v);
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe @:skipReflection
    #end
    public #if (!cs && !unsafe) inline #end function fastWriteUnsignedInt(ptr:UInt8Ptr, v:Int):Void
    {
        #if (cs && unsafe)
        untyped __cs__("uint *uiptr = (uint*)(ptr + {0})", this.data.position);
        untyped __cs__("*uiptr = (uint)v");
        data.position += 4;
        #else
        writeUnsignedInt(v);
        #end
    }
    
    public inline function writeUnsignedInt(value:Int):Void
    {
        #if (js && bytearray_wrap)
        uint32Array[Std.int(data.position / 4)] = value;
        data.position += 4;
        #else
        data.writeUnsignedInt(value);
        #end
    }
    
    public #if flash inline #end function resize(value:Int):Void
    {
        #if flash
        length = value;
        #elseif (js && bytearray_wrap)
        if (value > @:privateAccess (data:ByteArrayData).__length)
        {
            @:privateAccess (data:ByteArrayData).__resize(value);
            var buffer:ArrayBuffer = data.toArrayBuffer();
            var length:Int = Std.int(buffer.byteLength / 4);
            float32Array = untyped __js__("new Float32Array({0}, 0, {1})", buffer, length);
            uint32Array = untyped __js__("new Uint32Array({0}, 0, {1})", buffer, length);
        }
        #else
        @:privateAccess (data:ByteArrayData).__resize(value);
        #end
    }
    
    private function createTypedArrays():Void
    {
        #if (js && bytearray_wrap)
        var buffer:ArrayBuffer = data.toArrayBuffer();
        if (buffer != float32Array.buffer)
        {
            var length:Int = Std.int(buffer.byteLength / 4);
            float32Array = untyped __js__("new Float32Array({0}, 0, {1})", buffer, length);
            uint32Array = untyped __js__("new Uint32Array({0}, 0, {1})", buffer, length);
        }
        #end
    }
    
    public var bytesAvailable(get, never):Int;
    @:noCompletion private inline function get_bytesAvailable():Int { return data.bytesAvailable; }
    
    public var endian(get, set):Endian;
    @:noCompletion private inline function get_endian():Endian { return data.endian; }
    @:noCompletion private inline function set_endian(value:Endian):Endian { return data.endian = value; }
    
    public var length(get, set):Int;
    @:noCompletion private inline function get_length():Int { return data.length; }
    @:noCompletion private inline function set_length(value:Int):Int
    {
        #if (js && bytearray_wrap)
        data.length = value;
        createTypedArrays();
        return value;
        #else
        return data.length = value;
        #end
    }
    
    public var position(get, set):Int;
    @:noCompletion private inline function get_position():Int { return data.position; }
    @:noCompletion private inline function set_position(value:Int):Int { return data.position = value; }
}
