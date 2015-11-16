package admin.sync.processor {
	import admin.sync.SyncEvent;

	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;

	public class DataProcessor extends ProcessorBase {

		public function DataProcessor(dbPath:String, items:ArrayCollection, tableName:String) {
			super(dbPath, items, items.length, tableName);
		}

		public function get itemList():ArrayCollection {
			return _itemList as ArrayCollection;
		}

		override public function init() {
			switch(table) {
				case "screensaver":  {
					_processFunction = screensaverProcess;
					break;
				}
				case "produto_galeria":  {
					_processFunction = produtoGaleriaProcess;
					break;
				}
				case "startup_news":  {
					_processFunction = startupNewsProcess;
					break;
				}
				case "marca":  {
					_processFunction = marcaProcess;
					break;
				}
				case "produto_promocao":  {
					_processFunction = produtoPromocaoProcess;
					break;
				}
				case "produto_destaque":  {
					_processFunction = produtoDestaqueProcess;
					break;
				}
				case "genero":  {
					_processFunction = generoProcess;
					break;
				}
				default:  {
					_processFunction = defaultProcess;
					break;
				}
			}
			stmList = new Vector.<QueuedStatement>();
			process();
		}

		//screenserver
		private function screensaverProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, ordem, file_id_swf, active) VALUES (:id, :ordem, :file_id_swf, :active)";

			var params:Object = {"id": +item.id,
					"ordem": +item.ordem,
					"file_id_swf": item.swf_file_hash ? item.swf_file_hash : null,
					"active": item.active};

			stmList.push(new QueuedStatement(sql, params));
			if(item.swf_file) {
				processFile(table, item.swf_file, item.swf_file_hash);
			}
			onStepComplete();
		}

		//startup_screen
		private function startupNewsProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, author, title, content, date_start, date_finish, [order], active, file_id) VALUES (:id, :author, :title, :content, :date_start, :date_finish, :order, :active, :file_id)";

			var params:Object = {"id": +item.id,
					"author": item.author,
					"title": item.title,
					"content": item.content,
					"date_start": item.date_start ? item.date_start : null,
					"date_finish": item.date_finish ? item.date_finish : null,
					"order": +item.order,
					"active": +item.active,
					"file_id": item.file_hash ? item.file_hash : null
				};

			stmList.push(new QueuedStatement(sql, params));

			if(item.file_data) {
				processFile(table, item.file_data, item.file_hash);
			}
			onStepComplete();
		}

		//marca
		private function marcaProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, nome, file_id_logo, active) VALUES (:id, :nome, :file_id_logo, :active)";

			var params:Object = {"id": +item.id,
					"nome": item.nome,
					"file_id_logo": item.logo_hash ? item.logo_hash : null,
					"active": item.active
				};

			stmList.push(new QueuedStatement(sql, params));
			if(item.logo) {
				processFile(table, item.logo, item.logo_hash);
			}
			onStepComplete();
		}

		//produto_galeria
		private function produtoGaleriaProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, produto_id, [order], file_id, active) VALUES (:id, :produto_id, :order, :file_id, :active)";

			var params:Object = {"id": +item.id,
					"produto_id": +item.produto_id,
					"order": +item.order,
					"file_id": item.file_hash ? item.file_hash : null,
					"active": +item.active
				};

			stmList.push(new QueuedStatement(sql, params));
			if(item.file) {
				processFile(table, item.file, item.file_hash);
			}
			onStepComplete();
		}

		//produto_promocao
		private function produtoPromocaoProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, produto_cores_id, preco_de, preco_por, data_inicio, data_fim, [order], active) VALUES (:id, :produto_cores_id, :preco_de, :preco_por, :data_inicio, :data_fim, :order, :active)";

			var params:Object = {"id": +item.id,
					"produto_cores_id": +item.produto_cores_id,
					"preco_de": item.preco_de,
					"preco_por": item.preco_por,
					"data_inicio": item.date_start ? item.date_start : null,
					"data_fim": item.date_finish ? item.date_finish : null,
					"order": +item.order,
					"active": +item.active};

			stmList.push(new QueuedStatement(sql, params));
			onStepComplete();
		}

		//produto_destaque
		private function produtoDestaqueProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, produto_cores_id, date_start, date_finish, [order], active) VALUES (:id, :produto_cores_id, :date_start, :date_finish, :order, :active)";

			var params:Object = {"id": +item.id,
					"produto_cores_id": +item.produto_cores_id,
					"date_start": item.date_start ? item.date_start : null,
					"date_finish": item.date_finish ? item.date_finish : null,
					"order": +item.order,
					"active": +item.active};

			stmList.push(new QueuedStatement(sql, params));
			onStepComplete();
		}

		//genero
		private function generoProcess(isUpdate:Boolean, item:Object):void {
			var dontRemove:Array = new Array();
			for each(var i:Object in _itemList) {
				dontRemove.push(i.id);
			}
			var sqlDel:String = "DELETE FROM " + table + " WHERE id NOT IN (" + dontRemove.join(", ") + ")";
			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, nome, key, ids, active) VALUES (:id, :nome, :key, :ids, :active)";

			var params:Object = {"id": item.id,
					"nome": item.label,
					"key": item.chave,
					"ids": item.ids,
					"active": item.active};

			stmList.push(new QueuedStatement(sqlDel));
			stmList.push(new QueuedStatement(sql, params));
			onStepComplete();
		}

		//default
		private function defaultProcess(isUpdate:Boolean, item:Object):void {

			var sql:String = "INSERT OR REPLACE INTO " + table + " (id, nome, active) VALUES (:id, :nome, :active)";

			var params:Object = {"id": item.id,
					"nome": item.nome,
					"active": item.active};

			stmList.push(new QueuedStatement(sql, params));
			onStepComplete();
		}
	}
}
