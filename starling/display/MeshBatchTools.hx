package starling.display;

import openfl.geom.Matrix;
import starling.display.MeshBatch.MAX_NUM_VERTICES;
import starling.display.MeshBatch.sFullMeshSubset;
import starling.styles.MeshStyle;
import starling.utils.MeshSubset;

using starling.styles.MeshStyleTools;

@:access(starling.display.DisplayObject)
@:access(starling.display.MeshBatch)
class MeshBatchTools
{
	public static function fastAddMesh(batch:MeshBatch, mesh:Mesh, matrix:Matrix, alpha:Float,
                            subset:MeshSubset, ignoreTransformations:Bool):Void
    {
        if (ignoreTransformations) matrix = null;
        else if (matrix == null) matrix = mesh.transformationMatrix;
        if (subset == null) subset = sFullMeshSubset;

        var targetVertexID:Int = batch._vertexData.numVertices;
        var targetIndexID:Int  = batch._indexData.numIndices;
        var meshStyle:MeshStyle = mesh._style;

        if (targetVertexID == 0)
            batch.setupFor(mesh);

        meshStyle.fastBatchVertexData(batch._style, targetVertexID, matrix, subset.vertexID, subset.numVertices);
        meshStyle.batchIndexData(batch._style, targetIndexID, targetVertexID - subset.vertexID,
            subset.indexID, subset.numIndices);

        if (alpha != 1.0) batch._vertexData.scaleAlphas("color", alpha, targetVertexID, subset.numVertices);
        if (batch._batchable) batch.setRequiresRedraw();

        batch._indexSyncRequired = batch._vertexSyncRequired = true;
    }
	
	public static function fastCanAddMesh(batch:MeshBatch, mesh:Mesh, numVertices:Int):Bool
    {
        var currentNumVertices:Int = batch._vertexData.numVertices;

        if (currentNumVertices == 0) return true;
        if (numVertices  < 0) numVertices = mesh.numVertices;
        if (numVertices == 0) return true;
        if (numVertices + currentNumVertices > MAX_NUM_VERTICES) return false;

        return batch._style.canBatchWith(mesh._style);
    }
}