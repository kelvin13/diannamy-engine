import PNG

import class Foundation.JSONEncoder
import class Foundation.JSONDecoder
import struct Foundation.Data

/* struct Sphere 
{
    private 
    var points:[Math<Float>.V3]
    
    enum Operation 
    {
        case unconstrained(Math<Float>.V3), snapped(Math<Float>.V3), deleted(Int)
    }
    
    init(_ points:[Math<Float>.V3] = [])
    {
        self.points = points 
    }
    
    private 
    func index(before index:Int) -> Int 
    {
        let initial:Int = index == self.points.startIndex ? self.points.endIndex : index
        return self.points.index(before: initial)
    }
    private 
    func index(after index:Int) -> Int 
    {
        let increment:Int = self.points.index(after: index)
        return increment == self.points.endIndex ? self.points.startIndex : increment
    }
    
    // the two points are not guaranteed to be distinct (i.e. if we have a digon), 
    // but are guaranteed to be different from the input
    private 
    func adjacent(to index:Int) -> (Int, Int)?
    {
        guard self.points.count > 1 
        else 
        {
            return nil 
        }
        
        return (self.index(before: index), self.index(after: index))
    }
    
    @inline(__always)
    private static 
    func proximity(_ a:Math<Float>.V3, _ b:Math<Float>.V3, distance:Float) -> Bool
    {
        return Math.dot(a, b) > Float.cos(distance)
    }
    
    private 
    func nearest(to target:Math<Float>.V3, threshold:Float) -> Int? 
    {
        var gamma:Float = -1, 
            index:Int?  = nil 
        for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
        {
            let g:Float = Math.dot(point, target)
            if g > gamma 
            {
                gamma = g
                index = i
            }
        }
        
        return gamma > Float.cos(threshold) ? index : nil
    }
    private 
    func nearest(to target:Math<Float>.V3, threshold:Float, without exclude:Int) -> Int? 
    {
        var gamma:Float = -1, 
            index:Int?  = nil 
        for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
        {
            guard i != exclude 
            else 
            {
                continue 
            }
        
            let g:Float = Math.dot(point, target)
            if g > gamma 
            {
                gamma = g
                index = i
            }
        }
        
        return gamma > Float.cos(threshold) ? index : nil
    }
    
    private 
    func intersect(ray:ControlPlane.Ray) -> Math<Float>.V3? 
    {
        // need to deal with case of sphere not centered at origin
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), ray.source), 
            l:Float          = Math.dot(c, ray.vector)
        
        let discriminant:Float = 1 * 1 + l * l - Math.eusq(c)
        guard discriminant >= 0 
        else 
        {
            return nil
        }
        
        let offset:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
        return Math.normalize(Math.add(ray.source, offset))
    }
    private 
    func attract(ray:ControlPlane.Ray) -> Math<Float>.V3
    {
        // need to deal with case of sphere not centered at origin
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), ray.source), 
            l:Float          = Math.dot(c, ray.vector)
        
        let discriminant:Float    = max(1 * 1 + l * l - Math.eusq(c), 0), 
            offset:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
        return Math.normalize(Math.add(ray.source, offset))
    }
    
    func find(_ ray:ControlPlane.Ray) -> Int? 
    {
        guard let target:Math<Float>.V3 = self.intersect(ray: ray)
        else 
        {
            return nil
        }
        
        return self.nearest(to: target, threshold: 0.02)
    }
    
    private static 
    func collapse(index:Int, around deleted:Int) -> Int 
    {
        return index <= deleted ? index : index - 1
    }
    
    func previewAdd(at index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        if let nearest:Int = self.nearest(to: destination, threshold: 0.02)
        {
            // check if the destination is within the radius of the adjacent points 
            let before:Int = self.index(before: index)
            if      nearest == before 
            {
                return .deleted(before)
            }
            else if nearest == index 
            {
                return .deleted(index)
            }
            
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained(destination)
    }
    
    func previewMove(_ index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        if let nearest:Int = self.nearest(to: destination, threshold: 0.02, without: index)
        {
            // check if the destination is within the radius of the adjacent points 
            if  self.points.count > 1 
            {
                let before:Int = self.index(before: index), 
                    after:Int  = self.index(after: index)
                if      nearest == before 
                {
                    return .deleted(Sphere.collapse(index: before, around: index))
                }
                else if nearest == after 
                {
                    return .deleted(Sphere.collapse(index: after,  around: index))
                }
            }
            
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained(destination)
    }
    
    @discardableResult
    mutating 
    func add(at index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let operation:Operation = self.previewAdd(at: index, ray: ray)
        switch operation
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                self.points.insert(destination, at: index) 
            
            case .deleted:
                break
        }
        
        return operation
    }
    
    @discardableResult
    mutating 
    func move(_ index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let operation:Operation = self.previewMove(index, ray: ray)
        switch operation
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                self.points[index] = destination 
            
            case .deleted:
                self.points.remove(at: index)
        }
        
        return operation
    }
    
    func apply() -> [Math<Float>.V3]
    {
        return self.points
    }
    
    func apply(_ operation:Operation, addingAt index:Int) -> [Math<Float>.V3]
    {
        var vertices:[Math<Float>.V3] = self.apply()
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                
                vertices.insert(destination, at: index)
            
            case .deleted:
                break
        }
        
        return vertices
    }
    
    func apply(_ operation:Operation, moving index:Int) -> [Math<Float>.V3]
    {
        var vertices:[Math<Float>.V3] = self.apply()
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                
                vertices[index] = destination
            
            case .deleted:
                vertices.remove(at: index)
        }
        
        return vertices
    }
} */

struct Model 
{
    struct Log 
    {
        var contents:[Unicode.Scalar] = []
    
        mutating 
        func print(_ string:[Unicode.Scalar]) 
        {
            self.contents.append(contentsOf: string)
        }
        
        mutating 
        func print(_ string:String, terminator:String = "\n") 
        {
            self.contents.append(contentsOf: string.unicodeScalars)
            self.contents.append(contentsOf: terminator.unicodeScalars)
        }
    }
    
    struct Map 
    {
        // points are quasi-normalized, meaning we do our best to keep them sensible 
        // unit-length vectors, but should make no hard assumptions
        var points:[Vector3<Float>], 
            backgroundImage:String?
        
        var background:GL.Texture<PNG.RGBA<UInt8>>
        
