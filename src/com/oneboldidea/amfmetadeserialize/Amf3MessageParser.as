package com.oneboldidea.amfmetadeserialize
{
	import com.oneboldidea.amfmetadeserialize.data.Amf3Object;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import mx.utils.RPCUIDUtil;

	internal class Amf3MessageParser
	{
		private var object:Amf3Object;

		private var input:IDataInput;

		// Consts from AbstractMessage.as
		private static const HAS_NEXT_FLAG:uint = 128;

		private static const BODY_FLAG:uint = 1;

		private static const CLIENT_ID_FLAG:uint = 2;

		private static const DESTINATION_FLAG:uint = 4;

		private static const HEADERS_FLAG:uint = 8;

		private static const MESSAGE_ID_FLAG:uint = 16;

		private static const TIMESTAMP_FLAG:uint = 32;

		private static const TIME_TO_LIVE_FLAG:uint = 64;

		private static const CLIENT_ID_BYTES_FLAG:uint = 1;

		private static const MESSAGE_ID_BYTES_FLAG:uint = 2;

		// end consts from AbstractMessage.as
		//
		// Consts from AsyncMessage.as
		private static const CORRELATION_ID_FLAG:uint = 1;

		private static const CORRELATION_ID_BYTES_FLAG:uint = 2;

		// end consts from AsyncMessage.as
		//
		// Consts from CommandMessage.as
		private static const OPERATION_FLAG:uint = 1;

		// end consts from CommandMessage
		private var objectReferences:Array;

		private var stringReferences:Array;

		private var traitsReferences:Array;

		/**
		 *
		 * @param object
		 * @param input
		 *
		 */
		public function Amf3MessageParser( object:Amf3Object, input:IDataInput )
		{
			this.object = object;
			this.input = input;
		}

		public function readMessage():void
		{
			if ( !object || !input )
				return;

			switch ( object.className )
			{
				case "DSK": // adobe shorthand for AcknowledgeMessageExt
					object.className = "mx.messaging.messages.AcknowledgeMessageExt (DSK)";
					readAcknowledgeMessage();
					break;
				case "DSC": // adobe shorthand for CommandMessageExt
					object.className = "mx.messaging.messages.CommandMessageExt (DSC)";
					readCommandMessage();
					break;
				case "DSA": // adobe shorthand for AsyncMessageExt	
					object.className = "mx.messaging.messages.AsyncMessageExt (DSA)";
					readAsyncMessage();
					break;
			}
		}

		private function readCommandMessage():void
		{
			readAsyncMessage();
			var flagsArray:Array = readMessageFlags();

			for ( var i:uint = 0; i < flagsArray.length; i++ )
			{
				var flags:uint = flagsArray[ i ] as uint;
				var reservedPosition:uint = 0;

				if ( i == 0 )
				{
					if (( flags & OPERATION_FLAG ) != 0 )
					{
						object.addProperty( new Amf3Object( "operation", "uint", input.readObject() as uint ));
					}
					reservedPosition = 1;
				}

				// For forwards compatibility, read in any other flagged objects
				// to preserve the integrity of the input stream...
				if (( flags >> reservedPosition ) != 0 )
				{
					for ( var j:uint = reservedPosition; j < 6; j++ )
					{
						if ((( flags >> j ) & 1 ) != 0 )
						{
							// forwards compatability? I don't think i care about this.  readObject
							// just to keep the bytes in sync - i'm not going to meta-deserialize
							input.readObject();
						}
					}
				}
			}
		}

		private function readAcknowledgeMessage():void
		{
			readAsyncMessage();
			var flagsArray:Array = readMessageFlags();

			for ( var i:uint = 0; i < flagsArray.length; i++ )
			{
				var flags:uint = flagsArray[ i ] as uint;
				var reservedPosition:uint = 0;

				// For forwards compatibility, read in any other flagged objects
				// to preserve the integrity of the input stream...
				if (( flags >> reservedPosition ) != 0 )
				{
					for ( var j:uint = reservedPosition; j < 6; j++ )
					{
						if ((( flags >> j ) & 1 ) != 0 )
						{
							// forwards compatability? I don't think i care about this.  readObject
							// just to keep the bytes in sync - i'm not going to meta-deserialize
							input.readObject();
						}
					}
				}
			}
		}

		private function readAsyncMessage():void
		{
			readAbstractMessage();
			var flagsArray:Array = readMessageFlags();

			for ( var i:uint = 0; i < flagsArray.length; i++ )
			{
				var flags:uint = flagsArray[ i ] as uint;
				var reservedPosition:uint = 0;

				if ( i == 0 )
				{
					// TODO: RISK here: readObject, without using amf3parser - could lose a string/trait reference.
					if (( flags & CORRELATION_ID_FLAG ) != 0 )
						object.addProperty( new Amf3Object( "correlationId", "String", input.readObject() as String ));

					if (( flags & CORRELATION_ID_BYTES_FLAG ) != 0 )
					{
						var correlationIdBytes:ByteArray = input.readObject() as ByteArray;
						var correlationId:String = RPCUIDUtil.fromByteArray( correlationIdBytes );
						object.addProperty( new Amf3Object( "correlationId", "String", correlationId ));
					}
					reservedPosition = 2;
				}

				// For forwards compatibility, read in any other flagged objects
				// to preserve the integrity of the input stream...
				if (( flags >> reservedPosition ) != 0 )
				{
					for ( var j:uint = reservedPosition; j < 6; j++ )
					{
						if ((( flags >> j ) & 1 ) != 0 )
						{
							// forwards compatability? I don't think i care about this.  readObject
							// just to keep the bytes in sync - i'm not going to meta-deserialize
							input.readObject();
						}
					}
				}
			}
		}

		private function readAbstractMessage():void
		{
			var flagsArray:Array = readMessageFlags();

			for ( var i:uint = 0; i < flagsArray.length; i++ )
			{
				var flags:uint = flagsArray[ i ] as uint;
				var reservedPosition:uint = 0;
				// TODO - AMF3Parser should just be IDataInput, cast unnecessary
				var amf3Parser:Amf3Parser = new Amf3Parser( input as ByteArray );
				amf3Parser.setReferences( objectReferences, stringReferences, traitsReferences );

				if ( i == 0 )
				{
					if (( flags & BODY_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "body" ));
					else
					{
						var o:Amf3Object = new Amf3Object( "body", "null", "null" );
						// default body is {} so need to set it here
						object.addProperty( o );
					}

					if (( flags & CLIENT_ID_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "clientId" ));

					if (( flags & DESTINATION_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "destination" ));

					if (( flags & HEADERS_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "headers" ));

					if (( flags & MESSAGE_ID_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "messageId" ));

					if (( flags & TIMESTAMP_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "timestamp" ));

					if (( flags & TIME_TO_LIVE_FLAG ) != 0 )
						object.addProperty( amf3Parser.readObject( "timeToLive" ));
					reservedPosition = 7;
				}
				else if ( i == 1 )
				{
					if (( flags & CLIENT_ID_BYTES_FLAG ) != 0 )
					{
						var clientIdBytes:ByteArray = input.readObject() as ByteArray;
						var clientId:String = RPCUIDUtil.fromByteArray( clientIdBytes );
						object.addProperty( new Amf3Object( "clientId", "String", clientId ));
					}

					if (( flags & MESSAGE_ID_BYTES_FLAG ) != 0 )
					{
						var messageIdBytes:ByteArray = input.readObject() as ByteArray;
						var messageId:String = RPCUIDUtil.fromByteArray( messageIdBytes );
						object.addProperty( new Amf3Object( "messageId", "String", messageId ));
					}
					reservedPosition = 2;
				}

				// For forwards compatibility, read in any other flagged objects to
				// preserve the integrity of the input stream...
				if (( flags >> reservedPosition ) != 0 )
				{
					for ( var j:uint = reservedPosition; j < 6; j++ )
					{
						if ((( flags >> j ) & 1 ) != 0 )
						{
							// forwards compatability? I don't think i care about this.  readObject
							// just to keep the bytes in sync - i'm not going to meta-deserialize
							input.readObject();
						}
					}
				}
			}
		}

		// this is a direct gank of readFlags() on AbstractMessage.as
		private function readMessageFlags():Array
		{
			var hasNextFlag:Boolean = true;
			var flagsArray:Array = [];

			while ( hasNextFlag && input.bytesAvailable > 0 )
			{
				var flags:uint = input.readUnsignedByte();
				flagsArray.push( flags );

				if (( flags & HAS_NEXT_FLAG ) != 0 )
					hasNextFlag = true;
				else
					hasNextFlag = false;
			}
			return flagsArray;
		}

		public function setReferences( objectReferences:Array, stringReferences:Array, traitsReferences:Array ):void
		{
			this.objectReferences = objectReferences;
			this.stringReferences = stringReferences;
			this.traitsReferences = traitsReferences;
		}
	}
}
