package admin.sync {
	import admin.app.App;
	import admin.model.Config;
	import admin.senddata.SendDataManager;

	import com.adobe.utils.StringUtil;
	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.globalization.DateTimeFormatter;
	import flash.globalization.LocaleID;
	import flash.net.NetworkInfo;
	import flash.utils.Timer;

	import mx.collections.ArrayCollection;
	import mx.rpc.events.ResultEvent;
	import mx.utils.UIDUtil;

	import updater.ClientUpdater;

	import webservice.SOAPCall;
	import webservice.WsClient;

	public class SyncManager extends EventDispatcher {

		private var ws:SOAPCall;

		private static var _instance:SyncManager;
		private static var timer:Timer;

		public static var nextSync:Date;

		public static function get instance():SyncManager {
			if(!_instance) {
				_instance = new SyncManager();
			}
			return _instance;
		}

		public function init():void {
			//init
			var d:Date = App.config.data["sync_time"];
			var minutes:uint = Math.min(60, Math.max(1, +App.config.data["auto_sync_interval"]));
			var cDate:Date = new Date();
			nextSync = new Date();
			nextSync.hours = d.hours;
			nextSync.minutes = d.minutes;

			trace("SyncManager.init()");

			//sync timer interval
			timer = new Timer(1000 * 60 * minutes); //minutes
			timer.addEventListener(TimerEvent.TIMER, checkUpdate);
			timer.start();
		}

		private function checkUpdate(evt:TimerEvent = null):void {
			//Verifica se há requisição de atualizações no servidor
			WsClient.callMethod("autoSync", [Config.instance.getToken()], returnCheckUpdate);
			//Verifica atualização automática
			instance.scheduleSync();
		}

		private function scheduleSync():void {
			//Sincronização agendada
			var cDate:Date = new Date();
			trace("SyncManager.scheduleSync()", cDate, nextSync);
			if(cDate > nextSync) {

				//procura versões mais recentes
				ClientUpdater.instance.checkForUpdate();

				//Sincroniza tabelas
				SyncWorkerManager.instance.isScheduled = true;
				SyncWorkerManager.instance.sync();

				//Adiciona 1 dia para proxima atualização
				nextSync.date += 1;
			}
		}

		public function updateAppConfig(callback:Function) {
			var networkInterface:Object = NetworkInfo.networkInfo.findInterfaces();
			WsClient.callMethod("initClient", [networkInterface[0].hardwareAddress.toString(), Config.instance.getToken()], function(e:ResultEvent):void {
				var data:Object = e.result;
				var isActive:Boolean = false;
				if(data.result && data.code == 1) {
					Config.instance.update(data, function() {
						isActive = true;
						callback(isActive);
					});
				}
				else {
					callback(isActive);
				}
			});
		}

		//auto sync
		private static function returnCheckUpdate(evt:ResultEvent):void {
			trace("SyncManager.returnCheckUpdate", evt.result);
			if(App.config.data["auto_sync_last"] >= evt.result) {
				return;
			}
			else {
				App.config.data["auto_sync_last"] = evt.result;
				Database.getInstance().executeModify(Vector.<QueuedStatement>([new QueuedStatement("UPDATE config SET auto_sync_last = :auto_sync_last", {"auto_sync_last": evt.result})]), function(results:Vector.<SQLResult>) {
					SyncWorkerManager.instance.sync();
				}, instance.onResultError);
			}
		}

		private function onResultError(e:SQLError) {
			App.debug("SyncManager.onResultError", e);
		}

	}
}
