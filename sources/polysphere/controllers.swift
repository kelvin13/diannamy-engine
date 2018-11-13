import PNG

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
        var points:[Math<Float>.V3]
        
        var background:GL.Texture<PNG.RGBA<UInt8>>
        
        init(normalizing points:[Math<Float>.V3])
        {
            self.points = points.map(Math.normalize(_:))
            self.background = .generate()
            
            // generate checkerboard
            let image:Array2D<PNG.RGBA<UInt8>> = .init(shape: (16, 16)) 
            {
                ($0.y & 1 + $0.x) & 1 == 0 ? .init(60, .max) : .init(200, .max)
            }
            
            self.background.bind(to: .texture2d)
            {
                $0.data(image, layout: .rgba8, storage: .rgba8)
                $0.setMagnificationFilter(.nearest)
                $0.setMinificationFilter(.nearest, mipmap: nil)
            }
        }
        
        mutating 
        func replace(background path:String) -> String?
        {
            // "/home/klossy/downloads/world.topo.bathy.png"
            guard let (image, size):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
                try? PNG.rgba(path: path, of: UInt8.self)
            else 
            {
                return "could not read file '\(path)'"
            }
            
            self.background.bind(to: .texture2d)
            {
                $0.data(.init(image, shape: size), layout: .rgba8, storage: .rgba8)
                $0.setMagnificationFilter(.linear)
                $0.setMinificationFilter(.linear, mipmap: .linear)
                $0.generateMipmaps()
            }
            
            return nil
        }
        
        func findNearest(to location:Math<Float>.V3, threshold:Float) -> Int? 
        {
            var gamma:Float = -1, 
                index:Int?  = nil 
            for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
            {
                let g:Float = Math.dot(point, location)
                if g > gamma 
                {
                    gamma = g
                    index = i
                }
            }
            
            return gamma > Float.cos(threshold) ? index : nil
        }
    }
    
    var log:Log 
    var map:Map
    
    init() 
    {
        self.log = .init()
        self.map = .init(normalizing: [(0, 1, 1), (1, 0, 1), (0, -1, 1), (-1, 0, 1)])
        
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
                guard arguments.count == 2
                else 
                {
                    self.log.print("Usage: mapedit background FILENAME")
                    return nil
                }
                
                let filename:String = arguments[1]
                
                self.map.replace(background: filename).map{ self.log.print($0) }
            
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
    enum Event 
    {
        case toggleTerminal
        case terminalInput([Unicode.Scalar])
        
        case mapPointMoved(Int, Math<Float>.V3)
        case mapPointAdded(Int, Math<Float>.V3)
        case mapPointRemoved(Int)
    }
    
    var controller:Controller.Root, 
        model:Model
        
    init()
    {
        self.model = .init()
        self.controller = .init()
        
        self.handle(self.model.input("mapedit background /home/klossy/downloads/world.topo.bathy.png"))
        
        self.controller.sync(to: self.model)
    }
    
    mutating
    func resize(to size:Math<Float>.V2)
    {
        GL.viewport(anchor: (0, 0), size: Math.cast(size, as: Int.self))
        self.controller.setViewport(self.model, size)
    }
    
    mutating 
    func char(_ codepoint:Unicode.Scalar) 
    {
        self.handle(self.controller.char(self.model, codepoint))
    }
    
    mutating 
    func keypress(_ key:UI.Key, _ modifiers:UI.Key.Modifiers) 
    {
        self.handle(self.controller.keypress(self.model, key, modifiers))
    }
    
    mutating 
    func scroll(_ direction:UI.Direction) 
    {
        self.handle(self.controller.scroll(self.model, direction))
    }
    
    mutating 
    func down(_ action:UI.Action, _ position:Math<Float>.V2) 
    {
        self.handle(self.controller.down(self.model, action, position))
    }
    
    mutating 
    func move(_ position:Math<Float>.V2) 
    {
        self.handle(self.controller.move(self.model, position))
    }
    
    mutating 
    func up(_ action:UI.Action, _ position:Math<Float>.V2) 
    {
        self.handle(self.controller.up(self.model, action, position))
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
            self.controller.toggleTerminal()
            
        case .terminalInput(let input):
            self.handle(self.model.input(input))
            self.controller.terminal.sync(to: self.model)
        
        case .mapPointMoved(let index, let location):
            self.model.map.points[index] = Math.normalize(location)
            self.controller.mapEditor.sync(to: self.model)
        
        case .mapPointAdded(let index, let location):
            self.model.map.points.insert(Math.normalize(location), at: index)
            self.controller.mapEditor.sync(to: self.model)
        
        case .mapPointRemoved(let index):
            self.model.map.points.remove(at: index)
            self.controller.mapEditor.sync(to: self.model)
        }
    }
    
    mutating 
    func process(_ delta:Int) 
    {
        self.controller.process(self.model, delta)
    }
    
    mutating 
    func draw() 
    {
        self.controller.draw(self.model)
    }
}

