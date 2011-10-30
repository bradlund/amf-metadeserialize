package com.oneboldidea.amfmetadeserialize
{
	import flash.utils.ByteArray;

	public class TestAmf3ParserOverride extends Amf3Parser
	{
		public function TestAmf3ParserOverride( byteArray:ByteArray = null )
		{
			super( byteArray );
		}

		public function publicReadUint29():int
		{
			return readUint29();
		}
	}
}