        init(quasiUnitLengthPoints points:[Vector3<Float>], backgroundImage:String? = nil) 
        {
            self.points             = points 
            self.background         = .generate()
            self.backgroundImage    = backgroundImage
            
            self.reloadBackgroundImage()
        }
        
        mutating 
        func replace(background path:String) -> String?
        {
            // "/home/klossy/downloads/world.topo.bathy.png"
            self.backgroundImage = path
            return self.reloadBackgroundImage()
        }
        
        mutating 
        func clear() -> String?
        {
            self.backgroundImage = nil 
            return self.reloadBackgroundImage()
        }
        
        @discardableResult
        private mutating 
        func reloadBackgroundImage() -> String?
        {
            guard let path:String = self.backgroundImage 
            else 
            {
                // generate checkerboard
                let image:Array2D<PNG.RGBA<UInt8>> = .init(size: .init(16, 16)) 
                {
                    ($0.y & 1 + $0.x) & 1 == 0 ? .init(60, .max) : .init(200, .max)
                }
                
                self.background.bind(to: .texture2d)
                {
                    $0.data(image, layout: .rgba8, storage: .rgba8)
                    $0.setMagnificationFilter(.nearest)
                    $0.setMinificationFilter(.nearest, mipmap: nil)
                }
                
                return nil
            }
            
            guard let (image, (x, y)):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
                try? PNG.rgba(path: path, of: UInt8.self)
            else 
            {
                return "could not read file '\(path)'"
            }
            
            self.background.bind(to: .texture2d)
            {
                $0.data(.init(image, size: .init(x, y)), layout: .rgba8, storage: .rgba8)
                $0.setMagnificationFilter(.linear)
                $0.setMinificationFilter(.linear, mipmap: .linear)
                $0.generateMipmaps()
            }
            
            return nil
        }
        
        func findNearest(to location:Vector3<Float>, threshold:Float) -> Int? 
        {
            var gamma:Float = -1, 
                index:Int?  = nil 
            for (i, point):(Int, Vector3<Float>) in self.points.enumerated()
            {
                let g:Float = point <> location
                if g > gamma 
                {
                    gamma = g
                    index = i
                }
            }
            
            return gamma > Float.Math.cos(threshold) ? index : nil
        }
    }
    
    var log:Log 
    var map:Map
    
    init() 
    {
        self.log = .init()
        self.map = .init(quasiUnitLengthPoints: 
            [
                Vector3<Float>.init( 1,  0, 1), 
                Vector3<Float>.init( 0,  1, 1), 
                Vector3<Float>.init(-1,  0, 1), 
                Vector3<Float>.init( 0, -1, 1)
            ].map{ $0.normalized() })
        
        self.log.print("> ", terminator: "")
    }
    
    mutating 
    func input(_ input:[Unicode.Scalar]) -> Coordinator.Event?
    {
        self.log.print(input)
        
        let commands:[ArraySlice<Unicode.Scalar>] = input.dropLast().split(separator: " ")
        
        defer 
        {
            self.log.print("> ", terminator: "")
        }
        
        guard let first:String = (commands.first.map{ .init($0.map(Character.init(_:))) })
        else 
        {
            return nil
        }
        
        let arguments:[String] = commands.dropFirst().map{ .init($0.map(Character.init(_:))) }
        
        switch first 
        {
        case "help":
            self.log.print("press ctrl-1 to toggle terminal")
        case "exit":
            return .toggleTerminal
        
        case "mapedit":
            guard let second:String = arguments.first
            else 
            {
                self.log.print("Usage: mapedit COMMAND [PARAMS]...")
                return nil
            }
            
            switch second 
            {
            case "background":
                var suppliedPath:String?    = nil, 
                    clear:Bool              = false
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "-c", "--clear":
                        clear = true 
                    case "-h", "--help":
                        self.log.print(
                            """
                            Usage: mapedit background [OPTION] FILE
                            Change the background image on the globe.
                            
                              -h, --help        display this message
                              -c, --clear       remove the background image from the globe
                            """)
                        return nil
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many outputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                if clear 
                {
                    self.map.clear().map 
                    {
                        self.log.print($0)
                    }
                }
                else 
                {
                    self.map.replace(background: suppliedPath ?? "mapeditor-background.png").map
                    { 
                        self.log.print($0) 
                    }
                }
            
            case "save":
                var suppliedPath:String?    = nil, 
                    force:Bool              = false
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "-f", "--force":
                        force = true 
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many outputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                let encoder:Foundation.JSONEncoder  = .init()
                encoder.outputFormatting = .prettyPrinted
                
                do 
                {
                    let data:Foundation.Data = try encoder.encode(self.map), 
                        buffer:[UInt8]       = .init(data)
                    
                    let path:String = suppliedPath ?? "map.json"
                    do 
                    {
                        try File.write(buffer, to: path, overwrite: force)
                        self.log.print("(mapedit) saved map as '\(path)'")
                    }
                    catch
                    {
                        self.log.print("(mapedit) \(error)")
                    }
                }
                catch
                {
                    self.log.print("(mapedit) error: \(error)")
                }
            
            case "load": 
                var suppliedPath:String?    = nil
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many inputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                let decoder:Foundation.JSONDecoder  = .init()
                
                do 
                {
                    let path:String          = suppliedPath ?? "map.json"
                    let data:Foundation.Data = .init(try File.read(path))
                    
                    self.map = try decoder.decode(Map.self, from: data)
                    self.log.print("(mapedit) loaded map '\(path)'")
                    
                    return .mapSync(reset: true)
                }
                catch
                {
                    self.log.print("(mapedit) error: \(error)")
                }
            
            default:
                self.log.print("(mapedit) unrecognized command '\(second)'")
            }
            
        default:
            self.log.print("unrecognized command '\(first)'")
        }
        
        return nil
    }
    
    mutating 
    func input(_ string:String) -> Coordinator.Event?
    {
        return self.input([Unicode.Scalar](string.unicodeScalars) + ["\n"])
    }
}

struct Coordinator 
{
    struct Context 
    {
        var viewport:Vector2<Float>, 
            model:Model 
        
        enum Mutation 
        {
            case viewport
            case model 
        }
    }
    
    struct Base:LayerController 
    {
        var frame:Rectangle<Float> = .zero 
    }
    
    enum Event 
    {
        case toggleTerminal
        case terminalInput([Unicode.Scalar])
        
        case mapSync(reset:Bool)
        
        case mapPointMoved(Int, Vector3<Float>)
        case mapPointAdded(Int, Vector3<Float>)
        case mapPointRemoved(Int)
    }
    
    var context:Context
    var controllers:[LayerController] 
    
