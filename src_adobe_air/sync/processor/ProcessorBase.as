package admin.sync.processor {
	import admin.app.App;
	import admin.files.FileDownloader;
	import admin.sync.SyncEvent;

	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;

	public class ProcessorBase extends EventDispatcher {

		protected var table:String;
		protected var currentItem:int;
		protected var _itemList:Object;
		protected var _itemListLength:uint;
		protected var db:SQLRunner;
		protected var dbPath:String;
		protected var errorDispatched:Boolean = false;
		protected var _processFunction:Function;
		protected var stmList:Vector.<QueuedStatement>;
		private var processStepTimer:Timer = new Timer(50, 1);
		private var downloadsComplete:int = 0;
		private var databaseSyncFrequency:int = 200; //data will be persisted every X steps

		public function ProcessorBase(dbP:String, items, itemListLength:uint, tableName:String) {
			dbPath = dbP;
			db = Database.getInstance();
			table = tableName;
			_itemList = items;
			_itemListLength = itemListLength;
			stmList = new Vector.<QueuedStatement>();
			currentItem = 0;
			processStepTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onProcessStepTimer);
		}

		public function init() {
			stmList = new Vector.<QueuedStatement>();
			process();
		}

		private function isQueueCompleted():Boolean {
			return currentItem >= _itemListLength - 1;
		}

		private function onComplete() {
			dispatchEvent(new SyncEvent(SyncEvent.COMPLETE));
		}

		private function onProgress() {
			dispatchEvent(new SyncEvent(SyncEvent.PROGRESS, {progress: (currentItem / Math.max(1, _itemListLength - 1)) * 100}));
		}

		//process next
		private function onProcessStepTimer(e:TimerEvent) {
			processStepTimer.reset();
			if(stmList.length > 0) {
				//execute batch
				db.executeModify(stmList, function(rs:Vector.<SQLResult>) {

					//progress
					onProgress();

					if(isQueueCompleted()) {
						onComplete();
					}
					else {
						process();
					}
				}, onResultError);
			}
			else {
				onComplete();
			}
		}

		protected function next():void {
			if(isQueueCompleted()) {
				processStepTimer.start();
			}
			else {
				if(currentItem % databaseSyncFrequency == 0) {
					processStepTimer.start();
				}
				else {
					process();
				}
			}
		}

		protected function process() {
			var item:Object = _itemList[currentItem];

			if(item.removed == "1") {
				stmList.push(new QueuedStatement("DELETE FROM " + table + " WHERE id = :id", {"id": +item.id}));
				onStepComplete();
			}
			else {
				_processFunction(false, item);
			}
		}

		protected function onResultError(e:SQLError):void {
			App.debug("ProcessorBase.onResultError - table: " + table + " currentItem: " + currentItem, e);
			if(errorDispatched)
				return;
			errorDispatched = true;
			dispatchEvent(new SyncEvent(SyncEvent.ERROR, {error: e.getStackTrace() + "table: " + table + " currentItem: " + currentItem}));
		}

		protected function debug(message:String):void {
			dispatchEvent(new SyncEvent(SyncEvent.DEBUG, {message: message + " table: " + table + " currentItem: " + currentItem}));
		}

		protected function onStepComplete() {
			if(errorDispatched)
				return;

			//process next
			currentItem++;
			next();
		}

		protected function processFile(table:String, file:String, hash:String):void {

			//the file name is the MD5Checksum
			var filePath:String = FileDownloader.DOWNLOAD_DIR_NAME + "/" + table + "/" + hash + file.substr(file.lastIndexOf("."));

			var fileQueueInsert:QueuedStatement = new QueuedStatement("INSERT OR IGNORE INTO files_queue (remote_url, hash, local_path, date) VALUES (:remote_url, :hash, :local_path, :date)",
				{remote_url: file,
					hash: hash, local_path: filePath, date: new Date()});
			var fileInsert:QueuedStatement = new QueuedStatement("INSERT OR IGNORE INTO files (path, hash, ready) VALUES (:path, :hash, 0)", {path: filePath,
					hash: hash});

			stmList.push(fileQueueInsert);
			stmList.push(fileInsert);
		}
	}
}