enum Controller
{
    struct Root 
    {
        enum State 
        {
            case    terminal, 
                    mapEditor 
        }
        var terminal:Terminal, 
            mapEditor:MapEditor, 
            
            state:State
        
        init() 
        {
            self.terminal  = .init()
            self.mapEditor = .init()
            
            self.state     = .terminal
        }
        
        mutating 
        func setViewport(_ model:Model, _ viewport:Math<Float>.V2) 
        {
            self.terminal .setViewport(model, viewport)
            self.mapEditor.setViewport(model, viewport)
        }
        
        mutating 
        func toggleTerminal() 
        {
            switch self.state 
            {
                case .terminal:
                    self.state = .mapEditor 
                case .mapEditor:
                    self.state = .terminal
            }
        }
        
        mutating 
        func char(_ model:Model, _ codepoint:Unicode.Scalar) -> Coordinator.Event?
        {
            switch self.state
            {
                case .mapEditor:
                    return nil 
                case .terminal:
                    return self.terminal.char(model, codepoint)
            }
        }
        
        mutating 
        func keypress(_ model:Model, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
        {
            if  key == .one, 
                modifiers.control
            {
                return .toggleTerminal
            }
            
            switch self.state
            {
                case .mapEditor:
                    return self.mapEditor.keypress(model, key, modifiers)
                case .terminal:
                    return self.terminal.keypress(model, key, modifiers)
            }
        }
        
        mutating
        func scroll(_ model:Model, _ direction:UI.Direction) -> Coordinator.Event?
        {
            return self.mapEditor.scroll(model, direction)
        }
        
        mutating 
        func down(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.down(model, action, position)
        }
        
        mutating 
        func move(_ model:Model, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.move(model, position)
        }
        
        mutating 
        func up(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.up(model, action, position)
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.terminal.sync(to: model)
            self.mapEditor.sync(to: model)
        }
        
        mutating 
        func process(_ model:Model, _ delta:Int) 
        {
            self.mapEditor.process(model, delta)
        }
        
        mutating 
        func draw(_ model:Model)
        {
            GL.clear(color: true, depth: true)
            self.mapEditor.draw(model)
            if case .terminal = self.state 
            {
                self.terminal.draw(model)
            }
        }
    }
    
    struct Terminal 
    {
        private 
        var input:[Unicode.Scalar], 
            cursor:Int, 
        
            area:Math<Float>.Rectangle, 
            viewport:Math<Float>.V2, 
        
            view:View 
        
        private 
        var history:[[Unicode.Scalar]] = [], 
            historyIndex:Int? = nil
        
        init()
        {
            self.input  = []
            self.cursor = self.input.endIndex
            
            self.area   = ((0, 0), (0, 0))
            self.viewport = (0, 0)
            
            self.view   = .init()
        }
        
        private 
        func composeText(_ log:Model.Log) -> [(Unicode.Scalar, Math<UInt8>.V4)] 
        {
            return log.contents.map{ ($0, (100, 255, 255, 255)) } + self.input.map{ ($0, (.max, .max, .max, .max)) }
        }
        