    var definitions:Style.Definitions 
    
    var buttons:UI.Action.BitVector, 
        active:Int, 
        hover:Int? // only managed by emitLeaveCalls(_:)
    
    let displayBlock:UBO.DisplayBlock
    
    var activeController:LayerController
    {
        get 
        {
            return self.controllers[self.active]
        }
        set(v)
        {
            self.controllers[self.active] = v
        }
    }
    
    init()
    {
        self.context        = .init(viewport: .zero, model: .init())
        self.controllers    = 
        [
            Base.init(), 
            Controller.MapEditor.init()
        ]
        
        let faceinfo:[Style.Definitions.Face: (String, Int)] = 
        [
            .mono55:    ("assets/fonts/SourceCodePro-Medium.otf",      16), 
            .text55:    ("assets/fonts/SourceSansPro-Regular.ttf",     16), 
            .text56:    ("assets/fonts/SourceSansPro-Italic.ttf",      16), 
            .text75:    ("assets/fonts/SourceSansPro-Bold.ttf",        16), 
            .text76:    ("assets/fonts/SourceSansPro-BoldItalic.ttf",  16)
        ]
        
        self.definitions    = .init(faces: faceinfo)
        
        self.buttons        = .init()
        self.active         = self.controllers.endIndex - 1
        self.hover          = nil
        
        self.displayBlock   = .init()
    }
    
    private mutating 
    func emitLeaveCalls(newHover index:Int?) 
    {
        guard let old:Int = self.hover 
        else 
        {
            self.hover = index 
            return 
        }
        
        guard   let new:Int = index, 
                    new == old 
        else 
        {
            self.handle(self.controllers[old].leave(self.context))
            self.hover = index 
            return 
        }
    }
    
    private 
    func find(_ position:Vector2<Float>) -> Int
    {
        // search controllers from top to bottom, 
        // can bind by let value since `LayerController.test(_:)` is non-mutating
        for (index, controller):(Int, LayerController) in 
            zip(self.controllers.indices, self.controllers).reversed() 
        {
            if controller.test(position) 
            {
                return index 
            }
        }
        
        Log.fatal("base layer went missing!")
    }
    
    mutating
    func window(size:Vector2<Float>)
    {
        GL.viewport(.init(.zero, .cast(size)))
        self.context.viewport = size 
        
        for index:Int in self.controllers.indices 
        {
            self.controllers[index].frame = .init(.zero, size)
            
            self.controllers[index].notify(.viewport, in: self.context, reset: false) 
        }
    }
    
    mutating 
    func paste(_ string:String) 
    {
        for character:Character in string 
        {
            self.character(character)
        }
    }
    
    mutating 
    func character(_ character:Character) 
    {
        self.handle(self.activeController.character(self.context, character)) 
    }
    
    mutating 
    func keypress(_ key:UI.Key, _ modifiers:UI.Key.Modifiers) 
    {
        // toggle terminal 
        if case .grave = key, 
            modifiers.control 
        {
            self.handle(.toggleTerminal)
        }
        else 
        {
            self.handle(self.activeController.keypress(self.context, key, modifiers)) 
        }
    }
    
    mutating 
    func scroll(_ direction:UI.Direction, _ position:Vector2<Float>) 
    {
        let index:Int = self.find(position) 
        self.handle(self.controllers[index].scroll(self.context, direction, position))
    }
    
    mutating 
    func down(_ action:UI.Action, _ position:Vector2<Float>, doubled:Bool) 
    {
        self.buttons[action] = true 
        
        self.active = self.find(position)  
        self.handle(self.activeController.down(self.context, action, position, doubled: doubled))
        
        self.move(position)
    }
    
    mutating 
    func move(_ position:Vector2<Float>) 
    {
        let index:Int = self.buttons.any ? self.active : self.find(position)
        self.emitLeaveCalls(newHover: index)
        self.handle(self.controllers[index].move(self.context, position))
    }
    
    mutating 
    func up(_ action:UI.Action, _ position:Vector2<Float>) 
    {
        self.buttons[action] = false 
        
        self.handle(self.activeController.up(self.context, action, position))
        
        self.move(position)
    }
    
    private mutating 
    func handle(_ event:Event?) 
    {
        guard let event:Event = event
        else 
        {
            return 
        }
        
        switch event 
        {
        case .toggleTerminal:
            break
            
        case .terminalInput(let input):
            // self.handle(self.model.input(input))
            // self.controller.terminal.sync(to: self.model)
            break 
        
        case .mapSync(let reset):
            self.notify(.model, to: .all(Controller.MapEditor.self), reset: reset)
        
        case .mapPointMoved(let index, let location):
            // notify isn’t strictly necessary for this case or .mapPointAdded, 
            // as the controllers will already be in a clean state, but we notify 
            // as confirmation anyway
            self.context.model.map.points[index] = location.normalized()
            self.notify(.model, to: .all(Controller.MapEditor.self))
        
        case .mapPointAdded(let index, let location):
            self.context.model.map.points.insert(location.normalized(), at: index)
            self.notify(.model, to: .all(Controller.MapEditor.self))
        
        case .mapPointRemoved(let index):
            self.context.model.map.points.remove(at: index)
            self.notify(.model, to: .all(Controller.MapEditor.self))
        }
    }
    
    mutating 
    func process(_ delta:Int) -> Bool 
    {
        var redraw:Bool = false 
        for index:Int in self.controllers.indices 
        {
            redraw = self.controllers[index].process(self.context, delta) || redraw
        }
        
        return redraw
    }
    
    mutating 
    func draw() 
    {
        GL.clear(color: true, depth: true)
        for index:Int in self.controllers.indices 
        {
            self.displayBlock.bind(index: 0) 
            {
                UBO.DisplayBlock.encode( frame: self.controllers[index].frame, 
                                      viewport: self.context.viewport, 
                                            to: $0)
                self.controllers[index].draw(self.context, definitions: self.definitions)
            }
        }
    }
    
    
    // broadcasting APIs 
    enum Target 
    {
        case all(LayerController.Type)
    }
    
    private mutating 
    func notify(_ mutation:Context.Mutation, to target:Target, reset:Bool = false) 
    {
        switch target 
        {
        case .all(let metatype):
            for index:Int in self.controllers.indices where type(of: self.controllers[index]) == metatype
            {
                self.controllers[index].notify(mutation, in: self.context, reset: reset)
            }
        }
    }
}

protocol LayerController 
{
    var frame:Rectangle<Float> { get set }
    
