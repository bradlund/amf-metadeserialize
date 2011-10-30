package com.oneboldidea.amfmetadeserialize.error
{

	public class Amf3ParserError extends Error
	{
		public static const READ_METHOD_ON_NULL_BYTEARRAY:int = 4000;

		public static const UNKNOWN_TYPE_MARKER:int = 4001;

		public static var OBJECT_NOT_EXTERNALIZABLE:int = 4002;

		public function Amf3ParserError( id:int = -1 )
		{
			super( getMessageFromId( id ), id );
		}

		private static function getMessageFromId( id:int ):String
		{
			var returnString:String;

			switch ( id )
			{
				case READ_METHOD_ON_NULL_BYTEARRAY:
					returnString = "Attempting to call a read method when byteArray is null";
					break;
				case UNKNOWN_TYPE_MARKER:
					returnString = "Unknown typemarker found.";
					break;
				case OBJECT_NOT_EXTERNALIZABLE:
					returnString = "Unknown IExternalizable class";
					break;
				default:
					returnString = "Undefined error occurred in Amf3Parser";
			}
			return returnString;
		}
	}
}
