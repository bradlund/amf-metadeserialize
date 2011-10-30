package com.oneboldidea.amfmetadeserialize
{

	/**
	 * These are the marker types used by AMF to indicate what the next
	 * object will be.
	 *
	 * @author brad.lund
	 *
	 */
	internal class Amf3MarkerTypes
	{
		/** Direct from Section 3.1 of the AMF spec */
		public static const UNDEFINED:int = 0x00;

		public static const NULL:int = 0x01;

		public static const FALSE:int = 0x02;

		public static const TRUE:int = 0x03;

		public static const INTEGER:int = 0x04;

		public static const DOUBLE:int = 0x05;

		public static const String:int = 0x06;

		public static const XMLDOC:int = 0x07;

		public static const DATE:int = 0x08;

		public static const ARRAY:int = 0x09;

		public static const OBJECT:int = 0x0A;

		public static const XML:int = 0x0B;

		public static const BYTEARRAY:int = 0x0C;
	}
}