    // context mutation notifier
    mutating 
    func notify(_:Coordinator.Context.Mutation, in:Coordinator.Context, reset:Bool)
    
    // geometric intersection function 
    func test(_ position:Vector2<Float>) -> Bool 
    
    // event handlers
    mutating 
    func character(_:Coordinator.Context, _ character:Character) -> Coordinator.Event?
    
    mutating 
    func keypress(_:Coordinator.Context, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
    
    mutating
    func scroll(_:Coordinator.Context, _ direction:UI.Direction, _ position:Vector2<Float>) -> Coordinator.Event?
    
    mutating 
    func down(_:Coordinator.Context, _ action:UI.Action, _ position:Vector2<Float>, doubled:Bool) -> Coordinator.Event?
    
    mutating 
    func move(_:Coordinator.Context, _ position:Vector2<Float>) -> Coordinator.Event?
    
    mutating 
    func leave(_:Coordinator.Context) -> Coordinator.Event?
    
    mutating 
    func up(_:Coordinator.Context, _ action:UI.Action, _ position:Vector2<Float>) -> Coordinator.Event?
    
    // stream-called functions
    mutating 
    func process(_:Coordinator.Context, _ delta:Int) -> Bool 
    
    mutating 
    func draw(_:Coordinator.Context, definitions:Style.Definitions)
}
extension LayerController 
{
    func notify(_:Coordinator.Context.Mutation, in _:Coordinator.Context, reset _:Bool)
    {
    }
    
    // default implementations (ignore all events)
    func test(_ position:Vector2<Float>) -> Bool 
    {
        return true 
    }
    
    func character(_:Coordinator.Context, _:Character) -> Coordinator.Event?
    {
        return nil 
    }
    func keypress(_:Coordinator.Context, _:UI.Key, _:UI.Key.Modifiers) -> Coordinator.Event?
    {
        return nil
    }
    func scroll(_:Coordinator.Context, _:UI.Direction, _:Vector2<Float>) -> Coordinator.Event?
    {
        return nil
    }
    func down(_:Coordinator.Context, _:UI.Action, _:Vector2<Float>, doubled _:Bool) -> Coordinator.Event?
    {
        return nil
    }
    func move(_:Coordinator.Context, _:Vector2<Float>) -> Coordinator.Event?
    {
        return nil
    }
    func leave(_:Coordinator.Context) -> Coordinator.Event?
    {
        return nil
    }
    func up(_:Coordinator.Context, _:UI.Action, _:Vector2<Float>) -> Coordinator.Event?
    {
        return nil
    }
    
    func process(_:Coordinator.Context, _:Int) -> Bool
    { 
        return false
    }
    func draw(_:Coordinator.Context, definitions _:Style.Definitions) 
    { 
    }
}

// Equatable conformance not required in base type definition to allow Latest<Void> 
// to work. Basic definition does not expose self.value, but there’s no point in 
// reading self.value if T is Void.
protocol ViewEquatable 
{
    static 
    func viewEquivalent(_:Self, _:Self) -> Bool 
}
struct Latest<T>
{
    private 
    var _value:T, 
        dirty:Bool 
    
    var isDirty:Bool 
    {
        return self.dirty
    }
    
    init(_ value:T) 
    {
        self._value = value 
        self.dirty  = true 
    }
    
    mutating 
    func reset() 
    {
        self.dirty = true
    }
    
    mutating 
    func pop() -> T? 
    {
        if self.dirty 
        {
            self.dirty = false 
            return self._value 
        }
        else 
        {
            return nil 
        }        
    }
    
    mutating 
    func get() -> T 
    {
        self.dirty = false 
        return self._value
    }
}
extension Latest where T:Equatable 
{
    var value:T 
    {
        get 
        {
            return self._value 
        }
        set(value)
        {
            if value != self._value  
            {
                self.dirty  = true 
            }
            self._value = value 
        }
    }
}
extension Latest where T:ViewEquatable
{
    var value:T 
    {
        get 
        {
            return self._value 
        }
        set(value)
        {
            if !T.viewEquivalent(value, self._value)  
            {
                self.dirty  = true 
            }
            self._value = value 
        }
    }
}

enum Controller
{
    struct MapEditor:LayerController
    {
        enum Action:Equatable
        {
            case    none,
                    anchorSelected(Int), 
                    anchorMoving(Int, Vector3<Float>), 
                    anchorNew(Int, Vector3<Float>)
        }
        
        // interface for communicating with Self.View 
        struct State 
        {
            var model:Latest<Void>
            
            var action:Latest<Action> 
            var preselection:Latest<Int?>
            
            var plane:ControlPlane
        }
        
        
        var frame:Rectangle<Float> = .zero
        {
            didSet 
            {
                self.plane.invalidate()
            }
        }
        
        
        private 
        var view:View, 
            state:State 
        
        // other properties 
        private 
        var hotspots:[Vector2<Float>?]
        
        // state variables 
        private 
        var action:Action 
        {
            get         { return    self.state.action.value }
            set(value)  {           self.state.action.value = value }
        }
        private 
        var preselection:Int? 
        {
            get         { return    self.state.preselection.value }
            set(value)  {           self.state.preselection.value = value }
        }
        
        private 
        var plane:ControlPlane 
        {
            get         { return    self.state.plane }
            set(value)  {           self.state.plane = value }
        }
        
        
        init()
        {
            let plane:ControlPlane = .init(  .init(center: .zero,
                                orientation: .identity,
                                   distance: 4,
                                focalLength: 32))
                                
            self.state  = .init(model: .init(()), 
                               action: .init(.none), 
                         preselection: .init(nil), 
                                plane: plane)
            self.view   = .init()
            
            self.hotspots = []
        }
        
        
        mutating 
        func notify(_ member:Coordinator.Context.Mutation, in context:Coordinator.Context, reset:Bool)
        {
            switch member 
            {
            case .viewport:
                self.plane.invalidate()
            
            case .model:
                self.state.model.reset() 
                if reset
                {
                    self.action         = .none
                    self.preselection   = nil 
                }
            }
        }
        
        
        func test(_ position:Vector2<Float>) -> Bool  
        {
            return true 
        }
        
        
        // project a sphere point into 2D
        private  
        func trace(_ point:Vector3<Float>, viewport:Vector2<Float>) -> Vector2<Float>?
        {
            guard (point - self.plane.position) <> (point - 0) < 0 
            else 
            {
                return nil 
            }
            
            return viewport * self.plane.trace(point)
        }
        
