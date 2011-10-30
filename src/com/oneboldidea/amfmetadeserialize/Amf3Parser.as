package com.oneboldidea.amfmetadeserialize
{
	import com.oneboldidea.amfmetadeserialize.data.Amf3ClassTraits;
	import com.oneboldidea.amfmetadeserialize.data.Amf3Object;
	import com.oneboldidea.amfmetadeserialize.error.Amf3ParserError;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.IExternalizable;
	import mx.collections.ArrayCollection;
	import mx.messaging.messages.AbstractMessage;
	import mx.messaging.messages.AcknowledgeMessageExt;
	import mx.messaging.messages.AsyncMessageExt;
	import mx.messaging.messages.CommandMessageExt;

	/**
	 * This is the main entrance point for using this library.
	 *
	 * Intended use for this class is as follows.  It should roughly follow the
	 * ByteArray exposed methods for readObject, readByte, readUTF, etc.
	 *
	 * Note that this class is useful for reads only - no serialization methods like
	 * writeObject, writeUTF, etc.
	 *
	 * var object:Amf3Parser = new Amf3Parser();
	 * object.byteArray = myByteArray;
	 * var amf3MetaObject:Amf3MetaObject = object.readObject();
	 *
	 * AMF3 Spec:  http://opensource.adobe.com/wiki/download/attachments/1114283/amf3_spec_05_05_08.pdf
	 *
	 * @author brad.lund
	 *
	 */
	public class Amf3Parser
	{
		private var objectReferences:Array;

		private var stringReferences:Array;

		private var traitsReferences:Array;

		public function Amf3Parser( byteArray:ByteArray = null )
		{
			if ( byteArray )
				this.byteArray = byteArray;
			registerClassAlias( "DSK", AcknowledgeMessageExt );
			registerClassAlias( "DSC", CommandMessageExt );
			registerClassAlias( "DSA", AsyncMessageExt );
		}

		public function setReferences( objectReferences:Array, stringReferences:Array, traitsReferences:Array ):void
		{
			this.objectReferences = objectReferences;
			this.stringReferences = stringReferences;
			this.traitsReferences = traitsReferences;
		}

		private var _byteArray:ByteArray;

		// TODO - this byteArray should probably be swapped for a IDataInput
		public function get byteArray():ByteArray
		{
			return _byteArray;
		}

		public function set byteArray( value:ByteArray ):void
		{
			_byteArray = value;
			// note that we're leaving the position as is here - should we be capturing
			// original position? 
			objectReferences = new Array();
			stringReferences = new Array();
			traitsReferences = new Array();
		}

		public function readObject( propertyName:String = null ):Amf3Object
		{
			if ( !byteArray )
			{
				throw new Amf3ParserError( Amf3ParserError.READ_METHOD_ON_NULL_BYTEARRAY );
			}
			var typeMarker:int = byteArray.readByte();
			return parseAmf3( typeMarker, propertyName );
		}

		protected function parseAmf3( typeMarker:int, propertyName:String = null ):Amf3Object
		{
			var returnObject:Amf3Object = new Amf3Object( propertyName );

			// AMF3 spec 3.1, about a dozen possible primitive + object potential values - see Amf3MarkerTypes for options
			switch ( typeMarker )
			{
				case Amf3MarkerTypes.OBJECT:
					returnObject = readAmf3Object();
					returnObject.propertyName = propertyName;
					break;
				case Amf3MarkerTypes.UNDEFINED:
					returnObject.propertyValue = undefined;
					returnObject.propertyValueString = "undefined";
					break;
				case Amf3MarkerTypes.NULL:
					returnObject.propertyValue = null;
					returnObject.propertyValueString = "null";
					break;
				case Amf3MarkerTypes.FALSE:
					returnObject.propertyValue = false;
					returnObject.propertyValueString = "false";
					returnObject.className = "Boolean";
					break;
				case Amf3MarkerTypes.TRUE:
					returnObject.propertyValue = true;
					returnObject.propertyValueString = "true";
					returnObject.className = "Boolean";
					break;
				case Amf3MarkerTypes.INTEGER:
					returnObject.propertyValue = readUint29();
					returnObject.propertyValueString = returnObject.propertyValue.toString();
					returnObject.className = "int";
					break;
				case Amf3MarkerTypes.DOUBLE:
					returnObject.propertyValue = readDouble();
					returnObject.propertyValueString = returnObject.propertyValue.toString();
					returnObject.className = "Number";
					break;
				case Amf3MarkerTypes.String:
					returnObject.propertyValue = readString();
					returnObject.propertyValueString = returnObject.propertyValue as String;
					returnObject.className = "String";
					break;
				case Amf3MarkerTypes.XMLDOC:
					returnObject.propertyValue = readXMLDoc();
					returnObject.propertyValueString = "XML";
					returnObject.className = "XML";
					break;
				case Amf3MarkerTypes.DATE:
					returnObject.propertyValue = readDate();
					returnObject.propertyValueString = returnObject.propertyValue.toString();
					returnObject.className = "Date";
					break;
				case Amf3MarkerTypes.ARRAY:
					returnObject.properties = readArray();
					returnObject.className = "Array";
					break;
				case Amf3MarkerTypes.XML:
					returnObject.propertyValue = readXMLDoc();
					returnObject.propertyValueString = "XML";
					returnObject.className = "XML";
					break;
				case Amf3MarkerTypes.BYTEARRAY:
					returnObject.propertyValue = readByteArray();
					returnObject.propertyValueString = "ByteArray";
					returnObject.className = "ByteArray";
					break;
				default:
					returnObject = null;
					throw new Amf3ParserError();
			}
			return returnObject;
		}

		/**
		 * Reads an unsigned 29-bit integer. See AMF spec 1.3.1 for more info
		 * on how this data is packed.
		 *
		 *  Relevant excerpt below:
		 *  As with a normal 32-bit integer, up to 4 bytes are required
		 * to hold the value however the high bit of the first 3 bytes are used as flags to determine
		 * whether the next byte is part of the integer. With up to 3 bits of the 32 bits being used as
		 * flags, only 29 significant bits remain for encoding an integer. This means the largest
		 * unsigned integer value that can be represented is 2^29 - 1.
		 *
		 * 8 4 2 1
		 *
		 * @return integer value
		 *
		 */
		protected function readUint29():int
		{
			if ( !byteArray )
				throw new Amf3ParserError( Amf3ParserError.READ_METHOD_ON_NULL_BYTEARRAY );
			var returnInt:int;
			// always at least one byte.
			var byteCount:int = 1;
			// get the first byte
			var byte:int = byteArray.readUnsignedByte();

			// keep appending bytes while a) the first bit is 1 and b) the bytecount is <= 4
			while ((( byte & 0x80 ) != 0x00 ) && byteCount < 4 )
			{
				// shift the value over 7 bits (byte - 1 flag bit)
				returnInt = returnInt << 7;
				// bitwise or the 7 value bits from the current byte onto the return int
				returnInt = returnInt | ( byte & 0x7f );
				// read the next byte - if we're in this loop, the bit indicates another byte to come
				byte = byteArray.readUnsignedByte();
				byteCount++;
			}

			// now check - were there less than 4 bytes delivered? if so, drop the last byte on
			if ( byteCount < 4 )
			{
				returnInt = returnInt << 7;
				returnInt = returnInt | byte;
			}
			// all 4 bytes were delivered, append the last byte, no need to worry about flag bit.
			else
			{
				returnInt = returnInt << 8;
				returnInt = returnInt | byte;

				// stole this from BlazeDS code - think it's to flip the sign or manage range exceptions?
				if (( returnInt & 0x10000000 ) != 0 )
					returnInt |= 0xe0000000;
			}
			return returnInt;
		}

		protected function readDouble():Number
		{
			if ( !byteArray )
				throw new Amf3ParserError( Amf3ParserError.READ_METHOD_ON_NULL_BYTEARRAY );
			return byteArray.readDouble();
		}

		protected function readString():String
		{
			// note that the String can be either a UTF object or a String reference (section 3.8)
			var uint29ref:int = readUint29();
			// the payload is either the reference or the length of the string
			var payload:int = uint29ref >> 1;

			// check to see if this is a reference or not - if lowest bit is zero, it's a ref
			if (( uint29ref & 0x01 ) == 0 )
			{
				// it's a ref - bitshift off the low bit, and go get it and return.
				return stringReferences[ payload ];
			}

			// if we got to here, it's valid string. the payload is the string length in bytes
			//
			// per spec: The empty String is never sent by reference
			if ( payload == 0 )
				return "";
			var returnString:String = byteArray.readUTFBytes( payload );
			stringReferences.push( returnString );
			return returnString;
		}

		protected function readXMLDoc():XML
		{
			// TODO Auto Generated method stub
			return new XML();
		}

		protected function readDate():Date
		{
			var uint29ref:int = readUint29();

			// check to see if this is a reference or not - if lowest bit is zero, it's a ref
			if (( uint29ref & 0x01 ) == 0 )
			{
				// it's a ref - bitshift off the low bit, and go get it and return.
				return objectReferences[ uint29ref >> 1 ];
			}
			// if we get to here,it's not a reference.
			var date:Date = new Date();
			date.setTime( byteArray.readDouble());
			objectReferences.push( date );
			return date;
		}

		protected function readArray():Array
		{
			var uint29ref:int = readUint29();
			// the payload is either the object reference, or the length of the array 
			var payload:int = uint29ref >> 1;

			// check to see if this is a reference or not - if lowest bit is zero, it's a ref
			if (( uint29ref & 0x01 ) == 0 )
			{
				// it's a ref - bitshift off the low bit, and go get it and return.
				return objectReferences[ payload ];
			}
			// if we get to here, it's a fresh instance of an array, and payload indicates the length.
			var array:Array = new Array();
			// associate arrays (i.e. dictionaries/hashes) first
			var key:String;

			while ( byteArray.bytesAvailable < byteArray.length )
			{
				key = readString();

				// go until you hit an empty string
				if ( key == null || key == "" )
					break;
				array[ key ] = readObject();
			}

			// dense arrays
			for ( var i:int = 0; i < payload; ++i )
			{
				array.push( readObject( "[" + i + "]" ));
			}
			objectReferences.push( array );
			return array;
		}

		protected function readByteArray():ByteArray
		{
			// TODO Auto Generated method stub
			return new ByteArray();
		}

		/**
		 * See section 3.12 of the AMF spec for more info - relevant sections
		 * are located in the class comments for Amf3ClassTraits
		 *
		 * @return
		 *
		 */
		protected function readAmf3Object():Amf3Object
		{
			var uint29ref:int = readUint29();
			// the payload is the reference of the object, if it's an obj ref
			var payload:int = uint29ref >> 1;

			// check to see if this is a reference or not - if lowest bit is zero, it's a ref
			if (( uint29ref & 0x01 ) == 0 )
			{
				// it's a ref - bitshift off the low bit, and go get it and return.
				return objectReferences[ payload ];
			}
			// if we get to here,it's not a reference. start by getting the traits.
			var traits:Amf3ClassTraits = getClassTraits( uint29ref );
			var object:Amf3Object = new Amf3Object();
			object.className = traits.className;

			if ( traits.isExternalizable )
			{
				readExternalizable( object );
			}
			else
			{
				var traitObject:Amf3Object;

				for ( var i:int = 0; i < traits.numTraits; i++ )
				{
					traitObject = readObject( traits.traitNames[ i ]);
					indexTraitType( traits, traitObject );
					object.addProperty( traitObject );
				}

				// if dynamic, keep parsing name/value pairs until we hit the end of the input, or 
				// an empty string. (empty string = "" or null? not sure, testing both)
				if ( traits.isDynamic )
				{
					while ( byteArray.position < byteArray.length )
					{
						var trait:String = readString();

						if ( !trait || trait == "" )
						{
							break;
						}
						traitObject = readObject( trait );
						indexTraitType( traits, traitObject );
						object.addProperty( traitObject );
					}
				}
			}
			objectReferences.push( object );
			return object;
		}

		private function indexTraitType( traits:Amf3ClassTraits, traitObject:Amf3Object ):void
		{
			// if the classname is null or undefined
			if ( !traitObject.className )
				return;
			// if it dooesn't exist, add this traitname/classname pair to the traits dictionary for later reporting
			var dictResult:String = traits.traitTypes[ traitObject.propertyName ];

			if ( !dictResult )
				traits.traitTypes[ traitObject.propertyName ] = traitObject.className;
		}

		private function readExternalizable( object:Amf3Object ):void
		{
			switch ( object.className )
			{
				case "flex.messaging.io.ArrayCollection":
					object.className = "mx.collections.ArrayCollection";
					var source:Amf3Object = readObject( "source" ) as Amf3Object;
					object.properties = source.properties;
					break;
				case "DSK": // adobe shorthand for AcknowledgeMessageExt
				case "DSC": // adobe shorthand for CommandMessageExt
				case "DSA": // adobe shorthand for AsyncMessageExt
					var messageParser:Amf3MessageParser = new Amf3MessageParser( object, byteArray );
					messageParser.setReferences( objectReferences, stringReferences, traitsReferences );
					messageParser.readMessage();
					break;
				default:
					throw new Amf3ParserError( Amf3ParserError.OBJECT_NOT_EXTERNALIZABLE );
			}
		}

		private function getClassTraits( uint29ref:int ):Amf3ClassTraits
		{
			// by getting to here, low bit is always 1. check the next bit - if it's 0, 
			// the traits are sent by reference. 
			if (( uint29ref & 0x02 ) == 0 )
			{
				// by reference.  bitshift twice and use the reference. 
				return traitsReferences[ uint29ref >> 2 ] as Amf3ClassTraits;
			}
			// if we get to here, it's not a reference. we know that the first two bits are 1.
			var returnTrait:Amf3ClassTraits = new Amf3ClassTraits();
			// the third bit indicates it's externalizable - i don't know what to do with this yet.f
			returnTrait.isExternalizable = (( uint29ref & 0x04 ) == 0x04 );
			// next bit indicates whether class is dynamic or not.
			returnTrait.isDynamic = (( uint29ref & 0x08 ) == 0x08 );
			// the remaining bits indicate the # of traits (properties) on the object.
			var traitCount:int = ( uint29ref >> 4 );
			returnTrait.numTraits = traitCount;
			// now get the class-name
			returnTrait.className = readString();
			var traits:Array = [];

			// now read off all the trait names			
			for ( var i:int = 0; i < traitCount; i++ )
			{
				traits.push( readString());
			}
			returnTrait.traitNames = traits;
			traitsReferences.push( returnTrait );
			return returnTrait;
		}

		public function getTraitsReferences():Array
		{
			return traitsReferences;
		}
	}
}