        private 
        func layout(_ text:[(Unicode.Scalar, Math<UInt8>.V4)], atlas:FontAtlas) 
            -> (layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], template:Math<Float>.Rectangle)
        {
            let delta64:Math<Int>.V2 = Math.maskUp((atlas["\u{0}"].advance64, atlas.height64), exponent: 6), 
                linelength:Int       = Int(self.area.b.x - self.area.a.x) / (delta64.x >> 6)
            
            let cursorIndex:Int = text.endIndex - self.input.count + self.cursor
            
            var line:Int = 0, 
                layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)] = []
                layout.reserveCapacity(text.count + 1)
            var n:Int = text.endIndex
            while line < Int(self.area.b.y - self.area.a.y) / (delta64.y >> 6)
            {
                guard n >= text.startIndex 
                else 
                {
                    break
                }
                
                var begin:Int = n - 1
                split: 
                while begin >= text.startIndex 
                {
                    switch text[begin].0
                    {    
                    case "\r":
                        line  -= 1
                        fallthrough
                    case "\n":
                        break split 
                    default:
                        begin -= 1
                    }
                }
                
                // count how many physical lines this line will span 
                let height:Int = (n - begin) / linelength + ((n - begin) % linelength).signum()
                line += height
                
                var position:Math<Int>.V2 = (0, line)
                for (codepoint, color):(Unicode.Scalar, Math<UInt8>.V4) in text[begin + 1 ..< n] 
                {
                    if position.x == linelength 
                    {
                        position.x  = 0
                        position.y -= 1
                    }
                    
                    layout.append((codepoint, color, position))
                    
                    position.x += 1
                }
                
                // place cursor 
                if begin + 1 ... n ~= cursorIndex 
                {
                    let offset:Int = cursorIndex - begin - 1
                    
                    layout.append(("_", (0, 255, 255, .max), (offset % linelength, line - offset / linelength)))
                }
                
                n = begin
            }
            
            let delta:Math<Float>.V2  = Math.cast((delta64.x >> 6, delta64.y >> 6), as: Float.self), 
                origin:Math<Float>.V2 = Math.round(self.area.a)
            