        private mutating 
        func updateHotspots(_ points:[Vector3<Float>], viewport:Vector2<Float>) 
        {
            self.hotspots = points.map 
            {
                self.trace($0, viewport: viewport)
            }
        }
        
        private mutating 
        func updateHotspot(_ point:Vector3<Float>, at index:Int, viewport:Vector2<Float>) 
        {
            self.hotspots[index] = self.trace(point, viewport: viewport)
        }
        
        private mutating 
        func insertHotspot(_ point:Vector3<Float>, at index:Int, viewport:Vector2<Float>) 
        {
            self.hotspots.insert(self.trace(point, viewport: viewport), at: index)
            self.reindex(after: index, offset: 1)
        }
        
        private mutating 
        func removeHotspot(at index:Int) 
        {
            self.hotspots.remove(at: index)
            self.reindex(after: index, offset: -1)
        }
        
        private mutating 
        func reindex(after index:Int, offset:Int) 
        {
            if let preselection:Int = self.preselection
            {
                if preselection > index 
                {
                    self.preselection = preselection + offset
                }
                else if preselection == index 
                {
                    self.preselection = nil
                }
            }
        }
        
        private 
        func findHotspot(_ position:Vector2<Float>, threshold:Float) -> Int? 
        {
            var g2:Float   = .infinity, 
                index:Int? = nil 
            for (i, hotspot):(Int, Vector2<Float>?) in self.hotspots.enumerated()
            {
                guard let hotspot:Vector2<Float> = hotspot 
                else 
                {
                    continue 
                }
                
                let r:Vector2<Float> = hotspot - position, 
                    r2:Float         = r <> r
                if  r2 < g2
                {
                    g2    = r2
                    index = i
                }
            }
            
            return g2 < threshold * threshold ? index : nil
        }
        
        mutating 
        func keypress(_ context:Coordinator.Context, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
        {
            switch key
            {
            case .up:
                self.plane.bump(.up,    action: .track)
            case .down:
                self.plane.bump(.down,  action: .track)
            case .left:
                self.plane.bump(.left,  action: .track)
            case .right:
                self.plane.bump(.right, action: .track)
            
            case .period:
                self.plane.jump(to: .zero)
            
            case .backspace, .delete:
                switch self.action 
                {
                case .none:
                    break 
                case .anchorSelected(let index):
                    if case .backspace = key 
                    {
                        if context.model.map.points.count > 1 
                        {
                            self.action = .anchorSelected((index == 0 ? context.model.map.points.count - 1 : index) - 1)
                        }
                        else 
                        {
                            self.action = .none 
                        }
                    }
                    else 
                    {
                        if context.model.map.points.count > 1 
                        {
                            self.action = .anchorSelected(index == context.model.map.points.count - 1 ? 0 : index)
                        }
                        else 
                        {
                            self.action = .none 
                        }
                    }
                    self.removeHotspot(at: index)
                    return .mapPointRemoved(index)
                
                case .anchorMoving(let index, _):
                    self.action = .none 
                    self.removeHotspot(at: index)
                    return .mapPointRemoved(index)
                case .anchorNew:
                    self.action = .none 
                }
            
            case .tab:
                switch self.action 
                {
                case .anchorSelected(let index):
                    let next:Int 
                    if modifiers.shift 
                    {
                        next = index - 1 < 0 ? context.model.map.points.count - 1 : index - 1
                    }
                    else 
                    {
                        next = index + 1 < context.model.map.points.count ? index + 1 : 0
                    }
                    self.action = .anchorSelected(next)
                
                default:
                    break
                }

            default:
                break
            }
            return nil
        }
        
        mutating
        func scroll(_:Coordinator.Context, _ direction:UI.Direction, _:Vector2<Float>) -> Coordinator.Event?
        {
            self.plane.bump(direction, action: .zoom)
            return nil
        }
        
        mutating 
        func down(_ context:Coordinator.Context, _ button:UI.Action, _ position:Vector2<Float>, doubled:Bool) -> Coordinator.Event?
        {
            switch button 
            {
            case .primary:
                if  doubled, 
                    case .anchorSelected(let index) = self.action
                {
                    let p:Vector3<Float> = self.plane.project(position, on: .zero, radius: 1).normalized()
                    self.action = .anchorNew(index + 1, p) 
                    break 
                }
                
                switch self.action 
                {
                case .none, .anchorSelected:
                    if let i:Int = self.findHotspot(position, threshold: 8) 
                    {
                        self.action = .anchorSelected(i)
                    }
                    else 
                    {
                        self.action = .none
                        self.plane.down(position, button: button)
                    }
                
                case .anchorMoving(let index, let location):
                    self.action = .anchorSelected(index)
                    self.updateHotspot(location, at: index, viewport: context.viewport)
                    return .mapPointMoved(index, location)
                
                case .anchorNew(let index, let location):
                    self.action = .anchorSelected(index)
                    self.insertHotspot(location, at: index, viewport: context.viewport)
                    return .mapPointAdded(index, location)
                }
            
            case .secondary:
                switch self.action 
                {
                case .none, .anchorSelected:
                    if let i:Int = self.findHotspot(position, threshold: 8) 
                    {
                        self.action = .anchorMoving(i, context.model.map.points[i])
                    }
                    else 
                    {
                        self.action = .none
                    }
                
                case .anchorMoving(let index, _), .anchorNew(let index, _):
                    self.action = .anchorSelected(index)
                }
            
            default:
                break
            }
            
            return nil
        }
        
        mutating 
        func move(_:Coordinator.Context, _ position:Vector2<Float>) -> Coordinator.Event?
        {
            // prevents meaningless preselection toggles, which needlessly set 
            // dirty flags in the state structure
            var preselection:Int? = nil 
            defer 
            {
                self.preselection = preselection
            }
            
            switch self.action 
            {
            case .none, .anchorSelected:
                if let i:Int = self.findHotspot(position, threshold: 8) 
                {
                    preselection = i
                }
            
                self.plane.move(position)
            
            case .anchorMoving(let index, _):
                let p:Vector3<Float> = self.plane.project(position, on: .zero, radius: 1).normalized()
                self.action = .anchorMoving(index, p)
            
            case .anchorNew(let index, _):
                let p:Vector3<Float> = self.plane.project(position, on: .zero, radius: 1).normalized()
                self.action = .anchorNew(index, p)
            }
            
            return nil
        }
        
        mutating 
        func leave(_:Coordinator.Context) -> Coordinator.Event? 
        {
            self.preselection = nil
            return nil 
        }
        
        mutating 
        func up(_:Coordinator.Context, _ button:UI.Action, _ position:Vector2<Float>) -> Coordinator.Event?
        {
            self.plane.up(position, button: button)
            return nil
        }
        
        mutating 
        func process(_ context:Coordinator.Context, _ delta:Int) -> Bool 
        {
            return self.plane.process(delta, viewport: context.viewport, frame: self.frame)
        }
        
        mutating 
        func draw(_ context:Coordinator.Context, definitions:Style.Definitions) 
        {
            if self.plane.mutated 
            {
                self.updateHotspots(context.model.map.points, viewport: context.viewport)
            }
            
            self.view.draw(context.model, definitions: definitions, state: &self.state)
        }
    }
}


extension Controller.MapEditor 
{
    struct View 
    {
        struct Globe
        {
            private 
            let vao:GL.VertexArray, 
                vbo:GL.Buffer<(Float, Float, Float)>,
                ebo:GL.Buffer<(UInt8, UInt8, UInt8)>
            
