package content.search {
	import com.doitflash.consts.Easing;
	import com.doitflash.consts.Orientation;
	import com.doitflash.consts.ScrollConst;
	import com.doitflash.events.ScrollEvent;
	import com.doitflash.utils.scroll.TouchScroll;
	import com.greensock.TweenMax;
	import com.greensock.layout.AlignMode;
	import com.greensock.layout.ScaleMode;
	import com.greensock.loading.ImageLoader;
	import com.greensock.plugins.TintPlugin;
	import com.greensock.plugins.TweenPlugin;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getDefinitionByName;

	TweenPlugin.activate([TintPlugin]);

	public class HorizontalListComboBase extends MovieClip {

		protected var _tfLabel:TextField;
		protected var _itemContent:MovieClip;
		protected var _scrollContainer:MovieClip;
		protected var _mcBackground:MovieClip;

		protected var _data:Object;
		protected var _items:Array;
		protected var _filterItems:Array;
		protected var _scroller:TouchScroll;
		protected var _maxWidth:uint = 646;
		protected var _lines:uint = 1;

		public function HorizontalListComboBase(data:Object, items:Array, lines:uint = 1, maxWidth:uint = 646) {
			_data = data;
			_items = items;
			_maxWidth = maxWidth;
			_lines = lines;
		}

		protected function init(scrollContainer:MovieClip, itemContent:MovieClip, tfLabel:TextField, mcBackground:MovieClip) {
			_tfLabel = tfLabel;
			_itemContent = itemContent;
			_scrollContainer = scrollContainer;
			_mcBackground = mcBackground;

			//build
			buildList();
		}

		private function buildList() {
			//list label
			label = _data.label;

			//item container
			_itemContent = new MovieClip();
			_filterItems = new Array();
			//items
			for each(var itemData:Object in _items) {
				var fItem = buildItem(itemData);
				fItem.x = _itemContent.width + (_itemContent.numChildren > 0 ? 10 : 0);
				_itemContent.addChild(fItem);
				_filterItems.push(fItem);
			}
			//scroll
			if(_itemContent.width > _maxWidth) {
				_itemContent.x = 65;
				setScroll(_itemContent);
				_scrollContainer.addChildAt(_scroller, 0);

			}
			else {
				_scrollContainer.addChild(_itemContent);
				_scrollContainer.btLeft.visible = _scrollContainer.btRight.visible = false;
			}

			//position
			_scrollContainer.y = _mcBackground.y + _mcBackground.height + 20;
		}

		private function buildItem(itemData:Object):MovieClip {
			var item = getRendererFunction(_data.itemRenderer, itemData, _data.table);
			item.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void {
				var t = evt.currentTarget;
				t.selected = !t.selected;
				dispatchEvent(new SearchEvent(SearchEvent.SELECT_ITEM, {selected: t.selected, type: _data.table, itemData: itemData}));
			});
			return item;
		}

		/**
		 * Override
		 */
		protected function getRendererFunction(itemRenderer:String, itemData:Object, itemType:String):DisplayObject {
			return this[itemRenderer](itemData, itemType);
		}

		private function setScroll(_content:MovieClip) {
			_scroller = new TouchScroll();
			_scroller.x = 0;
			_scroller.y = _content.y;
			_scroller.maskContent = _content;
			_scroller.margin = 60;
			_scroller.isMouseScroll = false;
			_scroller.mouseWheelSpeed = 5;
			_scroller.orientation = Orientation.HORIZONTAL;
			_scroller.easeType = Easing.Strong_easeOut;
			_scroller.aniInterval = .25;
			_scroller.blurEffect = false;
			_scroller.mouseWheelSpeed = 2;
			_scroller.bitmapMode = ScrollConst.WEAK;
			_scroller.isStickTouch = false;
			_scroller.holdArea = 20;
			_scroller.maskWidth = _maxWidth;
			_scroller.maskHeight = _content.height;

			//prevent item click
			_scroller.addEventListener(ScrollEvent.MOUSE_MOVE, function() {
				_itemContent.mouseChildren = false;
				if(!_scroller.hasEventListener(ScrollEvent.MOUSE_UP))
					_scroller.addEventListener(ScrollEvent.MOUSE_UP, mouseUpDisable);
			});

			_scroller.addEventListener(ScrollEvent.TOUCH_TWEEN_UPDATE, function() {
				_itemContent.mouseChildren = false;
			});

			_scroller.addEventListener(ScrollEvent.TOUCH_TWEEN_COMPLETE, function() {
				_itemContent.mouseChildren = true;
			});

			//buttons
			_scrollContainer.btLeft.y = _scroller.height / 2 - _scrollContainer.btLeft.height / 2;
			_scrollContainer.btRight.y = _scroller.height / 2 - _scrollContainer.btRight.height / 2;

			//scroll right
			_scrollContainer.btRight.addEventListener(MouseEvent.CLICK, onScrollRight);

			//scroll left
			_scrollContainer.btLeft.addEventListener(MouseEvent.CLICK, onScrollLeft);
		}

		private function onScrollRight(e:MouseEvent):void {
			var factor:uint = 30;
			if(_scroller.xPerc + factor >= 100) {
				_scroller.xPerc = 100;
				return
			}
			_scroller.xPerc += factor;
		}

		private function onScrollLeft(e:MouseEvent) {
			var factor:uint = 30;
			if(_scroller.xPerc - factor <= 0) {
				_scroller.xPerc = 0;
				return
			}
			_scroller.xPerc -= factor;
		}

		private function mouseUpDisable(e:ScrollEvent) {
			_scroller.removeEventListener(ScrollEvent.MOUSE_UP, mouseUpDisable);
			_itemContent.mouseChildren = true;
		}

		public function set label(value:String):void {
			_tfLabel.text = value;
			_tfLabel.autoSize = TextFieldAutoSize.LEFT;
			_mcBackground.width = _tfLabel.width + 40;
			_mcBackground.width = _mcBackground.width < _mcBackground.height ? _mcBackground.height : _mcBackground.width;
			_tfLabel.x = (_mcBackground.width - _tfLabel.width) / 2;
		}

		public function reset() {
			for each(var sfi:SearchFilterItem in _filterItems) {
				sfi.selected = false;
			}
		}

		public function select(id:Array):void {
			for each(var m:SearchFilterItem in _filterItems)
				m.selected = id.indexOf(m.info.id) > -1;
		}
	}
}
