package starling.styles;
import openfl.geom.Matrix;

using starling.rendering.VertexDataTools;

@:access(starling.styles.MeshStyle)
class MeshStyleTools
{
	public static function fastBatchVertexData(style:MeshStyle, targetStyle:MeshStyle, targetVertexID:Int,
                                    matrix:Matrix, vertexID:Int, numVertices:Int):Void
    {
        style._vertexData.fastCopyTo(targetStyle._vertexData, targetVertexID, matrix, vertexID, numVertices);
    }
}