            init()
            {
                self.ebo = .generate()
                self.vbo = .generate()
                self.vao = .generate()

                let cube:[(Float, Float, Float)] =
                [
                     (-1, -1, -1),
                     ( 1, -1, -1),
                     ( 1,  1, -1),
                     (-1,  1, -1),

                     (-1, -1,  1),
                     ( 1, -1,  1),
                     ( 1,  1,  1),
                     (-1,  1,  1)
                ]
                
                // can’t use Vector3<UInt8> because of its 16 byte alignment 
                let indices:[(UInt8, UInt8, UInt8)] =
                [
                    (0, 2, 1),
                    (0, 3, 2),

                    (0, 1, 5),
                    (0, 5, 4),

                    (1, 2, 6),
                    (1, 6, 5),

                    (2, 3, 7),
                    (2, 7, 6),

                    (3, 0, 4),
                    (3, 4, 7),

                    (4, 5, 6),
                    (4, 6, 7)
                ]

                self.vbo.bind(to: .array)
                {
                    $0.data(cube, usage: .static)

                    self.vao.bind().setVertexLayout(.float(from: .float3))

                    self.ebo.bind(to: .elementArray)
                    {
                        $0.data(indices, usage: .static)
                        self.vao.unbind()
                    }
                }
            }
            
            func draw(_ model:Model.Map)
            {
                Programs.sphere.bind
                {
                    $0.set(float4: "sphere", .extend(.zero, 1))
                    model.background.bind(to: .texture2d, index: 1)
                    {
                        self.vao.drawElements(0 ..< 36, as: .triangles, indexType: UInt8.self)
                    }
                }
            }
        }
        
        struct Borders 
        {
            typealias Index = UInt32 
            
            @_fixed_layout
            @usableFromInline
            struct Vertex 
            {
                private 
                var storage:(x:Float, y:Float, z:Float, id:Int32)
                
                var position:Vector3<Float> 
                {
                    get 
                    {
                        return .init(self.storage.x, self.storage.y, self.storage.z)
                    }
                    set(v)
                    {
                        self.storage.x = v.x
                        self.storage.y = v.y
                        self.storage.z = v.z
                    }
                }
                var id:Int32 
                {
                    get 
                    {
                        return self.storage.id
                    }
                    set(id) 
                    {
                        self.storage.id = id
                    }
                }
                
                init(_ position:Vector3<Float>, id:Int)
                {
                    self.init(position, id: Int32(truncatingIfNeeded: id))
                }
                
                init(_ position:Vector3<Float>, id:Int32)
                {
                    self.storage = (position.x, position.y, position.z, id) 
                }
            }
            
            struct Indices
            {
                let indices:[Index]
                
                private 
                let partition:Int 
                
                var segments:(fixed:Range<Int>, interpolated:Range<Int>)
                {
                    let fixed:Range<Int>        = 0              ..< self.partition, 
                        interpolated:Range<Int> = self.partition ..< indices.count
                    return (fixed, interpolated)
                }
                
                init(fixed:[Index], interpolated:[Index]) 
                {
                    self.partition = fixed.count 
                    self.indices   = fixed + interpolated
                }
            }
            
            enum Selection:Equatable
            {
                // when adding cases UPDATE EQUATABLE CONFORMANCE
                case select(Int, Vector3<Float>)
                case move(Int, Vector3<Float>)
                case new(Vector3<Float>)
                case none
                
                func labelSphere(at offset:Vector3<Float>) -> (Vector3<Float>, [(Set<Style.Selector>, String)])?
                {
                    let selectors:Set<Style.Selector> = [.mapeditor, .label, .selection], 
                        bold:Set<Style.Selector> = selectors.union([.strong])
                    let parts:(String, String), 
                        point:Vector3<Float>, 
                        classes:Set<Style.Selector>
                    
                    switch self 
                    {
                    case    .select(let index, _), 
                            .move(let index, _):
                        parts.0 = "0:\(index)"
                                        
                    case .new:
                        parts.0 = "0:+"
                    
                    case .none:
                        return nil
                    }
                    
                    switch self 
                    {
                    case    .select(_, let location), 
                            .move(_, let location), 
                            .new(let location):
                        parts.1 = "   \(Selection.formatLL(.init(normalized: location)))"
                        point   = location + offset
                    
                    case .none:
                        return nil
                    }
                    
                    switch self 
                    {
                    case .select:
                        classes = []
                    case .move:
                        classes = [.move]
                                        
                    case .new:
                        classes = [.new]
                    
                    case .none:
                        return nil
                    }
                    
                    return (point, [(bold.union(classes), parts.0), (selectors.union(classes), parts.1)])
                }
                
                private static 
                func formatLL(_ s:Spherical2<Float>) -> String 
                {
                    let degreesN:Float = 90 - s.colatitude * (180 / Float.pi), 
                        degreesE:Float =      s.longitude  * (180 / Float.pi)
                    
                    let N:(d:Int, m:Int, s:Int) = sexagesimal(abs(degreesN)),
                        E:(d:Int, m:Int, s:Int) = sexagesimal(abs(degreesE))
                    
                    let Nm:String = padZero(N.m, to: 2), 
                        Ns:String = padZero(N.s, to: 2)
                    let Em:String = padZero(E.m, to: 2), 
                        Es:String = padZero(E.s, to: 2)
                    return "\(N.d)° \(Nm)′ \(Ns)′′ \(degreesN < 0 ? "S" : "N"), \(E.d)° \(Em)′ \(Es)′′ \(degreesE < 0 ? "W" : "E")"
                }
                
