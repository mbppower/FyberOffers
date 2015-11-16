package admin.sync {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.text.TextField;

	public class SyncItem extends MovieClip {
		public var txtLabel:TextField;
		public var txtNumber:TextField;
		public var txtPriority:TextField;
		public var txtLastUpdate:TextField;
		public var btSync:SyncButton;
		public var info:Object;
		private var isSyncInProgress:Boolean;
		private var dtf:DateTimeFormatter;

		public function SyncItem(info:Object, number:int, dark:Boolean = true, isSyncInProgress:Boolean = false):void {

			dtf = new DateTimeFormatter(LocaleID.DEFAULT);
			dtf.setDateTimePattern("dd/MM/yyyy HH:mm:ss");

			gotoAndStop(dark ? 1 : 2);
			this.info = info;
			txtNumber.text = number + "";
			txtLabel.text = info.label;
			txtPriority.text = info.order;
			update();

			working = isSyncInProgress;
		}

		public function update():void {
			txtLastUpdate.text = info.last_update ? dtf.format(info.last_update) : "-";
		}

		public function set working(value:Boolean):void {
			isSyncInProgress = value;
			if(isSyncInProgress) {
				btSync.working();
			}
			else {
				btSync.ready();
			}
		}

		public function get working():Boolean {
			return isSyncInProgress
		}

		public function set progress(value:Number):void {
			txtLabel.text = info.label + " (" + Math.ceil(value) + "%)";
		}

		public function failed():void {
			working = false;
			txtLabel.text = info.label + " (ERROR)";
		}
	}
}
