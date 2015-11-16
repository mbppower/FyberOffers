package admin.sync.processor {
	import admin.app.App;
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

	public class ProductImage {
		
		private var l:uint;
		private var i:uint = 0;
		private var _callback:Function;
		private var _processFile:Function;
		private var _items:Array;
		private var _table:String;
		
		public function ProductImage(produtoCoresImagem, table, processFile:Function, callback:Function) {
			_items = produtoCoresImagem;
			_table = table;
			
			_callback = callback;
			_processFile = processFile;
			
			l = _items.length;
			next();
		}
	
	private function next() {
		//complete
		if(i == l) {
			_callback();
		}
		else {
			processImage();
		}
	}
	
	private function processImage() {
		var currentItem:Object = _items[i];
		_processFile(_table, currentItem.image, currentItem.image_hash, function(file_id:Number) {
			var param:Object = {
				"produto_cores_id": currentItem.produto_cores_id,
				"file_id": file_id
			};
			Database.getInstance().executeModify(Vector.<QueuedStatement>(new QueuedStatement("INSERT INTO produto_cores_imagem VALUES (:produto_cores_id, :file_id)", param)), onComplete, onResultError);
		});
	}
	private function onComplete(results:Vector.<SQLResult>) {
		i++;
		next();
	}
	
	private function onResultError(e:SQLError):void {
		App.debug("ProductImage.onResultError", e);	
	}
}
