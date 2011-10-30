package com.oneboldidea.amfmetadeserialize.test.data
{
	import mx.collections.ArrayCollection;

	[RemoteClass( alias = "com.oneboldidea.amfmetadeserialize.test.data.UserTO" )]
	public class UserTO
	{
		public function UserTO( firstName:String = null, lastName:String = null, age:int = 0, weight:Number = NaN, isHappy:Boolean = false, children:ArrayCollection = null, petNames:Array = null, birthday:Date = null )
		{
			this.firstName = firstName;
			this.lastName = lastName;
			this.age = age;
			this.weight = weight;
			this.isHappy = isHappy;
			this.children = children;
			this.petNames = petNames;
			this.birthday = birthday;
		}

		public var firstName:String;

		public var lastName:String;

		public var age:int;

		public var weight:Number;

		public var isHappy:Boolean;

		public var children:ArrayCollection;

		public var petNames:Array;

		public var birthday:Date;
	}
}
