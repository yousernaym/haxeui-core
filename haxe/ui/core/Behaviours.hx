package haxe.ui.core;

import haxe.ui.util.Variant;

typedef BehaviourInfo = {
    var id:String;
    var cls:Class<Behaviour>;
    @:optional var defaultValue:Variant;
    @:optional var config:Map<String, String>;
}

@:access(haxe.ui.core.Component)
@:access(haxe.ui.core.Behaviour)
class Behaviours {
    private var _component:Component;
    
    private var _registry:Map<String, BehaviourInfo> = new Map<String, BehaviourInfo>();
    private var _instances:Map<String, Behaviour> = new Map<String, Behaviour>();
    
    public function new(component:Component) {
        _component = component;
    }
    
    public function register(id:String, cls:Class<Behaviour>, defaultValue:Variant = null) {
        var info:BehaviourInfo = {
            id: id,
            cls: cls,
            defaultValue: defaultValue
        }
        
        _registry.set(id, info);
        _updateOrder.remove(id);
        _updateOrder.push(id);
        _actualUpdateOrder = null;
    }
    
    public function isRegistered(id:String):Bool {
        return _registry.exists(id);
    }
    
    public function replaceNative() {
        if (_component.native == false || _component.hasNativeEntry == false) {
            return;
        }
        
        var ids = [];
        for (id in _registry.keys()) { // make a copy of ids as we might end up modifying the iterator
            ids.push(id);
        } 
        for (id in ids) {
            var nativeProps = _component.getNativeConfigProperties('.behaviour[id=${id}]');
            if (nativeProps != null && nativeProps.exists("class")) {
                var registered = _registry.get(id);
                var info:BehaviourInfo = {
                    id: id,
                    cls: cast Type.resolveClass(nativeProps.get("class")),
                    defaultValue: registered.defaultValue,
                    config: nativeProps
                }
                _registry.set(id, info);
            }
        }
    }
    
    public function validateData() {
        for (key in actualUpdateOrder) {
            var b = _instances.get(key);
            if (Std.is(b, DataBehaviour)) {
                cast(b, DataBehaviour).validate();
            }
        }
    }
    
    private var _updateOrder:Array<String> = [];
    public var updateOrder(get, set):Array<String>;
    private function get_updateOrder():Array<String> {
        return _updateOrder;
    }
    private function set_updateOrder(value:Array<String>):Array<String> {
        _updateOrder = value;
        _actualUpdateOrder = null;
        return value;
    }
    
    private var _actualUpdateOrder:Array<String> = null;
    private var actualUpdateOrder(get, null):Array<String>;
    private function get_actualUpdateOrder():Array<String> {
        if (_actualUpdateOrder == null) {
            _actualUpdateOrder = _updateOrder.copy();
            for (key in _instances.keys()) {
                if (_actualUpdateOrder.indexOf(key) == -1) {
                    _actualUpdateOrder.push(key);
                }
            }
        }
        return _actualUpdateOrder;
    }
    
    public function update() {
        for (key in actualUpdateOrder) {
            var b = _instances.get(key);
            if (b != null) {
                b.update();
            }
        }
    }
    
    public function find(id, create:Bool = true):Behaviour {
        var b = _instances.get(id);
        if (b == null && create == true) {
            var info = _registry.get(id);
            if (info != null) {
                b = Type.createInstance(info.cls, [_component]);
                b.config = info.config;
                b.id = id;
                _instances.set(id, b);
                _actualUpdateOrder = null;
            }
        }

        if (b == null) {
            b = new Behaviour(_component); // TODO: TEMP!!!!!! (just while components move over)
            //throw 'behaviour ${id} not found';
        }
        
        return b;
    }
    
    private var _cache:Map<String, Variant>;
    public function cache() {
        _cache = new Map<String, Variant>();
        for (registeredKey in _registry.keys()) {
            var v = _registry.get(registeredKey).defaultValue;
            var instance = _instances.get(registeredKey);
            if (instance != null) {
                v = instance.get();
            }
            if (v != null) {
                _cache.set(registeredKey, v);
            }
        }
    }

    public function detatch() {
        for (b in _instances) {
            b.detatch();
        }
        _instances = new Map<String, Behaviour>();
    }
    
    public function restore() {
        if (_cache == null) {
            return;
        }
        
        for (key in actualUpdateOrder) {
            var v = _cache.get(key);
            if (v != null) {
                set(key, v);
            }
        }
        
        _cache = null;
    }
    
    public function set(id, value:Variant) {
        var b = find(id);
        b.set(value);
            
        var autoDispatch = b.getConfigValue("autoDispatch", null);
        if (autoDispatch != null) {
            var arr = autoDispatch.split(".");
            var eventName = arr.pop().toLowerCase();
            var cls = arr.join(".");
            var event = Type.createInstance(Type.resolveClass(cls), [eventName]);
            b._component.dispatch(event);
        }
    }
    
    public function get(id):Variant {
        return find(id).get();
    }
    
    public function getDynamic(id):Dynamic {
        return find(id).getDynamic();
    }
    
    public function call(id, param:Any = null):Variant {
        return find(id).call(param);
    }
    
    public function applyDefaults() {
        var order:Array<String> = _updateOrder.copy();
        for (key in _registry.keys()) {
            if (order.indexOf(key) == -1) {
                order.push(key);
            }
        }
        
        for (key in order) {
            var r = _registry.get(key);
            if (r.defaultValue != null) {
                set(key, r.defaultValue);
            }
        }
    }
}