                private static 
                func sexagesimal(_ rd:Float) -> (d:Int, m:Int, s:Int) 
                {
                    let  s:Int                          = .init((60 * 60 * rd).rounded())
                    let (m,       seconds):(Int, Int)   = s.quotientAndRemainder(dividingBy: 60), 
                        (degrees, minutes):(Int, Int)   = m.quotientAndRemainder(dividingBy: 60)
                    
                    return (degrees, minutes, seconds)
                }
                
                private static 
                func padZero(_ x:Int, to count:Int) -> String 
                {
                    let string:String = .init(x)
                    return .init(repeating: "0", count: max(count - string.count, 0)) + string
                }
            }
            enum Preselection:Equatable 
            {
                case preselect(Int, Vector3<Float>)
                case occluded(Int)
                case none
                
                func labelSphere(at offset:Vector3<Float>) -> (Vector3<Float>, [(Set<Style.Selector>, String)])?
                {
                    let bold:Set<Style.Selector> = [.mapeditor, .label, .preselection, .strong]
                    switch self 
                    {
                    case .preselect(let index, let location):
                        return (offset + location, [(bold, "0:\(index)")])
                    
                    case .occluded, .none:
                        return nil
                    }
                }
            }
            
            private 
            let vao:GL.VertexArray
            private 
            var vvo:GL.Vector<Vertex>, 
                evo:GL.Vector<Index>
                
            private 
            var textvao:GL.VertexArray, 
                textvvo:GL.Vector<Text.Vertex>
                
            private 
            var indexSegments:(fixed:Range<Int>, interpolated:Range<Int>)
            
            private 
            var selection:Selection         = .none, 
                preselection:Preselection   = .none
            
            // whether the constructued border geometry deviates from the model
            private 
            var deviance:Bool = false 
            
            init()
            {
                self.evo = .generate()
                self.vvo = .generate()
                self.vao = .generate()
                self.textvao = .generate()
                self.textvvo = .generate()
                
                self.indexSegments = (0 ..< 0, 0 ..< 0)
                
                self.vvo.buffer.bind(to: .array)
                {
                    self.vao.bind().setVertexLayout(.float(from: .float3), .int(from: .int))
                    self.evo.buffer.bind(to: .elementArray)
                    {
                        self.vao.unbind()
                    }
                }
                
                self.textvvo.buffer.bind(to: .array)
                {
                    self.textvao.bind().setVertexLayout(
                        .float(from: .float2), 
                        .float(from: .float2), 
                        .float(from: .float3), 
                        .float(from: .ubyte4_rgba))
                    self.textvao.unbind()
                }
            }
            
            private static 
            func subdivide(_ loops:[[Vertex]], resolution:Float = 0.1) 
                -> (vertices:[Vertex], indices:Indices)
            {
                var vertices:[Vertex] = [], 
                    indices:(fixed:[Index], interpolated:[Index]) = ([], []) 
                for loop:[Vertex] in loops
                {
                    let base:Index = .init(vertices.count) 
                    for j:Int in loop.indices
                    {
                        let i:Int = loop.index(before: j == loop.startIndex ? loop.endIndex : j)
                        // get two vertices and angle between
                        let edge:(Vertex, Vertex) = (loop[i], loop[j])
                        let d:Float     = edge.0.position <> edge.1.position, 
                            z:Float     = Float.Math.acos(d.clipped(to: -1 ... 1)), 
                            scale:Float = 1 / (1 - d * d).squareRoot()
                        // determine subdivisions 
                        let subdivisions:Int = .init(z / resolution) + 1
                        
                        // push the fixed vertex 
                        indices.fixed.append(.init(vertices.count))
                        vertices.append(edge.0)
                        // push the interpolated vertices 
                        for s:Int in 1 ..< subdivisions
                        {
                            let t:Float = .init(s) / .init(subdivisions)
                            
                            // slerp!
                            let sines:Vector2<Float>   = Vector2.Math.sin(.init(z - z * t, z * t)), 
                                factors:Vector2<Float> = scale * sines
                            
                            let components:(Vector3<Float>, Vector3<Float>) 
                            components.0 = factors.x * edge.0.position 
                            components.1 = factors.y * edge.1.position 
                            
                            let interpolated:Vector3<Float> = components.0 + components.1
                            
                            vertices.append(.init(interpolated, id: edge.0.id))
                        }
                    }
                    
                    // compute lines-adjacency indices
                    let totalDivisions:Index = .init(vertices.count) - base
                    for primitive:Index in 0 ..< totalDivisions
                    {
                        indices.interpolated.append(base +  primitive    )
                        indices.interpolated.append(base + (primitive + 1) % totalDivisions)
                        indices.interpolated.append(base + (primitive + 2) % totalDivisions)
                        indices.interpolated.append(base + (primitive + 3) % totalDivisions)
                    }
                }
                
                return (vertices, .init(fixed: indices.fixed, interpolated: indices.interpolated))
            }
            
            mutating 
            func rebuild(_ loops:[[Vertex]]) 
            {
                let (vertices, indices):([Vertex], Indices) = Borders.subdivide(loops)
                self.vvo.assign(data: vertices,        in: .array,        usage: .dynamic)
                self.evo.assign(data: indices.indices, in: .elementArray, usage: .dynamic)
                
                self.indexSegments = indices.segments
            }
            
