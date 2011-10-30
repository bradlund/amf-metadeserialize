package com.oneboldidea.amfmetadeserialize.data
{
	import mx.collections.ArrayCollection;

	public class Amf3Object
	{
		public function Amf3Object( propertyName:String = null, className:String = null, propertyValue:* = null )
		{
			this.propertyName = propertyName;
			this.className = className;
			this.propertyValue = propertyValue;
		}

		public var className:String;

		public var propertyName:String;

		public var propertyValue:*;

		public var propertyValueString:String;

		public var properties:Array;

		public function addProperty( property:Amf3Object ):void
		{
			if ( !properties )
				properties = [];
			properties.push( property );
		}
	}
}