            return (layout, (origin, Math.add(origin, delta)))
        }
        
        private mutating 
        func show(with model:Model) 
        {
            let atlas:FontAtlas = Fonts.terminal.atlas
            let (layout, template):([(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], Math<Float>.Rectangle) = 
                self.layout(self.composeText(model.log), atlas: atlas)
            self.view.render(layout, template: template, atlas: atlas)
        }
        
        mutating 
        func setViewport(_ model:Model, _ viewport:Math<Float>.V2) 
        {
            // figure out center point of screen
            let a:Math<Float>.V2 = (20,                                                              20), 
                b:Math<Float>.V2 = (max((viewport.x * 0.5).rounded() - 20, 30), max(viewport.y - 20, 30))
            self.area = (a, b)
            
            self.show(with: model)
            
            self.viewport = viewport
        }
        
        mutating 
        func char(_ model:Model, _ codepoint:Unicode.Scalar) -> Coordinator.Event?
        {
            self.input.insert(codepoint, at: self.cursor)
            self.cursor += 1
            
            self.show(with: model)
            
            return nil
        }
        mutating 
        func keypress(_ model:Model, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
        {
            switch key 
            {
                case .enter:
                    self.history.append(self.input)
                    self.historyIndex = nil
                    
                    self.input.append("\n")
                    return .terminalInput(self.input)
                
                case .backspace:
                    guard self.cursor > self.input.startIndex 
                    else 
                    {
                        break
                    } 
                    
                    self.cursor -= 1
                    self.input.remove(at: self.cursor)
                    
                    self.show(with: model)
                
                case .left:
                    guard self.cursor > self.input.startIndex  
                    else 
                    {
                        break
                    }
                    
                    self.cursor -= 1
                    self.show(with: model)
                
                case .right:
                    guard self.cursor < self.input.endIndex
                    else 
                    {
                        break
                    }
                    
                    self.cursor += 1
                    self.show(with: model)
                
                case .up:
                    let index:Int = (self.historyIndex ?? self.history.endIndex) - 1 
                    
                    guard index >= 0 
                    else 
                    {
                        break 
                    }
                    
                    self.input = self.history[index]
                    self.cursor = self.input.endIndex
                    self.historyIndex = index
                    self.show(with: model)
                
                case .down:
                    break
                
                default:
                    break
            }
            
            return nil
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.input  = []
            self.cursor = self.input.startIndex
            
            self.show(with: model)
        }
        
        mutating 
        func draw(_ model:Model)
        {
            self.view.draw(viewport: self.viewport)
        }
    }
    
    struct MapEditor 
    {
        enum State 
        {
            case    none,
                    anchorSelected(Int), 
                    anchorMoving(Int, Math<Float>.V3), 
                    anchorNew(Int, Math<Float>.V3)
        }
        
        private 
        var state:State, 
            preselection:Int?
        
        private 
        var plane:ControlPlane, 
            cameraBlock:GL.Buffer<Camera.Storage>, 
            
            U:Math<Float>.Mat4, 
            hotspots:[Math<Float>.V2?]
        
        private 
        var view:View 
        
        init()
        {
            self.state        = .none 
            self.preselection = nil
            
            self.plane = .init(.init(center: (0, 0, 0),
                                orientation: .init(),
                                   distance: 4,
                                focalLength: 32))
            
            self.cameraBlock = .generate()
            self.cameraBlock.bind(to: .uniform)
            {
                $0.reserve(capacity: 1, usage: .dynamic)
            }
            
            self.U        = ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1))
            self.hotspots = []
            
            self.view = .init()
        }
        
        mutating 
        func setViewport(_ model:Model, _ viewport:Math<Float>.V2) 
        {
            // figure out center point of screen
            let shift:Math<Float>.V2 = Math.scale(viewport, by: -0.5)
            self.plane.sensor = (shift, Math.add(viewport, shift))
        }
        
        private  
        func trace(_ point:Math<Float>.V3) -> Math<Float>.V2?
        {
            guard Math.dot(Math.sub(point, self.plane.rayfilm.source), Math.sub(point, (0, 0, 0))) < 0 
            else 
            {
                return nil 
            }
            
            let h:Math<Float>.V4 = Math.mult(self.U, Math.extend(point, 1))
            return Math.scale((h.x, h.y), by: 1 / h.w)
        }
        
        private mutating 
        func updateHotspots(_ points:[Math<Float>.V3]) 
        {
            self.hotspots = points.map(self.trace(_:))
        }
        
        private mutating 
        func updateHotspot(_ point:Math<Float>.V3, at index:Int) 
        {
            self.hotspots[index] = self.trace(point)
        }
        
        private mutating 
        func insertHotspot(_ point:Math<Float>.V3, at index:Int) 
        {
            self.hotspots.insert(self.trace(point), at: index)
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
                    self.view.borders.push(preselection: preselection + offset)
                }
                else if preselection == index 
                {
                    self.preselection = nil
                    self.view.borders.push(preselection: nil)
                }
            }
        }
        
        private 
        func findHotspot(_ position:Math<Float>.V2, threshold:Float) -> Int? 
        {
            let scale:Math<Float>.V2 = Math.sub(self.plane.sensor.1, self.plane.sensor.0), 
                p:Math<Float>.V2     = Math.add(position, self.plane.sensor.0)
            
            var g:Float    = .infinity, 
                index:Int? = nil 
            for (i, hotspot):(Int, Math<Float>.V2?) in self.hotspots.enumerated()
            {
                guard let hotspot:Math<Float>.V2 = hotspot 
                else 
                {
                    continue 
                }
                
                let r:Float = Math.length(Math.sub(Math.mult(Math.scale(hotspot, by: 0.5), scale), p))
                if r < g
                {
                    g     = r
                    index = i
                }
            }
            
            return g < threshold ? index : nil
        }
        
        mutating 
        func keypress(_ model:Model, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
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
                self.plane.jump(to: (0, 0, 0))
            
            case .backspace, .delete:
                switch self.state 
                {
                case .none:
                    break 
                case .anchorSelected(let index):
                    self.state = .none 
                    self.removeHotspot(at: index)
                    return .mapPointRemoved(index)
                case .anchorMoving, .anchorNew:
                    self.state = .none 
                    self.view.borders.push(state: self.state, model: model.map, sync: true)
                }
            
            case .tab:
                switch self.state 
                {
                case .anchorSelected(let index):
                    let next:Int 
                    if modifiers.shift 
                    {
                        next = index - 1 < 0 ? model.map.points.count - 1 : index - 1
                    }
                    else 
                    {
                        next = index + 1 < model.map.points.count ? index + 1 : 0
                    }
                    self.state = .anchorSelected(next)
                    self.view.borders.push(state: self.state, model: model.map)
                
                default:
                    break
                }

            default:
                break
            }
            return nil
        }
        
        mutating
        func scroll(_ model:Model, _ direction:UI.Direction) -> Coordinator.Event?
        {
            self.plane.bump(direction, action: .zoom)
            return nil
        }
        
        mutating 
        func down(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            let _ = self.move(model, position)
            switch action 
            {
                case .double:
                    switch self.state 
                    {
                        case .anchorSelected(let index):
                            let ray:ControlPlane.Ray = self.plane.rayfilm.cast(position), 
                                p:Math<Float>.V3     = ControlPlane.project(ray: ray, on: (0, 0, 0), radius: 1)
                            self.state = .anchorNew(index + 1, Math.normalize(p))
                            self.view.borders.push(state: self.state, model: model.map)
                        
                        default:
                            break 
                    }
                
                case .primary:
                    switch self.state 
                    {
                        case .none, .anchorSelected:
                            if let i:Int = self.findHotspot(position, threshold: 8) 
                            {
                                self.state = .anchorSelected(i)
                            }
                            else 
                            {
                                self.state = .none
                                self.plane.down(position, action: action)
                            }
                            
                            self.view.borders.push(state: self.state, model: model.map)
                        
                        case .anchorMoving(let index, let location):
                            self.state = .anchorSelected(index)
                            self.updateHotspot(location, at: index)
                            return .mapPointMoved(index, location)
                        
                        case .anchorNew(let index, let location):
                            self.state = .anchorSelected(index)
                            self.insertHotspot(location, at: index)
                            return .mapPointAdded(index, location)
                    }
                
                case .secondary:
                    switch self.state 
                    {
                        case .none, .anchorSelected:
                            if let i:Int = self.findHotspot(position, threshold: 8) 
                            {
                                self.state = .anchorMoving(i, model.map.points[i])
                            }
                            else 
                            {
                                self.state = .none
                            }
                            
                            self.view.borders.push(state: self.state, model: model.map)
                        
                        case .anchorMoving(let index, _), .anchorNew(let index, _):
                            self.state = .anchorSelected(index)
                            
                            self.view.borders.push(state: self.state, model: model.map, sync: true)
                    }
                
                default:
                    break
            }
            
            return nil
        }
        
        mutating 
        func move(_ model:Model, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.preselection = nil
            self.view.borders.push(preselection: nil)
            switch self.state 
            {
            case .none, .anchorSelected:
                if let i:Int = self.findHotspot(position, threshold: 8) 
                {
                    self.preselection = i
                    self.view.borders.push(preselection: i)
                }
            
                self.plane.move(position)
            
            case .anchorMoving(let index, _):
                let ray:ControlPlane.Ray = self.plane.rayfilm.cast(position), 
                    p:Math<Float>.V3 = ControlPlane.project(ray: ray, on: (0, 0, 0), radius: 1)
                self.state = .anchorMoving(index, Math.normalize(p))
                self.view.borders.push(state: self.state, model: model.map)
            
            case .anchorNew(let index, _):
                let ray:ControlPlane.Ray = self.plane.rayfilm.cast(position), 
                    p:Math<Float>.V3 = ControlPlane.project(ray: ray, on: (0, 0, 0), radius: 1)
                self.state = .anchorNew(index, Math.normalize(p))
                self.view.borders.push(state: self.state, model: model.map)
            }
            return nil
        }
        
        mutating 
        func up(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.up(position, action: action)
            return nil
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.view.borders.push(state: self.state, model: model.map, sync: true)
        }
        
        mutating 
        func process(_ model:Model, _ delta:Int) 
        {
            self.plane.process(delta)
        }
        
        mutating 
        func draw(_ model:Model) 
        {
            self.cameraBlock.bind(to: .uniform, index: 0)
            {
                (target:GL.Buffer.BoundTarget) in

                // check if camera needs updating
                if let camera:Camera = self.plane.pop() 
                {
                    camera.withUnsafeBytes
                    {
                        target.subData($0)
                    }
                    
                    self.view.draw(model)
                    
                    self.U = camera.U
                    self.updateHotspots(model.map.points)
                }
                else 
                {
                    self.view.draw(model)
                }
            }
        }
    }
}

