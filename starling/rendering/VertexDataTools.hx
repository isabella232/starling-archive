package starling.rendering;

import haxe.io.BytesData;
import starling.rendering.VertexData.premultiplyAlpha;
import starling.rendering.VertexData.switchEndian;

@:access(starling.rendering.VertexData)
class VertexDataTools
{
    /** Writes the given coordinates to the specified vertex and attribute. */
    #if (cs && unsafe)
    @:unsafe
    #end
    public static function fastSetPoint(data:VertexData, vertexID:Int, attrName:String, x:Float, y:Float):Void
    {
        #if (cs && unsafe)
        if (data._numVertices < vertexID + 1)
             data.numVertices = vertexID + 1;

        var offset:Int = attrName == "position" ? data._posOffset : data.getAttribute(attrName).offset;
        var position:Int = vertexID * data._vertexSize + offset;
        var bytesData:BytesData = data._rawData.toBytes().getData();
        cs.Lib.fixed(
        {
            var ptr = cs.Lib.pointerOfArray(bytesData);

            untyped __cs__("float *fptr = (float*)(ptr + position)");
            untyped __cs__("*fptr = (float)x");
            untyped __cs__("++fptr");
            untyped __cs__("*fptr = (float)y");
        });
        #else
        data.setPoint(vertexID, attrName, x, y);
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe
    #end
    public static function fastSetPosition(data:VertexData, vertexID:Int, x:Float, y:Float):Void
    {
        var offset:Int = data._posOffset;
        #if (cs && unsafe)
        var position:Int = vertexID * data._vertexSize + offset;
        var bytesData:BytesData = data._rawData.toBytes().getData();
        cs.Lib.fixed(
        {
            var ptr = cs.Lib.pointerOfArray(bytesData);

            untyped __cs__("float *fptr = (float*)(ptr + position)");
            untyped __cs__("*fptr = (float)x");
            untyped __cs__("++fptr");
            untyped __cs__("*fptr = (float)y");
        });
        #else
        data._rawData.position = vertexID * data._vertexSize + offset;
        data._rawData.writeFloat(x);
        data._rawData.writeFloat(y);
        #end
    }
    
    #if (cs && unsafe)
    @:unsafe
    #end
    public static function fastColorize_premultiplied(data:VertexData, color:UInt=0xffffff, alpha:Float=1.0,
                             vertexID:Int=0, numVertices:Int=-1):Void
    {
        var offset:Int = data._colOffset;
        var pos:Int = vertexID * data._vertexSize + offset;
        var endPos:Int = pos + (numVertices * data._vertexSize);

        var rgba:UInt = ((color << 8) & 0xffffff00) | (Std.int(alpha * 255.0) & 0xff);

        rgba = premultiplyAlpha(rgba);

        #if (cs && unsafe)
        var bytesData:BytesData = data._rawData.toBytes().getData();
        cs.Lib.fixed(
        {
            var ptr = cs.Lib.pointerOfArray(bytesData);
            var uptr:cs.Pointer<UInt>;
            uptr = cast (ptr + pos);
            uptr[0] = switchEndian(rgba);
        #else
            data._rawData.position = pos;
            data._rawData.writeUnsignedInt(switchEndian(rgba));
        #end
            
            pos += data._vertexSize;
            
            while (pos < endPos)
            {
                #if (cs && unsafe)
                uptr = cast (ptr + pos);
                uptr[0] = switchEndian(rgba);
                #else
                data._rawData.position = pos;
                data._rawData.writeUnsignedInt(switchEndian(rgba));
                #end
                pos += data._vertexSize;
            }
            
        #if (cs && unsafe)
        });
        #end
    }
}