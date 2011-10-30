package com.oneboldidea.amfmetadeserialize
{
	import com.oneboldidea.amfmetadeserialize.data.Amf3ByteStreamInfo;
	import com.oneboldidea.amfmetadeserialize.data.Amf3Object;
	import flash.utils.ByteArray;
	import mx.messaging.messages.IMessage;

	public class Amf3ByteStreamParser
	{
		protected var _byteArray:ByteArray;

		public function Amf3ByteStreamParser( byteArray:ByteArray = null )
		{
			this.byteArray = byteArray;
		}

		public function get byteArray():ByteArray
		{
			return _byteArray;
		}

		public function set byteArray( value:ByteArray ):void
		{
			_byteArray = value;
		}

		public function readStream():Amf3ByteStreamInfo
		{
			// let's just say that this method can be improved upon.
			for ( var i:int = 0; i < byteArray.length; i++ )
			{
				byteArray.position = i;
				var amf3parser:Amf3Parser = new Amf3Parser( byteArray );

				try
				{
					var result:Amf3Object = amf3parser.readObject( "result" );
				}
				catch ( er:Error )
				{
					// dunno if i care about anything here.
				}

				if ( result && result.className && result.className.indexOf( "Message" ) >= 0 )
				{
					return new Amf3ByteStreamInfo( result, amf3parser.getTraitsReferences());
				}
			}
			return null;
		}
	}
}
