// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters;
import openfl.Vector;
import starling.rendering.FilterEffect;
import starling.rendering.Painter;
import starling.textures.Texture;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import starling.rendering.FilterEffect;
import starling.rendering.Program;
import starling.textures.Texture;
import starling.utils.MathUtil;
import starling.utils.RenderUtil;

import starling.rendering.FilterEffect.tex;

/** The BlurFilter applies a Gaussian blur to an object. The strength of the blur can be
 *  set for x- and y-axis separately. */
class BlurFilter extends FragmentFilter
{
    private var _blurX:Float;
    private var _blurY:Float;

    /** Create a new BlurFilter. For each blur direction, the number of required passes is
     *  <code>Math.ceil(blur)</code>.
     *
     *  <ul><li>blur = 0.5: 1 pass</li>
     *      <li>blur = 1.0: 1 pass</li>
     *      <li>blur = 1.5: 2 passes</li>
     *      <li>blur = 2.0: 2 passes</li>
     *      <li>etc.</li>
     *  </ul>
     */
    public function new(blurX:Float=1.0, blurY:Float=1.0, resolution:Float=1.0)
    {
        super();
        _blurX = blurX;
        _blurY = blurY;
        this.resolution = resolution;
    }

    /** @private */
    override public function process(painter:Painter, helper:IFilterHelper,
                                     input0:Texture = null, input1:Texture = null,
                                     input2:Texture = null, input3:Texture = null):Texture
    {
        var effect:BlurEffect = cast(this.effect, BlurEffect);

        if (_blurX == 0 && _blurY == 0)
        {
            effect.strength = 0;
            return super.process(painter, helper, input0);
        }

        var blurX:Float = Math.abs(_blurX);
        var blurY:Float = Math.abs(_blurY);
        var outTexture:Texture = input0;
        var inTexture:Texture;

        effect.direction = BlurEffect.HORIZONTAL;

        while (blurX > 0)
        {
            effect.strength = Math.min(1.0, blurX);

            blurX -= effect.strength;
            inTexture = outTexture;
            outTexture = super.process(painter, helper, inTexture);

            if (inTexture != input0) helper.putTexture(inTexture);
        }

        effect.direction = BlurEffect.VERTICAL;

        while (blurY > 0)
        {
            effect.strength = Math.min(1.0, blurY);

            blurY -= effect.strength;
            inTexture = outTexture;
            outTexture = super.process(painter, helper, inTexture);

            if (inTexture != input0) helper.putTexture(inTexture);
        }

        return outTexture;
    }

    /** @private */
    @:noCompletion override private function createEffect():FilterEffect
    {
        return new BlurEffect();
    }

    /** @private */
    @:noCompletion override private function set_resolution(value:Float):Float
    {
        super.resolution = value;
        updatePadding();
        return value;
    }

    /** @private */
    @:noCompletion override private function get_numPasses():Int
    {
        return Std.int(Math.max((Math.ceil(_blurX) + Math.ceil(_blurY)), 1));
    }

    private function updatePadding():Void
    {
        var paddingX:Float = (_blurX != 0 ? Math.ceil(Math.abs(_blurX)) + 3 : 1) / resolution;
        var paddingY:Float = (_blurY != 0 ? Math.ceil(Math.abs(_blurY)) + 3 : 1) / resolution;

        padding.setTo(paddingX, paddingX, paddingY, paddingY);
    }

    /** The blur factor in x-direction.
     *  The number of required passes will be <code>Math.ceil(value)</code>. */
    public var blurX(get, set):Float;
    @:noCompletion private function get_blurX():Float { return _blurX; }
    @:noCompletion private function set_blurX(value:Float):Float
    {
        _blurX = value;
        updatePadding();
        return value;
    }

    /** The blur factor in y-direction.
     *  The number of required passes will be <code>Math.ceil(value)</code>. */
    public var blurY(get, set):Float;
    @:noCompletion private function get_blurY():Float { return _blurY; }
    @:noCompletion private function set_blurY(value:Float):Float
    {
        _blurY = value;
        updatePadding();
        return value;
    }
}

class BlurEffect extends FilterEffect
{
    public static var HORIZONTAL:String = "horizontal";
    public static var VERTICAL:String = "vertical";

    private static var MAX_SIGMA:Float = 2.0;

    private var _strength:Float;
    private var _direction:String;

    private var _offsets:Vector<Float> = Vector.ofArray([0.0, 0, 0, 0]);
    private var _weights:Vector<Float> = Vector.ofArray([0.0, 0, 0, 0]);

    // helpers
    private var sTmpWeights:Vector<Float> = new Vector<Float>(5, true);

    /** Creates a new BlurEffect.
     *
     *  @param direction     horizontal or vertical
     *  @param strength      range 0-1
     */
    public function new(direction:String="horizontal", strength:Float=1):Void
    {
        super();
        this.strength  = strength;
        this.direction = direction;
    }