extension Controller.Terminal 
{
    struct View 
    {
        @_fixed_layout
        @usableFromInline
        struct Vertex 
        {
            var xy:Math<Float>.V2, 
                uv:Math<Float>.V2, 
                
                color:Math<UInt8>.V4
            
            init(_ xy:Math<Float>.V2, uv:Math<Float>.V2, color:Math<UInt8>.V4)
            {
                self.xy = xy
                self.uv = uv
                self.color = color
            }
        }
        
        private 
        let vao:GL.VertexArray
        var vvo:GL.Vector<Math<Vertex>.V2>
        
        init() 
        {
            self.vao = .generate()
            self.vvo = .generate()
            
            self.vvo.buffer.bind(to: .array)
            {
                self.vao.bind().setVertexLayout(.float(from: .float2), .float(from: .float2), .float(from: .ubyte4_rgba))
                self.vao.unbind()
            }
        }
        
        mutating 
        func render(_ layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], template:Math<Float>.Rectangle, atlas:FontAtlas) 
        {
            let delta:Math<Float>.V2        = Math.sub(template.b, template.a), 
                glyphs:[Math<Vertex>.V2]    = layout.map 
            {
                let origin:Math<Float>.V2   = 
                    Math.add(template.a, Math.mult(delta, Math.cast($0.2, as: Float.self)))
                
                let glyph:FontAtlas.Glyph   = atlas[$0.0]
                
                return 
                    (
                        .init(Math.add(origin, Math.cast(glyph.rectangle.a, as: Float.self)), uv: glyph.uv.a, color: $0.1), 
                        .init(Math.add(origin, Math.cast(glyph.rectangle.b, as: Float.self)), uv: glyph.uv.b, color: $0.1)
                    )
            }
            
            self.vvo.assign(data: glyphs, in: .array, usage: .dynamic)
        }
        
