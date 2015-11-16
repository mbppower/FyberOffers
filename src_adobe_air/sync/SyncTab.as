package admin.sync {
	import admin.app.App;
	import admin.app.AppMode;

	import controls.CheckBox;
	import controls.scroll.ComplexScroll;
	import controls.scroll.Scroll;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.text.TextField;

	public class SyncTab extends MovieClip {
		public var btSyncAll:SyncButton;
		public var txtUpdateTime:TextField;
		public var txtStatus:TextField;
		private var itensContainer:MovieClip;
		public var btTab:MovieClip;
		public var ignoreLastUpdate:CheckBox;

		public function SyncTab() {

			var dtf:DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT);
			dtf.setDateTimePattern("dd/MM/yyyy HH:mm");
			txtUpdateTime.text = dtf.format(SyncManager.nextSync);
			itensContainer = new MovieClip();
			itensContainer.x = 87;
			itensContainer.y = 178;
			addChild(itensContainer);

			SyncWorkerManager.instance.getTableList(buildTableList);
			SyncWorkerManager.instance.addEventListener(SyncEvent.STEP_INIT, onStepInit);
			SyncWorkerManager.instance.addEventListener(SyncEvent.STEP_COMPLETE, onStepComplete);
			SyncWorkerManager.instance.addEventListener(SyncEvent.STEP_ERROR, onStepError);
			SyncWorkerManager.instance.addEventListener(SyncEvent.PROGRESS, onProgress);
			SyncWorkerManager.instance.addEventListener(SyncEvent.COMPLETE, onComplete);

			btSyncAll.addEventListener(MouseEvent.CLICK, startSync);
		}

		private function buildTableList(tableList:Array) {
			var item:SyncItem;
			var count:int = 0;
			var currentStep = SyncWorkerManager.instance.currentStep();
			var currentStepTable = currentStep ? currentStep.table_name : "";

			for each(var i:Object in tableList) {
				item = new SyncItem(i, ++count, count % 2 == 0);
				item.name = i.table_name;
				item.working = currentStepTable == item.name;
				item.y = itensContainer.height;
				item.btSync.addEventListener(MouseEvent.CLICK, startSyncItem);
				itensContainer.addChild(item);
			}
			setScrollBar(itensContainer);
		}

		private function setScrollBar(container:MovieClip):void {
			var maxHeight:int = 700;
			var scroller:ComplexScroll;
			var scrollBar:Scroll = new Scroll();
			scrollBar.y = container.y;
			scrollBar.x = 900;
			scrollBar.bar.height = maxHeight - scrollBar.y;
			scroller = new ComplexScroll(scrollBar, container, true, true);
			scroller.init();
			addChild(scrollBar);
		}

		protected function onProgress(evt:SyncEvent):void {
			var item:SyncItem = itensContainer.getChildByName(evt.data.table_name) as SyncItem;
			item.progress = evt.data.processorProgress;
		}

		private function onComplete(evt:SyncEvent):void {
			trace("SyncTab.onComplete()");
			itensContainer.mouseChildren = true;
			btSyncAll.ready();
		}

		private function onStepInit(evt:SyncEvent):void {
			var item:SyncItem = itensContainer.getChildByName(evt.data.table_name) as SyncItem;
			item.working = true;
			item.progress = 0;
		}

		private function onStepComplete(evt:SyncEvent):void {
			var item:SyncItem = itensContainer.getChildByName(evt.data.table_name) as SyncItem;
			item.working = false;
			item.info = evt.data;
			item.update();
		}

		private function onStepError(evt:SyncEvent):void {
			App.debug("SyncTab.onStepError", evt);
			var item:SyncItem = itensContainer.getChildByName(evt.data.table_name) as SyncItem;
			item.failed();
			item.update();
		}

		private function startSyncItem(evt:MouseEvent):void {
			var item:SyncItem = evt.currentTarget.parent;
			trace("startSyncItem", item.info.table_name, ignoreLastUpdate.checked);

			if(!item.working)
				SyncWorkerManager.instance.sync(item.info.table_name, ignoreLastUpdate.checked);
		}

		private function startSync(evt:MouseEvent):void {
			if(!IFeet.CAN_SYNC || AppMode.SYNC_STATUS == AppMode.SYNC_RUNNING)
				return;

			itensContainer.mouseChildren = false;
			btSyncAll.working();
			trace("startSync ---------------------------------");
			SyncWorkerManager.instance.sync(null, ignoreLastUpdate.checked);
		}
	}
}
