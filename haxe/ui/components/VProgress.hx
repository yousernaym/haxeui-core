package haxe.ui.components;

import haxe.ui.core.Component;
import haxe.ui.core.MouseEvent;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.core.IClonable;

/**
 A vertical implementation of a `Progress`
**/
@:dox(icon="/icons/ui-progress-bar-vertical.png")
class VProgress extends Progress implements IClonable<VProgress> {
    public function new() {
        super();
    }

    //***********************************************************************************************************
    // Internals
    //***********************************************************************************************************
    private override function createDefaults():Void {
        super.createDefaults();
        _defaultLayout = new VProgressLayout();
    }

    private override function createChildren():Void {
        super.createChildren();
        if (componentWidth <= 0) {
            componentWidth = 20;
        }
        if (componentHeight <= 0) {
            componentHeight = 150;
        }
    }
}

//***********************************************************************************************************
// Custom layouts
//***********************************************************************************************************
@:dox(hide)
class VProgressLayout extends DefaultLayout {
    public function new() {
        super();
    }

    public override function resizeChildren():Bool {
        super.resizeChildren();

        var value:Component = component.findComponent("progress-value");
        var progress:Progress = cast component;
        if (value != null) {
            var ucy:Float = usableHeight;

            var cy:Float = 0;
            if (progress.rangeStart == progress.rangeEnd) {
                cy = (progress.pos - progress.min) / (progress.max - progress.min) * ucy;
            } else {
                cy = ((progress.rangeEnd - progress.rangeStart) - progress.min) / (progress.max - progress.min) * ucy;
            }

            if (cy < 0) {
                cy = 0;
            } else if (cy > ucy) {
                cy = ucy;
            }

            if (cy == 0) {
                value.componentHeight = 0;
                value.hidden = true;
            } else {
                value.componentHeight = cy;
                value.hidden = false;
            }
        }
        return true;
    }

    public override function repositionChildren():Void {
        super.repositionChildren();

        var value:Component = component.findComponent("progress-value");
        var progress:Progress = cast component;
        if (value != null) {
            var ucy:Float = usableHeight;
            var y:Float = ucy - value.componentHeight + paddingBottom;
            if (progress.rangeStart != progress.rangeEnd) {
                y -= (progress.rangeStart - progress.min) / (progress.max - progress.min) * ucy;
            }
            value.top = y;
        }
    }
}
