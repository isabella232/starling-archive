package starling.rendering;

import haxe.io.BytesData;
import openfl.geom.Matrix;
import starling.rendering.VertexData.premultiplyAlpha;
import starling.rendering.VertexData.switchEndian;
import starling.utils.Float32ArrayWrapper;

@:access(starling.rendering.VertexData)
class VertexDataTools
{
    /** Writes the given coordinates to the specified vertex and attribute. */
    #if (cs && unsafe)
    @:unsafe
    #else
    inline
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
	
	#if (cs && unsafe)
    @:unsafe
    #elseif cs
    #else
    inline
    #end
    public static function fastCopyTo(data:VertexData, target:VertexData, targetVertexID:Int, matrix:Matrix,
                           vertexID:Int, numVertices:Int):Void
    {
        #if cs
		if (numVertices < 0 || vertexID + numVertices > data._numVertices)
            numVertices = data._numVertices - vertexID;

        if (data._format == target._format)
        {
            if (target._numVertices < targetVertexID + numVertices)
                target._numVertices = targetVertexID + numVertices;

            target._tinted = target._tinted || data._tinted;

            // In this case, it's fastest to copy the complete range in one call
            // and then overwrite only the transformed positions.

            var targetRawData:Float32ArrayWrapper = target._rawData;
            targetRawData.position = targetVertexID * data._vertexSize;
            var length:UInt = numVertices * data._vertexSize;
            targetRawData.resize(targetRawData.position + length);
            #if (cs && unsafe)
            untyped __cs__("fixed(byte *dst = targetRawData.data.b){");
            #else
            var dst:Dynamic = null;
            #end
            targetRawData.fastWriteBytes(untyped dst, data._rawData, vertexID * data._vertexSize, length);

            if (matrix != null)
            {
                var x:Float, y:Float;
                var pos:Int = targetVertexID * data._vertexSize + data._posOffset;
                var endPos:Int = pos + (numVertices * data._vertexSize);
                #if (cs && unsafe)
                untyped __cs__("float *px");
                untyped __cs__("float *py");
                #end
                
                while (pos < endPos)
                {
                    #if (cs && unsafe)
                    untyped px = untyped __cs__("(float*)&dst[pos]");
                    untyped py = untyped __cs__("(float*)&dst[pos + 4]");
                    x = untyped __cs__("*px");
                    y = untyped __cs__("*py");
                    untyped __cs__("*px = (float)(matrix.a * x + matrix.c * y + matrix.tx)");
                    untyped __cs__("*py = (float)(matrix.d * y + matrix.b * x + matrix.ty)");
                    #else
                    targetRawData.position = pos;
                    x = targetRawData.readFloat();
                    y = targetRawData.readFloat();

                    targetRawData.position = pos;
                    targetRawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                    targetRawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);
                    #end

                    pos += data._vertexSize;
                }
            }
            
            #if (cs && unsafe)
            untyped __cs__("}");
            #end
        }
        else
        {
            if (target._numVertices < targetVertexID + numVertices)
                target.numVertices  = targetVertexID + numVertices; // ensure correct alphas!

            for (i in 0 ... data._numAttributes)
            {
                var srcAttr:VertexDataAttribute = data._attributes[i];
                var tgtAttr:VertexDataAttribute = target.getAttribute(srcAttr.name);

                if (tgtAttr != null) // only copy attributes that exist in the target, as well
                {
                    if (srcAttr.offset == data._posOffset)
                        data.copyAttributeTo_internal(target, targetVertexID, matrix,
                                srcAttr, tgtAttr, vertexID, numVertices);
                    else
                        data.copyAttributeTo_internal(target, targetVertexID, null,
                                srcAttr, tgtAttr, vertexID, numVertices);
                }
            }
        }
        #else
        data.copyTo(target, targetVertexID, matrix, vertexID, numVertices);
        #end
	}
}