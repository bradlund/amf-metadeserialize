package com.oneboldidea.amfmetadeserialize.data
{
	import flash.utils.Dictionary;

	/**
	 * section 3.12 of AMF spec:
	U29O-ref  =  U29 		; The first (low) bit is a flag
							; (representing whether an instance
							; follows) with value 0 to imply that
							; this is not an instance but a
							; reference. The remaining 1 to 28
							; significant bits are used to encode an
							; object reference index (an integer).
	U29O-traits-ref  =  U29 ; The first (low) bit is a flag with
							; value 1. The second bit is a flag
							; (representing whether a trait
							; reference follows) with value 0 to
							; imply that this objects traits are
							; being sent by reference. The remaining
							; 1 to 27 significant bits are used to
							; encode a trait reference index (an
							; integer).
	U29O-traits-ext  =  U29 ; The first (low) bit is a flag with
							; value 1. The second bit is a flag with
							; value 1. The third bit is a flag with
							; value 1. The remaining 1 to 26
							; significant bits are not significant
							; (the traits member count would always
							; be 0).
	U29O-traits  =  U29  	; The first (low) bit is a flag with
							; value 1. The second bit is a flag with
							; value 1. The third bit is a flag with
							; value 0.  The fourth bit is a flag
							; specifying whether the type is
							; dynamic. A value of 0 implies not
							; dynamic, a value of 1 implies dynamic.
							; Dynamic types may have a set of name
							; value pairs for dynamic members after
							; the sealed member   section. The
							; remaining 1 to 25 significant bits are
							; used to encode the number of sealed
							; traits member names that follow after
							; the class name (an integer).
class-name  =  UTF-8-vr    	; Note: use the empty string for
							; anonymous classes.
dynamic-member  =  UTF-8-vr	; Another dynamic member follows
							; until the string-type is the
							; empty string.
	 */
	public class Amf3ClassTraits
	{
		public function Amf3ClassTraits()
		{
		}

		public var numTraits:int;

		public var isExternalizable:Boolean;

		public var isAnonymous:Boolean;

		public var isDynamic:Boolean;

		public var className:String;

		// these are any public properties that would be serialized/deserialized
		public var traitNames:Array = [];

		// key is name, value is type classname
		public var traitTypes:Dictionary = new Dictionary( true );
	}
}
