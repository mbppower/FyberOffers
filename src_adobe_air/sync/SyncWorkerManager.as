package admin.sync {
	import admin.app.App;
	import admin.app.AppMode;
	import admin.app.Screensaver;
	import admin.files.DownloadWorkerManager;
	import admin.model.Config;
	import admin.senddata.SendDataManager;

	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.utils.ByteArray;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	import webservice.WsClient;

	import workerHelper.WorkerHolderBase;

	public class SyncWorkerManager extends EventDispatcher {

		private var syncWorker:SyncWorker;

		private static var _instance:SyncWorkerManager;
		protected var db:SQLRunner = Database.getInstance();

		public static const WORKER_READY = "WORKER_READY";
		private var _isReady:Boolean = false;
		private var startRequested:Boolean = false;
		private var _isScheduled:Boolean = false;

		public function set isScheduled(value:Boolean):void {
			_isScheduled = value;
		}

		public function get isReady():Boolean {
			return _isReady;
		}

		public static function get instance():SyncWorkerManager {
			if(!_instance) {
				_instance = new SyncWorkerManager();
			}
			return _instance;
		}

		public function SyncWorkerManager() {
			syncWorker = new SyncWorker();

			syncWorker.addEventListener(SyncEvent.READY, determineCommand);
			syncWorker.addEventListener(SyncEvent.INIT, determineCommand);
			syncWorker.addEventListener(SyncEvent.STEP_INIT, determineCommand);
			syncWorker.addEventListener(SyncEvent.STEP_COMPLETE, determineCommand);
			syncWorker.addEventListener(SyncEvent.STEP_ERROR, determineCommand);
			syncWorker.addEventListener(SyncEvent.COMPLETE, determineCommand);
			syncWorker.addEventListener(SyncEvent.PROGRESS, determineCommand);
		}

		public function sync(itemToSync:String = null, ignoreLastUpdate = false) {

			if(!IFeet.CAN_SYNC) {
				trace("App update required, cannot sync");
				return;
			}

			if(AppMode.SYNC_STATUS == AppMode.SYNC_RUNNING) {
				trace("The syncing is already in progress");
				return;
			}
			trace("SyncWorkerManager.sync()");
			getTableList(function(tableList:Array) {
				//set worker params
				syncWorker.sync(tableList, itemToSync, ignoreLastUpdate);
			});

		}

		public function currentStep():Object {
			return syncWorker.currentStep();
		}

		private function nextStep() {
			syncWorker.nextStep();
		}

		public function getTableList(callback:Function):void {
			db.execute("SELECT table_name, ws_method, label, last_update, [order] FROM sync ORDER BY [order]", null, function(rs:SQLResult) {
				callback(rs.data);
			}, null, onResultError);
		}

		protected function determineCommand(e:SyncEvent) {
			var command:String = e.type;
			switch(command) {
				case SyncEvent.READY:  {
					_isReady = true;
					dispatchEvent(new SyncEvent(command));
					break;
				}
				case SyncEvent.INIT:  {
					AppMode.SYNC_STATUS = AppMode.SYNC_RUNNING;
					dispatchEvent(new SyncEvent(command));
					break;
				}
				case SyncEvent.STEP_INIT:  {
					var item:Object = e.data.item;
					dispatchEvent(new SyncEvent(command, item));
					break;
				}
				case SyncEvent.STEP_COMPLETE:  {
					var item:Object = e.data.item;
					db.execute("SELECT * FROM sync WHERE table_name = :table_name", {"table_name": item.table_name}, function(rs:SQLResult) {
						var result:Array = rs.data;
						dispatchEvent(new SyncEvent(command, result ? result[0] : item));
						nextStep();
					}, null, onResultError);
					break;
				}
				case SyncEvent.STEP_ERROR:  {
					App.debug("SyncWorkerManager.processWSProduct", e);
					var item:Object = e.data.item;
					dispatchEvent(new SyncEvent(command, item));
					nextStep();
					break;
				}
				case SyncEvent.PROGRESS:  {
					var item:Object = e.data.item;
					dispatchEvent(new SyncEvent(command, {
							"table_name": item.table_name,
							"processor": e.data.progress,
							"processorProgress": e.data.processorProgress
						}));
					break;
				}
				case SyncEvent.COMPLETE:  {
					//sync complete
					AppMode.SYNC_STATUS = AppMode.SYNC_NOT_RUNNING;

					//Envia cadastros
					if(_isScheduled) {
						trace("isScheduled send data");

						SendDataManager.instance.addEventListener(SyncEvent.COMPLETE, completeScheduleSend);
						SendDataManager.instance.send();
					}
					else {
						//donwload files
						DownloadWorkerManager.instance.start();
					}

					dispatchEvent(new SyncEvent(command, e.data));
					break;
				}
				default:  {
					break;
				}
			}
		}

		private function onResultError(e:SQLError):void {
			App.debug("SyncWorkerManager.onResultError", e);
			dispatchEvent(new SyncEvent(SyncEvent.STEP_ERROR));
		}

		private function completeScheduleSend(e:SyncEvent):void {
			SendDataManager.instance.removeEventListener(SyncEvent.COMPLETE, completeScheduleSend);
			trace("isScheduled send data complete, start download");

			//donwload files
			DownloadWorkerManager.instance.start();
			_isScheduled = false;
		}
	}
}
