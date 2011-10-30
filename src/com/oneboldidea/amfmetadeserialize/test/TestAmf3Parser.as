package com.oneboldidea.amfmetadeserialize.test
{
	import com.oneboldidea.amfmetadeserialize.Amf3Parser;
	import com.oneboldidea.amfmetadeserialize.data.Amf3Object;
	import com.oneboldidea.amfmetadeserialize.test.data.UserTO;
	import flash.utils.ByteArray;
	import flexunit.framework.Assert;
	import mx.collections.ArrayCollection;

	public class TestAmf3Parser
	{
		private var byte:ByteArray;

		[Before]
		public function setUp():void
		{
			var child:UserTO = new UserTO( "Andy", "Smith", 7, 52.4, true, null, [ "Buster" ], new Date( 2003,
																										 05,
																										 22 ));
			var child2:UserTO = new UserTO( "Becky", "Smith", -9, NaN, true, null, null, new Date( 2001,
																								   04,
																								   20 ));
			var child3:UserTO = new UserTO( "Claude", null, 12, 100, false, null, null, null );
			var child4:UserTO = new UserTO( "Dennis", "Smith", 17, 156.4, true, null, [ "Goldie", "Bowser" ],
											new Date( 1993, 09, 4 ));
			var parent:UserTO = new UserTO( "Judy", "Smith", 40, 120.8, true, new ArrayCollection([ child, child2, child3, child4 ]),
											[ "Weeble", "Wobble" ], new Date( 1972, 05, 14 ));
			byte = new ByteArray();
			byte.writeObject( parent );
			byte.position = 0;
		}

		[After]
		public function tearDown():void
		{
		}

		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}

		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}

		[Test]
		public function testParser():void
		{
			var parser:Amf3Parser = new Amf3Parser( byte );
			var result:Amf3Object = parser.readObject( "result" );
			Assert.assertEquals( true, true );
		}

		[Test]
		public function testParser2():void
		{
			var parser:Amf3Parser = new Amf3Parser( byte );
			var result:Amf3Object = parser.readObject( "result" );
			Assert.assertEquals( true, true );
		}

		[Test]
		public function testParser3():void
		{
			var parser:Amf3Parser = new Amf3Parser( byte );
			var result:Amf3Object = parser.readObject( "result" );
			Assert.assertEquals( true, true );
		}

		[Test]
		public function testParser4():void
		{
			var parser:Amf3Parser = new Amf3Parser( byte );
			var result:Amf3Object = parser.readObject( "result" );
			Assert.assertEquals( true, true );
		}
	}
}
