// BinaryFloatingPoint, because we use float literals with math
struct Quaternion<F>:Equatable where F:FloatingPoint & ExpressibleByFloatLiteral & Mathematical & SIMDScalar
{
    private 
    var q:Vector4<F> 
    
    var a:F 
    {
        return self.q.w
    } 
    var b:Vector3<F> 
    {
        return self.q.xyz
    }
    
    static 
    var identity:Quaternion<F> 
    {
        return .init(1, .zero)
    }
    
    init(from s:Vector3<F>, to t:Vector3<F>) 
    {
        let a:F = (2 * (1 + s <> t)).squareRoot()
        self.init(0.5 * a, s >< t / a)
    }
    
    init(axis:Vector3<F>, angle:F)
    {
        self.init(F.Math.cos(0.5 * angle), F.Math.sin(0.5 * angle) * axis)
    }
    
    init(_ a:F, _ b:Vector3<F>)
    {
        self.init(.extend(b, a))
    }
    
    private 
    init(_ q:Vector4<F>) 
    {
        self.q = q
    }

    var matrix:Matrix3<F>
    {
        let r:Vector3<F>    = .init(self.b.y, self.b.z, self.b.x)
        let o:Vector3<F>    = self.b * r, 
            i:Vector3<F>    = self.b * self.b, 
            a:Vector3<F>    = self.b * self.a
        
        let v0:Vector3<F>   = .init(1 - 2 * (i.y + i.z) as F,     2 * (o.x + a.z) as F,     2 * (o.z - a.y) as F),
            v1:Vector3<F>   = .init(    2 * (o.x - a.z) as F, 1 - 2 * (i.x + i.z) as F,     2 * (o.y + a.x) as F),
            v2:Vector3<F>   = .init(    2 * (o.z + a.y) as F,     2 * (o.y - a.x) as F, 1 - 2 * (i.x + i.y) as F)
        return .init(v0, v1, v2)
    }
    
    mutating 
    func normalize() 
    {
        self.q.normalize()
    }
    func normalized() -> Quaternion<F>
    {
        return .init(self.q.normalized())
    }
    
    var inverse:Quaternion<F>
    {
        return .init(self.a, -self.b)
    }
    
    func rotate(_ point:Vector3<F>) -> Vector3<F> 
    {
        let r:Vector3<F> = 2 * ((self.b <> point) * self.b + self.a * (self.b >< point)), 
            s:Vector3<F> = point * (self.q <> self.inverse.q)
        return r + s
    }

    static
    func >< (q1:Quaternion<F>, q2:Quaternion<F>) -> Quaternion<F>
    {
        let a:F          = q1.a * q2.a               - q1.b <> q2.b, 
            b:Vector3<F> = q1.a * q2.b + q2.a * q1.b + q1.b >< q2.b
        return Quaternion.init(a, b).normalized()
    }
}
