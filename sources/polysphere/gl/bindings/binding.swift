/*
    Copyright 2017, Kelvin Ma (“taylorswift”), kelvin13ma@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
public typealias GLboolean          = Bool
public typealias GLdouble           = Double
public typealias GLclampd           = Double
public typealias GLfloat            = Float
public typealias GLclampf           = Float
public typealias GLbyte             = Int8
public typealias GLchar             = Int8
public typealias GLcharARB          = Int8
public typealias GLshort            = Int16
public typealias GLint              = Int32
public typealias GLsizei            = Int32
public typealias GLenum             = Int32
public typealias GLfixed            = Int32
public typealias GLclampx           = Int32
public typealias GLint64            = Int64
public typealias GLint64EXT         = Int64
public typealias GLintptr           = Int
public typealias GLintptrARB        = Int
public typealias GLsizeiptr         = Int
public typealias GLsizeiptrARB      = Int
public typealias GLvdpauSurfaceNV   = Int
public typealias GLubyte            = UInt8
public typealias GLushort           = UInt16
public typealias GLhalfNV           = UInt16
public typealias GLuint             = UInt32
public typealias GLbitfield         = UInt32
public typealias GLuint64           = UInt64
public typealias GLuint64EXT        = UInt64
public typealias GLhandleARB        = UnsafeMutableRawPointer?
public typealias GLeglImageOES      = UnsafeMutableRawPointer?
public typealias GLsync             = OpaquePointer?

public typealias GLDebugProc = @convention(c)
    (Int32, Int32, UInt32, Int32, Int32, UnsafePointer<Int8>?, UnsafeRawPointer?) -> Void
public typealias GLDebugProcARB = GLDebugProc
public typealias GLDebugProcKHR = GLDebugProc

public typealias GLDebugProcAMD = @convention(c)
    (Int32, Int32, Int32, Int32, UnsafePointer<Int8>?, UnsafeMutableRawPointer?) -> Void
*/

#if os(Linux)
    import Glibc
#elseif os(OSX)
    import Darwin
#endif

enum OpenGL 
{
    static 
    func getfp(_ name:String, support:[String]) -> UnsafeMutableRawPointer
    {
        guard let fp:UnsafeMutableRawPointer = lookupAddress(of: name)
        else
        {
            fatalError("failed to load function \(name)\n\(support.joined(separator: "\n"))")
        }
        return fp
    }
    
#if os(Linux)
    static 
    var glxGetProcAddress:(@convention(c) (UnsafePointer<Int8>) -> UnsafeMutableRawPointer?)? = nil

    static 
    func lookupAddress(of name:String) -> UnsafeMutableRawPointer?
    {
        if let glxGetProcAddress = glxGetProcAddress
        {
            return glxGetProcAddress(name)
        }

        guard let dlopenhandle:UnsafeMutableRawPointer = dlopen(nil, RTLD_LAZY | RTLD_LOCAL)
        else
        {
            fatalError("failed to obtain dynamic library handle")
        }
        if let fp:UnsafeMutableRawPointer = dlsym(dlopenhandle, "glXGetProcAddressARB")
        {
            glxGetProcAddress = unsafeBitCast(fp, to: type(of: glxGetProcAddress))
        }

        if let glxGetProcAddress = glxGetProcAddress
        {
            return glxGetProcAddress(name)
        }

        if let fp:UnsafeMutableRawPointer = dlsym(dlopenhandle, "glXGetProcAddress")
        {
            glxGetProcAddress = unsafeBitCast(fp, to: type(of: glxGetProcAddress))
        }

        if let glxGetProcAddress = glxGetProcAddress
        {
            return glxGetProcAddress(name)
        }

        fatalError("failed to find glXGetProcAddress")
    }

#elseif os(OSX)
    static 
    var dlopenhandle:UnsafeMutableRawPointer? = nil
    
    static 
    func lookupAddress(of name:String) -> UnsafeMutableRawPointer?
    {
        if let dlopenhandle:UnsafeMutableRawPointer = dlopenhandle
        {
            return dlsym(dlopenhandle, name)
        }
        
        dlopenhandle = dlopen("/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL", RTLD_LAZY)
        
        if let dlopenhandle:UnsafeMutableRawPointer = dlopenhandle
        {
            return dlsym(dlopenhandle, name)
        }
        
        fatalError("failed to load opengl framework")
    }
    
#else
    func lookupAddress(of _:String) -> UnsafeMutableRawPointer?
    {
        fatalError("unsupported OS")
    }
    
#endif
}
