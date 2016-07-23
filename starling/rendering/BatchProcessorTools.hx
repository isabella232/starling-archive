package starling.rendering;
import openfl.geom.Matrix;
import starling.display.Mesh;
import starling.rendering.BatchProcessor.sMeshSubset;
import starling.utils.MeshSubset;

using starling.display.MeshBatchTools;

@:access(starling.rendering.BatchProcessor)
class BatchProcessorTools
{
	public static function fastAddMesh(processor:BatchProcessor, mesh:Mesh, state:RenderState, subset:MeshSubset,
                            ignoreTransformations:Bool):Void
    {
        if (subset == null)
        {
            subset = sMeshSubset;
            subset.vertexID = subset.indexID = 0;
            subset.numVertices = mesh.numVertices;
            subset.numIndices  = mesh.numIndices;
        }
        else
        {
            if (subset.numVertices < 0) subset.numVertices = mesh.numVertices - subset.vertexID;
            if (subset.numIndices  < 0) subset.numIndices  = mesh.numIndices  - subset.indexID;
        }

        if (subset.numVertices > 0)
        {
            if (processor._currentBatch == null || !processor._currentBatch.fastCanAddMesh(mesh, subset.numVertices))
            {
                processor.finishBatch();

                processor._currentStyleType = mesh.style.type;
                processor._currentBatch = processor._batchPool.get(processor._currentStyleType);
                processor._currentBatch.blendMode = state != null ? state.blendMode : mesh.blendMode;
                processor._cacheToken.setTo(processor._batches.length);
                processor._batches[processor._batches.length] = processor._currentBatch;
            }

            var matrix:Matrix = state != null ? @:privateAccess state._modelviewMatrix : null;
            var alpha:Float  = state != null ? @:privateAccess state._alpha : 1.0;

            processor._currentBatch.fastAddMesh(mesh, matrix, alpha, subset, ignoreTransformations);
            processor._cacheToken.vertexID += subset.numVertices;
            processor._cacheToken.indexID  += subset.numIndices;
        }
    }
}