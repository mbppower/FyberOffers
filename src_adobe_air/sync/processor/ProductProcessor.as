package admin.sync.processor {
	import admin.sync.SyncEvent;

	import com.probertson.data.QueuedStatement;
	import com.probertson.data.SQLRunner;

	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.xml.XMLNode;

	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;

	public class ProductProcessor extends ProcessorBase {

		public function ProductProcessor(dbPath:String, items, tableName:String) {
			super(dbPath, items, items.length(), tableName);
		}

		public function get itemList():XMLList {
			return _itemList as XMLList;
		}

		override public function init() {
			_processFunction = processProduct;
			process();
		}

		//product
		protected function processProduct(isUpdate:Boolean, item:XML):void {

			var sql:String = "INSERT OR REPLACE INTO produto (id, sku, nome, marca_id, classe_id, subclasse_id, linha_id, colecao_id, genero_id, descricao, active) VALUES (:id, :sku, :nome, :marca_id, :classe_id, :subclasse_id, :linha_id, :colecao_id, :genero_id, :descricao, :active)";

			var param:Object = {
					"id": +item.id,
					"sku": item.sku.toString(),
					"nome": item.nome.toString(),
					"marca_id": +item.marca_id,
					"classe_id": +item.classe_id,
					"subclasse_id": +item.subclasse_id,
					"linha_id": +item.linha_id,
					"colecao_id": +item.colecao_id,
					"genero_id": +item.genero_id,
					"descricao": item.descricao.toString(),
					"active": +item.active
				};

			stmList.push(new QueuedStatement(sql, param));

			// remove cores anteriores
			param = {"produto_id": +item.id};
			stmList.push(new QueuedStatement("DELETE FROM produto_cores_imagem WHERE produto_cores_id IN (SELECT id FROM produto_cores WHERE produto_id = :produto_id)", param));
			stmList.push(new QueuedStatement("DELETE FROM produto_cores WHERE produto_id = :produto_id", param));
			stmList.push(new QueuedStatement("DELETE FROM produto_tamanho WHERE produto_id = :produto_id", param));

			//produto_cores_imagem
			var produtoCoresImagem:Array = new Array();

			//cores
			for each(var c:XML in item.cores.item) {
				param = {
						"id": +c.@id,
						"nome": c.@nome.toString(),
						"preco_de": c.@preco_de,
						"preco_por": c.@preco_por,
						"sku": c.@sku,
						"promocao": +c.@promocao,
						"exclusivo": +c.@exclusivo,
						"lancamento": +c.@lancamento,
						"descricao_tecnica": c.descricao_tecnica.toString(),
						"produto_id": +item.id
					};
				stmList.push(new QueuedStatement("INSERT INTO produto_cores VALUES (:id, :nome, :preco_de, :preco_por, :sku, :promocao, :exclusivo, :lancamento, :produto_id, :descricao_tecnica)", param));

				//imagem
				var i:uint = 0;
				for each(var imagem:XML in c.imagem.item) {
					produtoCoresImagem.push({
							"produto_cores_id": +c.@id,
							"image": imagem.@image,
							"image_hash": imagem.@image_hash,
							"order": i++
						});
				}
			}

			//tamanhos

			for each(var t:XML in item.tamanhos.item) {
				param = {
						"tamanho_id": +t.@id,
						"produto_id": +item.id,
						"sku": t.@sku
					};
				stmList.push(new QueuedStatement("INSERT INTO produto_tamanho VALUES (:produto_id, :tamanho_id, :sku)", param));
			}

			//Insere as imagens no file_queue para download
			for each(var produtoCoresImagemItem:Object in produtoCoresImagem) {
				processFile(table, produtoCoresImagemItem.image, produtoCoresImagemItem.image_hash);
				stmList.push(new QueuedStatement("INSERT INTO produto_cores_imagem VALUES (:produto_cores_id, :file_id, :order)", {
						"produto_cores_id": produtoCoresImagemItem.produto_cores_id,
						"file_id": produtoCoresImagemItem.image_hash,
						"order": produtoCoresImagemItem.order
					}));
			}

			//step complete
			onStepComplete();
		}
	}
}
