package com.oneboldidea.amfmetadeserialize.data
{

	public class Amf3ByteStreamInfo
	{
		public function Amf3ByteStreamInfo( amf3Object:Amf3Object, traits:Array )
		{
			this.amf3Object = amf3Object;
			this.traits = traits;
		}

		public var amf3Object:Amf3Object;

		public var traits:Array;
	}
}
