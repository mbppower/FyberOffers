package content.search {
	import com.greensock.TweenMax;
	import com.greensock.layout.AlignMode;
	import com.greensock.layout.ScaleMode;
	import com.greensock.plugins.TintPlugin;
	import com.greensock.plugins.TweenPlugin;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.filesystem.File;
	import flash.text.TextField;

	public class SearchFilterGroup extends HorizontalListComboBase {

		public var txtLabel:TextField;
		public var itemContent:MovieClip;
		public var scrollContainer:MovieClip;
		public var mcBackground:MovieClip;

		public function SearchFilterGroup(data:Object, items:Array, lines:uint = 1, maxWidth:uint = 960) {
			super(data, items, lines, maxWidth);
			init(scrollContainer, itemContent, txtLabel, mcBackground);
		}

		/**
		 * Override
		 */
		override protected function getRendererFunction(itemRenderer:String, itemData:Object, itemType:String):DisplayObject {
			return this[itemRenderer](itemData, itemType);
		}

		//begin renderer
		private function generoRenderer(itemData:Object, table:String) {
			var fItem = new SearchItemWithImage();
			fItem.autoResize = false;
			fItem.label = String(itemData["nome"]).toUpperCase();
			fItem.loadImage(File.applicationDirectory.resolvePath("assets/search/gender/icon_" + itemData["key"] + ".png").nativePath, {width: 103,
					height: 73, scaleMode: ScaleMode.NONE, vAlign: AlignMode.BOTTOM});
			return fItem;
		}

		private function marcaRenderer(itemData:Object, table:String):MovieClip {
			var fItem = new SearchItemWithImage();
			fItem.autoResize = false;
			if(itemData["path"]) {
				fItem.loadImage(IFeet.getApplicationStorageDirectory().resolvePath(itemData["path"]).nativePath, {width: 103, height: 103, scaleMode: ScaleMode.PROPORTIONAL_INSIDE});
			}
			else {
				fItem.centerVertical = true;
				fItem.label = itemData["nome"];
			}
			return fItem;
		}

		private function categoriaRenderer(itemData:Object, table:String):MovieClip {
			var fItem = new SearchItemOnlyLabelHorizontal();
			fItem.label = itemData["nome"];
			return fItem;
		}

		private function defaultRenderer(itemData:Object, table:String):MovieClip {
			var fItem = table == "subclasse" ? new SearchItemOnlyLabelHorizontal() : new SearchItemOnlyLabelBox();
			fItem.autoResize = false;
			fItem.label = itemData["nome"];
			return fItem;
		}
		//end renderer
	}
}
