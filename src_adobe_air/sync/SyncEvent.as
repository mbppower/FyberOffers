package admin.sync {
	import flash.events.Event;
	import mx.collections.ArrayCollection;

	public class SyncEvent extends Event {

		public static const SUBSCRIBE_SENT:String = "SUBSCRIBE_SENT";
		public static const SUBSCRIBE_SEND:String = "SUBSCRIBE_SEND";

		public static const STAT_PRODUTO_SENT:String = "STAT_PRODUTO_SENT";
		public static const STAT_PRODUTO_SEND:String = "STAT_PRODUTO_SEND";

		public static const STAT_SCREENSAVER_SENT:String = "STAT_SCREENSAVER_SENT";
		public static const STAT_SCREENSAVER_SEND:String = "STAT_SCREENSAVER_SEND";

		public static const SYNC:String = "SYNC";
		public static const SYNC_ALL:String = "SYNC_ALL";

		public static const START:String = "START";
		public static const RESTART:String = "RESTART";
		public static const PAUSE:String = "PAUSE";
		public static const CANCEL:String = "CANCEL";
		public static const INIT:String = "INIT";
		public static const READY:String = "READY";
		public static const STEP_INIT:String = "STEP_INIT";
		public static const STEP_COMPLETE:String = "STEP_COMPLETE";
		public static const STEP_ERROR:String = "STEP_ERROR";
		public static const NEXT_STEP:String = "NEXT_STEP";
		public static const PROGRESS:String = "PROGRESS";
		public static const COMPLETE:String = "COMPLETE";
		public static const ERROR:String = "ERROR";
		public static const DEBUG:String = "DEBUG";

		public var data;
		public var text;

		public function SyncEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false, text:String = ""):void {
			this.data = data;
			this.text = text;
			super(type, bubbles, cancelable);
		}
	}
}