        func draw(viewport:Math<Float>.V2) 
        {
            Programs.text.bind 
            {
                $0.set(float2: "viewport", viewport)
                Fonts.terminal.texture.bind(to: .texture2d, index: 2)
                {
                    self.vao.draw(0 ..< self.vvo.count << 1, as: .lines)
                }
            }
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
                vbo:GL.Buffer<Math<Float>.V3>,
                ebo:GL.Buffer<Math<UInt8>.V3>
            
            init()
            {
                self.ebo = .generate()
                self.vbo = .generate()
                self.vao = .generate()

                let cube:[Math<Float>.V3] =
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

                let indices:[Math<UInt8>.V3] =
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
            
            func draw(_ model:Model)
            {
                Programs.sphere.bind
                {
                    $0.set(float4: "sphere", (0, 0, 0, 1))
                    model.map.background.bind(to: .texture2d, index: 1)
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
                var position:Math<Float>.V3, 
                    id:Int32
                
                init(_ position:Math<Float>.V3, id:Int)
                {
                    self.init(position, id: Int32(truncatingIfNeeded: id))
                }
                
                init(_ position:Math<Float>.V3, id:Int32)
                {
                    self.position = position 
                    self.id       = id
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
            
            private 
            let vao:GL.VertexArray
            private 
            var vvo:GL.Vector<Vertex>, 
                evo:GL.Vector<Index>
                
            private 
            var indexSegments:(fixed:Range<Int>, interpolated:Range<Int>)
            
            private 
            var indicator:Int32     = -1, 
                preselection:Int32  = -1, 
                fixed:[Vertex]?     = nil
            
            init()
            {
                self.evo = .generate()
                self.vvo = .generate()
                self.vao = .generate()
                
                self.indexSegments = (0 ..< 0, 0 ..< 0)
                
                self.vvo.buffer.bind(to: .array)
                {
                    self.vao.bind().setVertexLayout(.float(from: .float3), .int(from: .int))
                    self.evo.buffer.bind(to: .elementArray)
                    {
                        self.vao.unbind()
                    }
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
                    let base:Index = Index(vertices.count) 
                    for j:Int in loop.indices
                    {
                        let i:Int = loop.index(before: j == loop.startIndex ? loop.endIndex : j)
                        // get two vertices and angle between
                        let edge:Math<Vertex>.V2 = (loop[i], loop[j])
                        let d:Float     = Math.dot(edge.0.position, edge.1.position), 
                            φ:Float     = .acos(max(-1, min(d, 1))), 
                            scale:Float = 1 / (1 - d * d).squareRoot()
                        // determine subdivisions 
                        let subdivisions:Int = Int(φ / resolution) + 1
                        
                        // push the fixed vertex 
                        indices.fixed.append(Index(vertices.count))
                        vertices.append(edge.0)
                        // push the interpolated vertices 
                        for s:Int in 1 ..< subdivisions
                        {
                            let t:Float = Float(s) / Float(subdivisions)
                            
                            // slerp!
                            let sines:Math<Float>.V2   = (.sin(φ - φ * t), .sin(φ * t)), 
                                factors:Math<Float>.V2 = Math.scale(sines, by: scale)
                            
                            let components:Math<Math<Float>.V3>.V2 
                            components.0 = Math.scale(edge.0.position, by: factors.0) 
                            components.1 = Math.scale(edge.1.position, by: factors.1) 
                            
                            let interpolated:Math<Float>.V3 = Math.add(components.0, components.1)
                            
                            vertices.append(.init(interpolated, id: edge.0.id))
                        }
                    }
                    
                    // compute lines-adjacency indices
                    let totalDivisions:Index = Index(vertices.count) - base
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
            func push(state:State, model:Model.Map, sync:Bool = false) 
            {
                switch state
                {
                    case .none:
                        if sync 
                        {
                            self.fixed = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        }
                        self.indicator = -1
                    
                    case .anchorSelected(let index):
                        if sync 
                        {
                            self.fixed = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        }
                        self.indicator = .init(index) << 1 | 0
                    
                    case .anchorMoving(let index, let position):
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed[index].position = position
                        self.fixed = fixed
                        self.indicator = .init(index) << 1 | 1
                    
                    case .anchorNew(let index, let position):
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed.insert(.init(position, id: -1), at: index)
                        self.fixed = fixed
                        self.indicator = -1
                }
            }
            
            mutating 
            func push(preselection:Int?) 
            {
                self.preselection = .init(preselection ?? -1)
            }
            
            mutating 
            func draw() 
            {
                if let fixed:[Vertex] = self.fixed 
                {
                    let (vertices, indices):([Vertex], Indices) = Borders.subdivide([fixed])
                    self.vvo.assign(data: vertices,        in: .array,        usage: .dynamic)
                    self.evo.assign(data: indices.indices, in: .elementArray, usage: .dynamic)
                    
                    self.indexSegments = indices.segments
                    
                    self.fixed = nil
                }
                
                Programs.borderPolyline.bind 
                {
                    $0.set(float:  "thickness", 2)
                    $0.set(float4: "frontColor", (1, 1, 1, 1))
                    $0.set(float4: "backColor",  (1, 1, 1, 0))
                    self.vao.drawElements(self.indexSegments.interpolated, as: .linesAdjacency, indexType: Index.self)
                }
                
                Programs.borders.bind 
                {
                    $0.set(int: "indicator",    self.indicator)
                    $0.set(int: "preselection", self.preselection)
                    self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                }
                
                Programs.borderLabels.bind 
                {
                    $0.set(int: "indicator",    self.indicator)
                    $0.set(int: "preselection", self.preselection)
                    
                    $0.set(float4: "monoFontMetrics", Programs.monofont.metrics)
                    Programs.monofont.texture.bind(to: .texture2d, index: 0)
                    {
                        self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                    }
                }
            }
        }
        
        var globe:Globe, 
            borders:Borders
        
        init()
        {
            self.globe   = .init()
            self.borders = .init()
        }
        
        mutating 
        func draw(_ model:Model)
        {
            GL.enable(.culling)
            
            GL.disable(.multisampling)
            
            GL.enable(.blending)
            GL.blend(.mix)
            self.globe.draw(model) 
            
            GL.enable(.multisampling)
            GL.blend(.add)
            self.borders.draw()
        }
    }
}
