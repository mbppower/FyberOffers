package content.search {
	import com.greensock.TweenMax;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.ImageLoader;
	import com.greensock.plugins.TintPlugin;
	import com.greensock.plugins.TweenPlugin;

	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	TweenPlugin.activate([TintPlugin]);

	public class SearchFilterItem extends MovieClip {
		public var txtLabel:TextField;
		public var imageContainer:MovieClip;
		public var mcBackground:MovieClip;
		public var info:Object;
		private var _label:String;
		public var autoResize:Boolean = true;
		public var centerVertical:Boolean = false;

		public function SearchFilterItem(label:String = "", info:Object = null) {
			this.label = label;
			this.info = info;
			TweenMax.to(txtLabel, 0, {tint:"0xdbdbdb"});
		}

		public function loadImage(path:String, params:Object) {
			TweenMax.to(imageContainer, 0, {tint:"0xdbdbdb"});
			if(!params["container"]) {
				params["container"] = imageContainer;
			}
			var imageLoader:ImageLoader = new ImageLoader(path, params);
			imageLoader.load();
		}

		public function set label(value:String):void {
			if(!value)
				return;
			_label = value;
			txtLabel.text = value;
			txtLabel.autoSize = TextFieldAutoSize.LEFT;

			//resize background
			if(autoResize) {
				mcBackground.width = txtLabel.width + 40;
				mcBackground.width = mcBackground.width < mcBackground.height ? mcBackground.height : mcBackground.width;
			}
			//center
			if(centerVertical)
				txtLabel.y = (mcBackground.height - txtLabel.height) / 2;
			txtLabel.x = (mcBackground.width - txtLabel.width) / 2;
		}

		public function set selected(value:Boolean):void {
			mcBackground.gotoAndStop(value ? 2 : 1);
			TweenMax.to(txtLabel, 0, {tint: (value ? "0x7b7b7b" : "0xdbdbdb")});
			
			if(imageContainer)
				TweenMax.to(imageContainer, 0, {tint: (value ? "0x7b7b7b" : "0xdbdbdb")});
		}

		public function get selected():Boolean {
			return mcBackground.currentFrame == 2;
		}
	}

}
