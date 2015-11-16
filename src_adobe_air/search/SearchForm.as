package content.search {
	import com.adobe.utils.ArrayUtil;
	import com.adobe.utils.DictionaryUtil;
	import com.adobe.utils.StringUtil;
	import com.greensock.TweenMax;
	import com.greensock.easing.Strong;
	
	import content.Content;
	import content.details.ProductDescription;
	import content.touchscroll.Product;
	import content.touchscroll.TouchPanelBase;
	
	import flash.data.SQLResult;
	import flash.display.MovieClip;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	public class SearchForm extends TouchPanelBase {

		public var closeButton:MovieClip;
		public var searchFilter:MovieClip;

		public var grid:MovieClip; //results container
		public var btDragger:MovieClip;
		public var mcMask:MovieClip;
		private var bounds:Rectangle = new Rectangle(); //mask
		private var isOpen:Boolean = false;
		private var moved:Boolean = false;
		public var resultLabel:MovieClip;
		private var filterList:Object = {};
		public var products:Array = null;
		private var isFullClosed:Boolean;
		private var searchFilterGroups:Array;

		public function SearchForm() {
			init(grid, true);
			
			resultLabel.visible = false;
			closeButton.addEventListener(MouseEvent.CLICK, closeForm);
			btDragger.addEventListener(MouseEvent.MOUSE_DOWN, onStartDrag);
			addEventListener(SearchEvent.UPDATE_SEARCH, updateProducts);
			
			mcMask.height = 0;
			grid.visible = false;
			isFullClosed = true;
			//mask
			setFilters();
		}
		

		private function updateProducts(evt:Event):void {
			loadItems();
		}

		private function closeForm(evt:MouseEvent):void {
			closePanel(true);
		}

		override protected function loadItems():void {
			if(hasSelectedFilter()) {
				if(products.length > 0) {
					var pArray:Array = new Array();
					for each(var p:Object in products) {
						pArray.push(+p.produto_cores_id);
					}
					loadProducts("WHERE pc.id IN (" + pArray.join(", ") + ")");
				}
				else {
					//no results found
					setResultLabel();
					unloadPages();
				}
			}
			else {
				//no filter selected
				setResultLabel(null, true);
				unloadPages();
			}
		}

		protected function loadProducts(where:String) {
			var sql:String = Product.LIST_SQL + where +
				"AND image_cover IS NOT NULL " +
				"ORDER BY p.id, p.nome";
			db.execute(sql, null, onItemsResult, null, onResultError);
		}

		protected function onItemsResult(rs:SQLResult):void {
			setResultLabel(rs.data ? rs.data.length : 0);

			if(rs.data && rs.data.length > 0) {
				buildGrid(rs.data, ProductDescription.BUSCA);
			}
		}
		private function onStartDrag(evt:MouseEvent):void {
			moved = false;
			btDragger.startDrag(false, isFullClosed ? new Rectangle(0, 0, 0, bounds.height) : bounds);
			stage.addEventListener(MouseEvent.MOUSE_UP, onDragMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDragMouseMove);
		}

		private function onDragMouseUp(evt:MouseEvent):void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDragMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onDragMouseUp);
			btDragger.stopDrag();

			if(moved) {
				if(btDragger.y < (bounds.height - bounds.height / 4))
					closePanel();
				else
					openPanel();
			}
			else{
				if(isOpen)
					closePanel()
				else
					openPanel();
			}
		}
		private function onDragMouseMove(evt:MouseEvent):void {
			moved = true;
			updateMask();
		}
		public function openPanel():void {
			isOpen = true;
			TweenMax.to(btDragger, .5, {y: bounds.y + bounds.height, ease: Strong.easeOut, onUpdate: updateMask});
			isFullClosed = false;
			grid.visible = true;
			if(grid.alpha == 0){
				TweenMax.to(grid, .5, {alpha: 1, ease: Strong.easeOut});
			}
			Content.instance.showMarca(false);
		}

		public function closePanel(fullClose:Boolean = false):void {
			
			//fullClose when has no filter selected
			if(!fullClose)
				fullClose = !hasSelectedFilter();
				
			isOpen = false;
			TweenMax.to(btDragger, .5, {y: fullClose ? 0 : bounds.y, ease: Strong.easeOut, onUpdate: updateMask});
			if(fullClose){
				fullClosePanel();
			}
		}
		private function fullClosePanel():void {
			isFullClosed = true;
			clearFilter();
			TweenMax.to(grid, .5, {alpha: 0, ease: Strong.easeOut, onComplete: function(){
				grid.visible = false;
				unloadPages();
			}});
			
			Content.instance.showMarca(true);
			
		}
		
		private function clearFilter():void {
			filterList = {};
			resultLabel.visible = false;
			searchFilter.y = resultLabel.y;
			updateBounds();
			searchFilter.tfTextSearch.text = "";
			for each(var fg:SearchFilterGroup in searchFilterGroups){
				fg.reset();
			}
		}
		
		private function updateMask():void {
			mcMask.height = btDragger.y;
			updateGridSize();
		}

		private function updateBounds(rect:Rectangle = null) {
			bounds.y = rect != null ? rect.y : searchFilter.y;
			bounds.height = rect != null ? rect.height : searchFilter.height + 20;
			updateGridSize();
		}
		
		private function updateGridSize(){
			grid.y = btDragger.y + btDragger.height - 10;
			if(scroller){
				scroller.maskHeight = 1920 - grid.y;
			}
		}

		public function setResultLabel(numResults:uint = 0, remove:Boolean = false):void {
			if(!remove) {
				TweenMax.to(resultLabel, .2, {alpha: 1});
				TweenMax.to(searchFilter, .2, {y: resultLabel.y + resultLabel.height + 20, onUpdate: updateMaskSize});
				resultLabel.visible = true;
				if(numResults) {
					resultLabel.txtNumResults.visible = resultLabel.txtLabelResults.visible = true;
					resultLabel.txtNumResults.text = numResults + (numResults > 1 ? " PRODUTOS" : " PRODUTO");
					resultLabel.txtLabelResults.text = numResults > 1 ? "FORAM ENCONTRADOS" : "FOI ENCONTRADO";
				}
				else {
					resultLabel.txtNumResults.visible = false;
					resultLabel.txtLabelResults.visible = true;
					resultLabel.txtLabelResults.text = "NENHUM RESULTADO ENCONTRADO";
				}
			}
			else {
				TweenMax.to(resultLabel, .2, {alpha: 0});
				TweenMax.to(searchFilter, .3, {y: resultLabel.y, onUpdate: updateMaskSize});
			}
		}

		private function updateMaskSize() {
			updateBounds();
			openPanel();
		}
		
		private function setFilters() {
			searchFilterGroups = new Array();

			var fList:Array = [
				{table: "genero", label: "GÊNEROS", itemRenderer: "generoRenderer", y: 0},
				{table: "marca", label: "MARCAS", itemRenderer: "marcaRenderer",  y: 200},
				{table: "tamanho", label: "TAMANHOS", itemRenderer: "defaultRenderer", y: 400},
				{table: "subclasse", label: "CATEGORIAS", itemRenderer: "categoriaRenderer", y: 560},
			];
			
			for each(var t:Object in fList) {
				var table:String = t.table;
				var sql:String;
				
				if(table == "marca") {
					sql = "SELECT m.id, m.nome, f.path FROM " + table + " m " +
							"LEFT JOIN files f ON m.file_id_logo = f.hash AND f.ready = 1 " +
							"WHERE m.active = 1 ORDER BY m.nome";
				}
				else if(table == "genero") {
					sql = "SELECT m.id, m.nome, m.key, m.ids FROM " + table + " m " +
							"WHERE m.active = 1 ORDER BY m.nome";
				}
				else if (table == "tamanho"){
					sql = "SELECT DISTINCT t.id, t.nome FROM produto_tamanho pt " +
							"INNER JOIN " + table + " t ON t.id = pt.tamanho_id " +
							"WHERE t.active = 1 ORDER BY t.nome";
				}
				else if(table == "subclasse"){
					sql = "SELECT m.id, m.nome FROM " + table + " m " +
							"WHERE m.active = 1 ORDER BY m.nome";
				}
				
				new function(t){
					Database.getInstance().execute(sql, null, function(rs:SQLResult) {
						if(rs.data) {
							buildFilterItem(rs, t);
						}
					}, null, onResultError);
				}(t);
			}
			//textfield search
			setTextFilter();
		}
		
		private function buildFilterItem(rs:SQLResult, itemData:Object):void {
			
			//group
			var item:SearchFilterGroup = new SearchFilterGroup(itemData, rs.data);
			item.addEventListener(SearchEvent.SELECT_ITEM, function(e:SearchEvent){
				var t = e.data;
				t.selected ? addFilter(t) : removeFilter(t);
			});
			item.y = itemData.y;	
			item.x = 60;
			searchFilterGroups.push(item);
			searchFilter.addChild(item);
			updateBounds();
		}
		
		private function addFilter(d:Object):void {
			if(d.type == "text"){
				filterList[d.type] = new Array(d.itemData.id);
			}
			else{
				if(!filterList[d.type]) {
					filterList[d.type] = new Array();
				}
				/*
				if(d.itemData.ids){
					var arr:Array = d.itemData.ids.split(",");
					for each(var id:String in arr){
						var v:String = StringUtil.trim(id);
						if(v){
							filterList[d.type].push(v);
						}
					}
				}
				else{*/
					filterList[d.type].push(d.itemData.id);
				//}
			}
			updateResult(filterList);
		}
		
		private function removeFilter(d:Object):void {
			if(d.type == "text"){
				delete filterList[d.type];
			}
			else{
				var t:Array = filterList[d.type];				
				t.splice(t.indexOf(d.itemData.id), 1);
				if(t.length == 0)
					delete filterList[d.type];
			}
			updateResult(filterList);
		}
		
		private function setTextFilter():void {
			searchFilter.tfTextSearch.addEventListener(Event.CHANGE, function(e:Event) {
				var txt:String = StringUtil.trim(searchFilter.tfTextSearch.text);
				//add text filter
				if(txt == ""){
					removeFilter({type: "text", itemData : {id:txt}});
				}
				else if(txt != "" && txt.length > 3){
					addFilter({type: "text", itemData : {id:txt}});
				}
			});
		}
		
		private function updateResult(fList:Object):void {
		
			var sql:String = "SELECT p.id AS produto_id, pc.id AS produto_cores_id " +
								"FROM produto p " +
							"INNER JOIN produto_cores pc ON pc.produto_id = p.id ";
			
			var where:String = " WHERE 1 = 1 ";
			var table_prefix:String;
			var params:Object = {};
			products = null;
			
			for(var filter:String in fList) {
				if(filter == "text") {
					params["filter"] = '%' + fList[filter] + '%';
					where += "AND ((p.sku || '-' || pc.sku) LIKE :filter OR p.nome LIKE :filter)";
				}
				else if(filter == "genero") {
					where += "AND (SELECT g.id FROM genero g WHERE g.id IN (" + fList[filter] + ") AND TRIM(g.ids, TRIM(g.ids, p.genero_id)))";
				}
				else {
					table_prefix = filter.charAt(0);
					if(filter == "tamanho") {
						sql += "INNER JOIN produto_tamanho pt ON (pt.produto_id = p.id) " +
							"INNER JOIN tamanho t ON (t.id = pt.tamanho_id)";
					}
					else {
						sql += "INNER JOIN " + filter + " " + table_prefix + " ON " + table_prefix + ".id = p." + filter + "_id ";
					}
					
					where += " AND " + table_prefix + ".id IN (" + fList[filter] + ")";
				}
			}
						
			sql = sql + where;
			Database.getInstance().execute(sql, params, onProductComplete, null, onResultError);
		}

		protected function onProductComplete(rs:SQLResult):void {
			products = rs.data ? rs.data : [];
			dispatchEvent(new SearchEvent(SearchEvent.UPDATE_SEARCH));
		}	

		public function hasSelectedFilter():Boolean{
			for each(var a:Array in filterList){
				if(a.length > 0){
					return true;
					break;
				}
			}
			return false;
		}

	}
}