            mutating 
            func draw(_ model:Model.Map, definitions:Style.Definitions, state controllerState:inout State) 
            {
                let preselection:Preselection, 
                    selection:Selection
                rebuild:
                if let action:Action = controllerState.action.pop()
                {
                    let controlPoints:[Vertex]
                    
                    switch action
                    {
                    case .none:
                        selection = .none
                        
                        if controllerState.model.pop() != nil || self.deviance 
                        {
                            controlPoints = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                            self.deviance = false
                        }
                        else 
                        {
                            break rebuild 
                        }
                    
                    case .anchorSelected(let index):
                        selection = .select(index, model.points[index])
                        
                        if controllerState.model.pop() != nil || self.deviance 
                        {
                            controlPoints = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                            self.deviance = false
                        }
                        else 
                        {
                            break rebuild
                        }
                    
                    case .anchorMoving(let index, let position):
                        // get() call clears dirty flag
                        controllerState.model.get() 
                        
                        selection = .move(index, position)
                        
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed[index].position   = position
                        controlPoints           = fixed
                        
                        self.deviance = true
                    
                    case .anchorNew(let index, let position):
                        controllerState.model.get() 
                        
                        selection = .new(position)
                        
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed.insert(.init(position, id: -1), at: index)
                        controlPoints           = fixed
                        
                        self.deviance = true
                    }
                    
                    self.rebuild([controlPoints])
                }
                else if controllerState.model.pop() != nil
                {
                    selection = self.selection 
                    self.rebuild([model.points.enumerated().map{ .init($0.1, id: $0.0) }])
                    self.deviance = false 
                }
                else 
                {
                    selection = self.selection
                }
                
                // clear preselection if both the selection and preselection point 
                // to the same vertex
                let selectionIndex:Int?, 
                    preselectionIndex:Int?
                switch selection 
                {
                case    .select(let index, _), 
                        .move(let index, _):
                    selectionIndex = index
                
                case    .new, .none:
                    selectionIndex = nil 
                }
                
                if let update:Int? = controllerState.preselection.pop() 
                {
                    preselectionIndex = update 
                }
                else 
                {
                    switch self.preselection 
                    {
                    case    .preselect(let index, _), 
                            .occluded(let index):
                        preselectionIndex = index 
                    case    .none:
                        preselectionIndex = nil 
                    }
                }
                
                if let i1:Int = preselectionIndex 
                {
                    if let i2:Int = selectionIndex, i1 == i2 
                    {
                        preselection = .occluded(i1)
                    }
                    else 
                    {
                        preselection = .preselect(i1, model.points[i1])
                    }
                }
                else 
                {
                    preselection = .none
                }
                
                if selection != self.selection || preselection != self.preselection 
                {
                    var textVertices:[Text.Vertex]  = []
                    if let (point, label):(Vector3<Float>, [(Set<Style.Selector>, String)]) = 
                        selection.labelSphere(at: .zero) 
                    {
                        let text:Text = definitions.line(label) 
                        textVertices.append(contentsOf: text.vertices(at: .init(20, 20), tracing: point))
                    } 
                    if let (point, label):(Vector3<Float>, [(Set<Style.Selector>, String)]) = 
                        preselection.labelSphere(at: .zero) 
                    {
                        let text:Text = definitions.line(label) 
                        textVertices.append(contentsOf: text.vertices(at: .init(20, 20), tracing: point))
                    } 
                    
                    self.textvvo.assign(data: textVertices, in: .array, usage: .dynamic)
                    
                    self.selection     = selection 
                    self.preselection  = preselection 
                }
                
                Programs.borderPolyline.bind 
                {
                    $0.set(float:  "thickness", 2)
                    $0.set(float4: "frontColor", .init(0.5, 0.5, 0.5, 1))
                    $0.set(float4: "backColor",  .init(0.1, 0.1, 0.1, 1))
                    self.vao.drawElements(self.indexSegments.interpolated, as: .linesAdjacency, indexType: Index.self)
                }
                
                Programs.borderNodes.bind 
                {
                    let indicator:Int32
                    switch self.selection 
                    {
                        case .select(let index, _):
                            indicator = .init(index) << 1 | 0
                        
                        case .move(let index, _):
                            indicator = .init(index) << 1 | 1
                        
                        case .new, .none:
                            indicator = -1
                    }
                    let preselection:Int32
                    switch self.preselection 
                    {
                        case .preselect(let index, _):
                            preselection = .init(index)
                        
                        case .occluded, .none:
                            preselection = -1
                    }
                    $0.set(int: "indicator",    indicator)
                    $0.set(int: "preselection", preselection)
                    self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                }
                
                Programs.tracingText.bind 
                {
                    _ in 
                    definitions.atlas.texture.bind(to: .texture2d, index: 2)
                    {
                        self.textvao.draw(0 ..< self.textvvo.count, as: .lines)
                    }
                }
            }
        }
        
        private 
        var globe:Globe, 
            borders:Borders
        
        private 
        let cameraBlock:UBO.CameraBlock
        
        private 
        var textvao:GL.VertexArray, 
            textvvo:GL.Vector<Text.Vertex>, 
            textRendered:Bool = false 
        
        init()
        {
            self.globe   = .init()
            self.borders = .init()
            
            self.cameraBlock = .init()
            
            self.textvao = .generate()
            self.textvvo = .generate()
            
            self.textvvo.buffer.bind(to: .array)
            {
                self.textvao.bind().setVertexLayout(
                    .float(from: .float2), 
                    .float(from: .float2), 
                    .padding(3 * MemoryLayout<Float>.size), 
                    .float(from: .ubyte4_rgba))
                self.textvao.unbind()
            }
        }
        
        mutating 
        func draw(_ model:Model, definitions:Style.Definitions, state controllerState:inout State)
        {
            if !textRendered 
            {
                let runs:[(Set<Style.Selector>, String)] = 
                [
                    ([],                    "012345 Hello world! "), 
                    ([.emphasis],           "This text is italic! There \n\nonce was a girl known by "), 
                    ([.emphasis, .strong],  "everyone"), 
                    ([.strong],             " and no one. efficiency. 012345") 
                ]
                
                let text:Text = definitions.paragraph(runs, linebox: .init(150, 20), block: [.paragraph])
                self.textvvo.assign(data: text.vertices(at: .init(20, 20)), in: .array, usage: .static)
                textRendered = true 
            }
            
            self.cameraBlock.bind(index: 1)
            {
                // check if camera needs updating
                if let matrices:Camera.Matrices = controllerState.plane.pop()
                {
                    UBO.CameraBlock.encode(matrices: matrices, to: $0)
                    Log.note("camera updated")
                }
                
                GL.enable(.culling)
                
                GL.disable(.multisampling)
                
                GL.enable(.blending)
                GL.blend(.mix)
                self.globe.draw(model.map) 
                
                GL.enable(.multisampling)
                GL.blend(.add)
                self.borders.draw(model.map, definitions: definitions, state: &controllerState)
            }
            
            Programs.text.bind 
            {
                _ in 
                definitions.atlas.texture.bind(to: .texture2d, index: 2)
                {
                    self.textvao.draw(0 ..< self.textvvo.count, as: .lines)
                }
            }
        }
    }
}

/* enum Layout 
{
    enum Element 
    {
        case block(Block)
        case inlineBlock(InlineBlock)
        case inline(Inline)
    }
    
    struct Block 
    {
        var children:[Element]
    }
    struct InlineBlock 
    {
        var children:[Element]
    }
} */
