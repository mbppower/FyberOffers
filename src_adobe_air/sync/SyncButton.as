package admin.sync {
	import flash.display.MovieClip;
	import flash.events.Event;

	public class SyncButton extends MovieClip {
		public var mcArrow:MovieClip;

		public function SyncButton() {
			ready();
		}

		public function ready():void {
			mouseEnabled = mouseChildren = true;
			alpha = 1;
			gotoAndStop(1);
			rotateArrow(false);
		}

		public function working():void {
			mouseEnabled = mouseChildren = false;
			alpha = 1;
			gotoAndStop(2);
			rotateArrow();
		}

		public function disable():void {
			mouseEnabled = mouseChildren = false;
			alpha = .5;
			gotoAndStop(1);
			rotateArrow(false);
		}

		private function rotateArrow(r:Boolean = true) {
			if(r)
				mcArrow.addEventListener(Event.ENTER_FRAME, onArrowEnterFrame);
			else {
				mcArrow.removeEventListener(Event.ENTER_FRAME, onArrowEnterFrame);
				mcArrow.rotation = 0;
			}
		}

		private function onArrowEnterFrame(e:Event) {
			e.target.rotation += 20;
		}
	}
}
