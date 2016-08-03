package starling.rendering._internal;

#if (flash || openfl >= "4.0.4")
typedef Shader = flash.utils.ByteArray;
#else
typedef Shader = openfl.gl.GLShader;
#end