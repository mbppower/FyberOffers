package admin.sync {
	import admin.app.App;
	import admin.app.AppMode;
	import admin.model.Config;

	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.xml.XMLNode;
	import flash.utils.setTimeout;

	public class SyncProductStock {

		private static var _instance:SyncProductStock;
		private var db:SQLRunner;
		private var timer:Timer;
		private var fileStream:FileStream;
		protected var currentItem:uint;
		protected var _itemList:Object;
		protected var _itemListLength:uint;
		private var _filesToProcess:Array;
		private var _currentFile:uint;

		private var _lastReadFileDateTime:Date;

		public static const MILLISECONDS_IN_DAY:Number = 86400000;
		public static const MILLISECONDS_IN_HOUR:Number = 3600000;
		public static const MILLISECONDS_IN_MINUTE:Number = 60000;
		public static const MILLISECONDS_IN_SECOND:Number = 1000;

		public function SyncProductStock() {
			db = Database.getInstance();
			_lastReadFileDateTime = new Date();
			_lastReadFileDateTime.date -= 7;
		}

		private function timeDifference(startTime:Date, endTime:Date, type:String = "d"):Number {
			var aTms = Math.floor(endTime.valueOf() - startTime.valueOf());
			return aTms / (
				type == "d" ? MILLISECONDS_IN_DAY : (
				type == "h" ? MILLISECONDS_IN_HOUR : (
				type == "m" ? MILLISECONDS_IN_MINUTE : (
				type == "s" ? MILLISECONDS_IN_SECOND : 1
				))));
		}

		public static function get instance():SyncProductStock {
			if(!_instance)
				_instance = new SyncProductStock();

			return _instance;
		}

		public function init():void {
			if(timer)
				return;
			timer = new Timer(1000 * 60 * 4) //4 minutes;
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			timer.start();
		}

		protected function onTimer(e:TimerEvent):void {
			if(AppMode.SYNC_STATUS == AppMode.SYNC_RUNNING) {
				trace("The syncing is already in progress");
				return;
			}
			trace("SyncProductStock.onTimer()");
			//status
			AppMode.SYNC_STATUS = AppMode.SYNC_RUNNING;

			//stop timer
			timer.stop();

			//begin update
			update();
		}

		public function update():void {
			var stockFolder:File = null;
			var stockXMLFolder:String = Config.instance.data["stock_folder_path"];
			_lastReadFileDateTime = Config.instance.data["stock_file_last"] ? Config.instance.data["stock_file_last"] : _lastReadFileDateTime;

			//check if folder exists
			if(stockXMLFolder != "") {
				var path:String = stockXMLFolder.replace(/\\/g, "/");
				try {
					stockFolder = new File(path);
				}
				catch(e:Error) {
					App.debug("SyncProductStock.update path:" + path, e);
				}
			}

			if(stockFolder != null) {
				stockFolder.addEventListener(FileListEvent.DIRECTORY_LISTING, function(e:FileListEvent) {
					function compareDate(a:File, b:File) {
						if(a.modificationDate.getTime() > b.modificationDate.getTime()) {
							return 1;
						}
						else if(a.modificationDate.getTime() < b.modificationDate.getTime()) {
							return -1;
						}
						return 0;
					}
					var files:Array = e.files.sort(compareDate);
					_filesToProcess = new Array();
					_currentFile = 0;
					for each(var f:File in files) {
						if(f.extension == "xml") {
							var diff = timeDifference(f.modificationDate, _lastReadFileDateTime); //Retorna a diferença de tempo em dias
							if(diff > 7) //Remove arquivos criados a mais de 7 dias
								f.deleteFile();
							else if(diff < 0) //Adiciona apenas arquivos mais recentes que o ultimo processado 
								_filesToProcess.push(f);
						}
					}
					//begin file process queue
					nextFile();
				});

				if(stockFolder.exists) {
					stockFolder.getDirectoryListingAsync();
				}
				else {
					trace("ProductStockFolder: XML not found");
					onProcessComplete();
				}
			}
			else {
				trace("ProductStockFolder: folder is null");
				onProcessComplete();
			}
		}

		protected function onProcessComplete() {
			//change status
			AppMode.SYNC_STATUS = AppMode.SYNC_NOT_RUNNING;
			//start timer
			timer.start();
		}

		protected function nextFile():void {
			if(_currentFile > _filesToProcess.length - 1) {
				trace("SyncProductStock complete");

				//complete process
				onProcessComplete();
			}
			else {
				trace("SyncProductStock current file: " + _filesToProcess[_currentFile].name);
				fileStream = new FileStream();
				fileStream.addEventListener(Event.COMPLETE, function(e:Event) {
					_lastReadFileDateTime = _filesToProcess[_currentFile].modificationDate;
					_lastReadFileDateTime.milliseconds += 1; // Correção para inserir no banco, aparentemente o sqlite arredonda para baixo perdendo 1 milisegundo.
					
					//update last file read
					db.executeModify(Vector.<QueuedStatement>([new QueuedStatement("UPDATE config SET stock_file_last = :stock_file_last", {stock_file_last: _lastReadFileDateTime})]),
						function(results:Vector.<SQLResult>) {
							var xml:XML = XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
							fileStream.close();
							processXMLData(xml);
							_currentFile++;
						},
						function(e:SQLError) {
							App.debug("SyncProductStock.nextFile() ", e);
							trace("SyncProductStock.nextFile() ", e.getStackTrace());
							//fatal error, restart timer and all process
							onProcessComplete();
						}
					);					
				});
				fileStream.openAsync(_filesToProcess[_currentFile], FileMode.READ);
			}
		}

		private function processXMLData(xml:XML):void {
			//Quando existe a tag web no XML, significa que é o update full com todos os produtos
			//Quando existe a tag pdv no XML, significa que é o update de uma movimentação no caixa da loja
			if(xml.hasOwnProperty("web")) {
				_itemList = xml..web;
				//Remove tudo para inserir os novos valores de estoque
				var sql:String = "DELETE FROM produto_estoque";
				db.executeModify(Vector.<QueuedStatement>([new QueuedStatement(sql)]), function(results:Vector.<SQLResult>) {
					callback();
				}, function(e:SQLError) {
					App.debug("SyncProductStock.processXMLData - currentItem: " + currentItem, e);
					trace("SyncProductStock.processXMLData() fatal error ", e.getStackTrace() + "currentItem: " + currentItem);
					//fatal error, restart timer and all process
					onProcessComplete();
				});
			}
			else {
				_itemList = xml..pdv;
				callback();
			}

			function callback() {
				_itemListLength = _itemList.length();
				if(_itemListLength > 0) {
					currentItem = 0;
					process();
				}
				else {
					onComplete();
				}
			}
		}

		protected function next():void {
			//give time to flash main app
			setTimeout(function(){
				if(currentItem >= _itemListLength - 1) {
					//done	
					onComplete();
				}
				else {
					//process next
					currentItem++;
					process();
				}
			}, 100);
		}

		protected function onResultError(e:SQLError):void {
			App.debug("SyncProductStock.onResultError - currentItem: " + currentItem, e);
			trace(e.getStackTrace() + "currentItem: " + currentItem);
			next();
		}

		protected function onComplete() {
			trace("SyncProductStock file process complete");
			nextFile();
		}

		protected function onStepComplete() {
			next();
		}

		protected function onStepError() {
			trace("Error on currentItem: " + currentItem);
			next();
		}

		private function process():void {

			var item:Object = _itemList[currentItem];
			if(item.hasOwnProperty("sku")) {
				//SKU = PPPPP-PCCCTTT
				var skuProduto:String = item.sku.substring(0, 7); //PPPPP-P
				var skuCor:String = item.sku.substring(7, 10); //CCC
				var skuTamanho:String = item.sku.substring(10, 13); //TTT

				var sql:String = "SELECT pe.id AS id, p.id AS produto_id " +
					"FROM produto p " +
					"LEFT JOIN produto_estoque pe ON pe.produto_id = p.id AND pe.produto_cores_sku = :sku_cor AND  pe.produto_tamanho_sku = :sku_tamanho " +
					"WHERE p.sku = :sku_produto";

				db.execute(sql, {"sku_produto": skuProduto, "sku_cor": skuCor, "sku_tamanho": skuTamanho},
					function(rs:SQLResult) {
						if(rs.data) {
							callback(Number(rs.data[0]["id"]), Number(rs.data[0]["produto_id"]), skuCor, skuTamanho, item);
						}
						else {
							trace("SyncProductStock Item not found: ", skuProduto, skuCor, skuTamanho);
							onStepComplete();
						}
					}, null, function(e:SQLError) {
						App.debug("SyncProductStock.process #1", e);
						trace("Error #1");
						onResultError(e);
					});

				function callback(id:Number, produtoId:Number, skuCor:String, skuTamanho:String, data:Object) {
					var sql:String = id > 0 ?
						"UPDATE produto_estoque SET produto_id = :produto_id, produto_cores_sku = :produto_cores_sku, produto_tamanho_sku = :produto_tamanho_sku, preco = :preco, estoque = :estoque WHERE id = " + id :
						"INSERT INTO produto_estoque (produto_id, produto_cores_sku, produto_tamanho_sku, preco, estoque) VALUES (:produto_id, :produto_cores_sku, :produto_tamanho_sku, :preco, :estoque)";

					var params:Object = {
							"produto_id": produtoId,
							"produto_cores_sku": skuCor,
							"produto_tamanho_sku": skuTamanho,
							"preco": data.preco.toString(),
							"estoque": +data.saldo.toString()
						};

					db.executeModify(Vector.<QueuedStatement>([new QueuedStatement(sql, params)]), function(results:Vector.<SQLResult>) {
						onStepComplete();
					}, function(e:SQLError) {
						App.debug("SyncProductStock.process #2", e);
						trace("Error #2", id, ",", produtoId, ",", skuCor, ",", skuTamanho, sql);
						onResultError(e);
					});
				}
			}
			else {
				onStepError();
			}
		}
	}
}
