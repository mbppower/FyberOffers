package content.search {
	import flash.events.Event;
	import mx.collections.ArrayCollection;

	public class SearchEvent extends Event {

		public static const SELECT_ITEM:String = "SELECT_ITEM";
		public static const UPDATE_SEARCH:String = "UPDATE_SEARCH";

		public var data;

		public function SearchEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false):void {
			this.data = data;
			super(type, bubbles, cancelable);
		}
	}
}