    override private function createProgram():Program
    {
        if (_strength == 0) return super.createProgram();

        var vertexShader:String = [
            "m44 op, va0, vc0     ", // 4x4 matrix transform to output space
            "mov v0, va1          ", // pos:  0 |
            "sub v1, va1, vc4.zwxx", // pos: -2 |
            "sub v2, va1, vc4.xyxx", // pos: -1 | --> kernel positions
            "add v3, va1, vc4.xyxx", // pos: +1 |     (only 1st two values are relevant)
            "add v4, va1, vc4.zwxx"  // pos: +2 |
        ].join("\n");

        // v0-v4 - kernel position
        // fs0   - input texture
        // fc0   - weight data
        // ft0-4 - pixel color from texture
        // ft5   - output color

        var fragmentShader:String = [
            tex("ft0", "v0", 0, texture),    // read center pixel
            "mul ft5, ft0, fc0.xxxx       ", // multiply with center weight

            tex("ft1", "v1", 0, texture),    // read pixel -2
            "mul ft1, ft1, fc0.zzzz       ", // multiply with weight
            "add ft5, ft5, ft1            ", // add to output color

            tex("ft2", "v2", 0, texture),    // read pixel -1
            "mul ft2, ft2, fc0.yyyy       ", // multiply with weight
            "add ft5, ft5, ft2            ", // add to output color

            tex("ft3", "v3", 0, texture),    // read pixel +1
            "mul ft3, ft3, fc0.yyyy       ", // multiply with weight
            "add ft5, ft5, ft3            ", // add to output color

            tex("ft4", "v4", 0, texture),    // read pixel +2
            "mul ft4, ft4, fc0.zzzz       ", // multiply with weight
            "add  oc, ft5, ft4            "  // add to output color
        ].join("\n");

        return Program.fromSource(vertexShader, fragmentShader);
    }

    override private function beforeDraw(context:Context3D):Void
    {
        super.beforeDraw(context);

        if (_strength != 0)
        {
            updateParameters();

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, _offsets);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _weights);
        }
    }

    @:noCompletion override private function get_programVariantName():UInt
    {
        return super.programVariantName | (_strength != 0 ? 1 << 4 : 0);
    }

    private function updateParameters():Void
    {
        // algorithm described here:
        // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
        //
        // To run in constrained mode, we can only make 5 texture look-ups in the fragment
        // shader. By making use of linear texture sampling, we can produce similar output
        // to what would be 9 look-ups.

        var sigma:Float;
        var pixelSize:Float;

        if (_direction == HORIZONTAL)
        {
            sigma = _strength * MAX_SIGMA;
            pixelSize = 1.0 / texture.root.width;
        }
        else
        {
            sigma = _strength * MAX_SIGMA;
            pixelSize = 1.0 / texture.root.height;
        }

        var twoSigmaSq:Float = 2 * sigma * sigma;
        var multiplier:Float = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);

        // get weights on the exact pixels (sTmpWeights) and calculate sums (_weights)

        for (i in 0 ... 5)
            sTmpWeights[i] = multiplier * Math.exp(-i*i / twoSigmaSq);

        _weights[0] = sTmpWeights[0];
        _weights[1] = sTmpWeights[1] + sTmpWeights[2];
        _weights[2] = sTmpWeights[3] + sTmpWeights[4];

        // normalize weights so that sum equals "1.0"

        var weightSum:Float = _weights[0] + 2*_weights[1] + 2*_weights[2];
        var invWeightSum:Float = 1.0 / weightSum;

        _weights[0] *= invWeightSum;
        _weights[1] *= invWeightSum;
        _weights[2] *= invWeightSum;

        // calculate intermediate offsets

        var offset1:Float = (  pixelSize * sTmpWeights[1] + 2*pixelSize * sTmpWeights[2]) / _weights[1];
        var offset2:Float = (3*pixelSize * sTmpWeights[3] + 4*pixelSize * sTmpWeights[4]) / _weights[2];

        // depending on pass, we move in x- or y-direction

        if (_direction == HORIZONTAL)
        {
            _offsets[0] = offset1;
            _offsets[1] = 0;
            _offsets[2] = offset2;
            _offsets[3] = 0;
        }
        else
        {
            _offsets[0] = 0;
            _offsets[1] = offset1;
            _offsets[2] = 0;
            _offsets[3] = offset2;
        }
    }

    public var direction(get, set):String;
    @:noCompletion private function get_direction():String { return _direction; }
    @:noCompletion private function set_direction(value:String):String { return _direction = value; }

    public var strength(get, set):Float;
    @:noCompletion private function get_strength():Float { return _strength; }
    @:noCompletion private function set_strength(value:Float):Float
    {
        return _strength = MathUtil.clamp(value, 0, 1);
    }
}
