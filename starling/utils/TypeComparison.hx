package starling.utils;

class TypeComparison
{
    #if !cs inline #end
	public static function fastClassEq(typeA:Class<Dynamic>, typeB:Class<Dynamic>)
    {
		#if cs
        return untyped __cs__("typeA == typeB");
		#else
		return typeA == typeB;
		#end
    }
}