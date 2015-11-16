package admin.sync {
	import admin.app.App;
	import admin.model.Config;
	import admin.sync.processor.DataProcessor;
	import admin.sync.processor.ProductProcessor;

	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.display.Sprite;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.text.ReturnKeyLabel;
	import flash.utils.Timer;

	import mx.collections.ArrayCollection;
	import mx.rpc.events.ResultEvent;
	import mx.utils.UIDUtil;

	import webservice.SOAPCall;
	import webservice.WsClient;

	import workerHelper.WorkerBase;

	public class SyncWorker extends EventDispatcher {

		private var _tableList:Array;
		private var syncList:Array;
		private var _ignoreLastUpdate:Boolean = false;
		private var currentIndex:int = -1;
		private var progressStep:Number;
		private var progressCurrent:Number;

		private var ws:SOAPCall;
		private var db:SQLRunner;
		private var token:String = null;
		private var dbPath:String;
		private var processStepTimer:Timer = new Timer(50, 1);

		public function SyncWorker() {
			ws = new SOAPCall(WsClient.getWebServiceURL());
			db = Database.getInstance();
			processStepTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onProcessStepTimer);
			dispatchEvent(new SyncEvent(SyncEvent.READY));
		}

		private function initStep():void {
			processStepTimer.start();
		}

		private function onProcessStepTimer(e:TimerEvent) {
			processStepTimer.reset();
			var currentItem:Object = syncList[currentIndex];
			dispatchEvent(new SyncEvent(SyncEvent.STEP_INIT, {"item": currentItem}));

			var dtf = new DateTimeFormatter(LocaleID.DEFAULT);
			dtf.setDateTimePattern("yyyy-MM-dd'T'HH:mm:ss");

			var dt:String = (_ignoreLastUpdate || !currentItem.last_update ? null : dtf.format(currentItem.last_update));
			var params:Array = [token, dt];

			if(currentItem.table_name == "produto") {
				ws.callMethod(currentItem.ws_method, params, processWSProduct, onSyncStepError, "e4x");
			}
			else {
				ws.callMethod(currentItem.ws_method, params, processWSData, onSyncStepError);
			}
		}

		public function currentStep():Object {
			return currentIndex > -1 ? syncList[currentIndex] : null;
		}

		private function onSyncStepComplete(lastUpdate, table):void {
			var sql:String = "UPDATE sync SET last_update = :last_update WHERE table_name = :table_name";
			var params:Object = {"last_update": lastUpdate, "table_name": table};
			db.executeModify(Vector.<QueuedStatement>([new QueuedStatement(sql, params)]), function(results:Vector.<SQLResult>) {
				dispatchEvent(new SyncEvent(SyncEvent.STEP_COMPLETE, {"item": syncList[currentIndex]}));
			}, onResultError);
		}

		private function onSyncStepError(e:* = null):void {
			App.debug("SyncWorker.onSyncStepError", e);
			onProgress(progressStep, 0);
			dispatchEvent(new SyncEvent(SyncEvent.STEP_ERROR, {"item": syncList[currentIndex]}));
		}

		public function nextStep():void {
			if(currentIndex == syncList.length - 1) {
				currentIndex = -1;
				onSyncComplete();
			}
			else {
				currentIndex++;
				initStep();
			}
		}

		private function onProgress(step:Number, processorProgress:Number):void {
			progressCurrent += step;

			//notify main worker
			dispatchEvent(new SyncEvent(SyncEvent.PROGRESS, {"item": syncList[currentIndex], "progress": progressCurrent, "processorProgress": processorProgress}));
		}

		private function onError():void {
			trace("SyncWorker.onError()");
			onSyncStepError();
		}

		private function onResultError(e:SQLError):void {
			App.debug("SyncWorker.onResultError", e);
			onError();
		}

		private function processWSData(evt:ResultEvent):void {
			try {
				var table:String = syncList[currentIndex].table_name;
				var data:Object = evt.result[table];

				if(!data) {
					onError();
					return;
				}

				//parse
				var items = data.item ? (data.item.length ? data.item : new ArrayCollection([data.item])) : null;

				if(items && items.length > 0) {

					//start processor
					var processor:DataProcessor = new DataProcessor(dbPath, items, table);
					processor.addEventListener(SyncEvent.COMPLETE, function() {
						onSyncStepComplete(data.lastUpdate, table);
					});
					processor.addEventListener(SyncEvent.ERROR, function(e:SyncEvent) {
						App.debug("SyncWorker.processWSData", e);
						onSyncStepError();
					});
					processor.addEventListener(SyncEvent.DEBUG, function(e:SyncEvent) {
						trace("DEBUG: " + e.data.message);
					});
					processor.addEventListener(SyncEvent.PROGRESS, function(e:SyncEvent) {
						onProgress(progressStep / Math.max(1, processor.itemList.length), e.data.progress);
					});
					processor.init();
				}
				else {
					//nothing to update
					onProgress(progressStep, 100);
					onSyncStepComplete(data.lastUpdate, table);
				}
			}
			catch(e:Error) {
				App.debug("SyncWorker.processWSData", e);
				onError();
			}
		}

		private function processWSProduct(evt:ResultEvent):void {
			try {
				var table:String = syncList[currentIndex].table_name;
				var data:XMLList = Utils.removeNamespace(XML(evt.result)).getProdutosResult.produto;

				if(!data) {
					onError();
					return;
				}

				//parse
				var items:XMLList = data.item;
				if(items && items.length() > 0) {

					//start processor
					var processor:ProductProcessor = new ProductProcessor(dbPath, items, table);
					processor.addEventListener(SyncEvent.COMPLETE, function() {
						onSyncStepComplete(data.@lastUpdate, table);
					});
					processor.addEventListener(SyncEvent.ERROR, function(e:SyncEvent) {
						App.debug("SyncWorker.processWSProduct", e);
						onSyncStepError();
					});
					processor.addEventListener(SyncEvent.DEBUG, function(e:SyncEvent) {
						trace("DEBUG: " + e.data.message);
					});
					processor.addEventListener(SyncEvent.PROGRESS, function(e:SyncEvent) {
						onProgress(progressStep / Math.max(1, processor.itemList.length()), e.data.progress);
					});
					processor.init();
				}
				else {
					//nothing to update
					onProgress(progressStep, 100);
					onSyncStepComplete(data.@lastUpdate, table);
				}
			}
			catch(e:Error) {
				App.debug("SyncWorker.processWSProduct", e);
				onError();
			}
		}

		private function onSyncComplete() {
			dispatchEvent(new SyncEvent(SyncEvent.COMPLETE, {"totalCompletedItems": syncList.length}));
		}

		public function getInfo(table:String):Object {
			for each(var t:Object in _tableList)
				if(t.table_name == table)
					return t;

			return null;
		}

		public function sync(tableList:Array, itemToSync:String = null, ignoreLastUpdate:Boolean = false):void {
			token = Config.instance.getToken();
			if(!token) {
				trace("SyncWorker Error: Invalid token");
				return;
			}
			_ignoreLastUpdate = ignoreLastUpdate;
			_tableList = tableList;

			syncList = itemToSync ? new Array(getInfo(itemToSync)) : _tableList;

			currentIndex = 0;
			progressCurrent = 0;
			progressStep = 100 / syncList.length;

			//notify main worker
			dispatchEvent(new SyncEvent(SyncEvent.INIT));

			initStep();
		}
	}
}
