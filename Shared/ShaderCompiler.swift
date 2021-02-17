//
//  ShaderCompiler.swift
//  ShaderMania
//
//  Created by Markus Moenig on 2/9/20.
//

import MetalKit

// https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language
extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

/// A shader parameter instance
class ShaderParameter
{
    enum ParameterType {
        case Float, Float2, Float3, Float4
    }
    
    enum ParameterUIType {
        case Slider, Color
    }

    var id                  = UUID()
    var type                : ParameterType = .Float
    var uiType              : ParameterUIType = .Slider

    var name                = ""
    var index               : Int = 0
    
    // Possible UI params
    
    var min                 = Float(0)
    var max                 = Float(1)

    var step                = Float(0.1)
    
    var defaultValue        = float4(0,0,0,0)
    
    init(_ paramType: String, _ parameters: [String: String])
    {
        if let name = parameters["name"] {
            self.name = name
        }
        
        if paramType == "ParamFloat3" {
            
            type = .Float3
            
            if let uiType = parameters["ui"] {
                if uiType.lowercased() == "color" {
                    self.uiType = .Color
                }
            }
            
            if uiType == .Color {
                if let defaultValue = parameters["default"] {
                    let v = String(defaultValue)
                        
                    func readHexString(_ hex:String) -> float3 {
                        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

                        if (cString.hasPrefix("#")) {
                            cString.remove(at: cString.startIndex)
                        }

                        if ((cString.count) != 6) {
                            return float3()
                        }

                        var rgbValue:UInt64 = 0
                        Scanner(string: cString).scanHexInt64(&rgbValue)

                        return float3( Float((rgbValue & 0xFF0000) >> 16) / 255.0,
                                Float((rgbValue & 0x00FF00) >> 8) / 255.0,
                                Float(rgbValue & 0x0000FF) / 255.0)
                    }
                        
                    let v3 = readHexString(v)
                    
                    self.defaultValue.x = v3.x
                    self.defaultValue.y = v3.y
                    self.defaultValue.z = v3.z
                }
            }
        } else
        if paramType == "ParamFloat" {
            if let uiType = parameters["ui"] {
                if uiType.lowercased() == "slider" {
                    self.uiType = .Slider
                }
            }
            
            if let uiType = parameters["ui"] {
                if uiType.lowercased() == "slider" {
                    self.uiType = .Slider
                }
            }
            if let defaultValue = parameters["default"] {
                if let v = Float(defaultValue) {
                    self.defaultValue.x = v
                }
            }
            if let min = parameters["min"] {
                if let v = Float(min) {
                    self.min = v
                }
            }
            if let max = parameters["max"] {
                if let v = Float(max) {
                    self.max = v
                }
            }
            if let step = parameters["step"] {
                if let v = Float(step) {
                    self.step = v
                }
            }
        }
    }
    
    func createShaderText(_ index: Int) -> String
    {
        self.index = index
        
        var text = ""
        
        if type == .Float {
            text = "data.parameters[\(index)].x"
        } else
        if type == .Float3 {
            text = "data.parameters[\(index)].xyz"
        }
        
        return text
    }
}

/// A shader instance
class Shader                : NSObject
{
    var isValid             : Bool = false
    var pipelineStateDesc   : MTLRenderPipelineDescriptor!
    var pipelineState       : MTLRenderPipelineState!
    
    var inputs              : [String] = []
    var parameters          : [ShaderParameter] = []
    
    var paramDataBuffer     : MTLBuffer? = nil
    
    var compileTime         : Double = 0
    var executionTime       : Double = 0

    deinit {
        pipelineStateDesc = nil
        pipelineState = nil
    }
    
    override init()
    {
        super.init()
    }
}

class ShaderCompiler
{
    let core            : Core
    
    init(_ core: Core)
    {
        self.core = core
    }
    
    func compile(asset: Asset, cb: @escaping (Shader?, [CompileError]) -> ())
    {
        var code = getHeaderCode(noOp: asset.type == .Common)
        
        if asset.type != .Common {
            for asset in core.assetFolder.assets {
                if asset.type == .Common {
                    code += asset.value
                }
            }
        }
        
        var ns = code as NSString
        var lineNumbers  : Int32 = 0
        
        ns.enumerateLines { (str, _) in
            lineNumbers += 1
        }
                
        var parseErrors: [CompileError] = []
        let shader = Shader()

        func createError(_ errorText: String = "Syntax Error", line: Int32) {
            var error = CompileError()
            error.asset = asset
            error.line = line - lineNumbers
            error.column = 0
            error.error = errorText
            error.type = "error"
            parseErrors.append(error)
        }
        
        ns = (code + asset.value) as NSString
        var lineNr : Int32 = 0
                
        var parsedCode = ""

        ns.enumerateLines { (str, _) in
            lineNr += 1
            
            var processed = str
            
            // Substitute ParamInput (the input slots
            
            while processed.contains("ParamInput") {
                if let range = processed.range(of: "ParamInput") {
                    let startIndex : Int = range.lowerBound.utf16Offset(in: processed)
                    var index : Int = range.upperBound.utf16Offset(in: processed) + 1
                    var params = ""
                    while processed[index] != ">" && processed[index] != "\n" {
                        params.append(processed[index])
                        index += 1
                    }
                    if processed[index] == ">" {
                        index += 1
                        let pairs = self.splitParameters(params)
                        if let name = pairs["name"] {
                            let start = String.Index(utf16Offset: startIndex, in: processed)
                            let end = String.Index(utf16Offset: index, in: processed)
                            processed.replaceSubrange(start..<end, with: "data.slot\(shader.inputs.count);")
                            shader.inputs.append(name)
                        }
                    }
                } else { break }
            }
            
            // Substitute UI parameters
            
            let paramTypes = ["ParamFloat3", "ParamFloat"]
            
            for type in paramTypes {
                while processed.contains(type) {
                    if let range = processed.range(of: type) {
                        let startIndex : Int = range.lowerBound.utf16Offset(in: processed)
                        var index : Int = range.upperBound.utf16Offset(in: processed) + 1
                        var params = ""
                        while processed[index] != ">" && processed[index] != "\n" {
                            params.append(processed[index])
                            index += 1
                        }
                        if processed[index] == ">" {
                            index += 1
                            let pairs = self.splitParameters(params)
                                
                            let parameter = ShaderParameter(type, pairs)
                            let paramText = parameter.createShaderText(shader.parameters.count)
                            if asset.shaderDataNames[shader.parameters.count] != parameter.name {
                                asset.shaderData[shader.parameters.count] = parameter.defaultValue
                                asset.shaderDataNames[shader.parameters.count] = parameter.name
                            }
                            shader.parameters.append(parameter)
                            
                            let start = String.Index(utf16Offset: startIndex, in: processed)
                            let end = String.Index(utf16Offset: index, in: processed)
                            processed.replaceSubrange(start..<end, with: "\(paramText);")
                        }
                    } else { break }
                }
            }
            
            parsedCode += processed + "\n"
        }
        
        if parseErrors.count > 0 {            
            cb(nil, parseErrors)
            return
        }
                        
        let startTime =  NSDate().timeIntervalSince1970

        let compiledCB : MTLNewLibraryCompletionHandler = { (library, error) in
            
            var errors: [CompileError] = []
            
            shader.compileTime = (NSDate().timeIntervalSince1970 - startTime) * 1000
            
            if let error = error {
                let str = error.localizedDescription
                let arr = str.components(separatedBy: "program_source:")
                for str in arr {
                    if str.starts(with: "Compilation failed:") == false && (str.contains("error:") || str.contains("warning:")) {
                        let arr = str.split(separator: ":")
                        let errorArr = String(arr[3].trimmingCharacters(in: .whitespaces)).split(separator: "\n")
                        var errorText = ""
                        if errorArr.count > 0 {
                            errorText = String(errorArr[0])
                        }
                        if arr.count >= 4 {
                            var er = CompileError()
                            er.asset = asset
                            er.line = Int32(arr[0])! - lineNumbers - 1
                            er.column = Int32(arr[1])
                            er.type = arr[2].trimmingCharacters(in: .whitespaces)
                            er.error = errorText
                            if er.line != nil && er.column != nil && er.line! >= 0 && er.column! >= 0 {
                                errors.append(er)
                            }
                        }
                    }
                }
            }
            
            if let error = error, library == nil {
                print(error.localizedDescription)
                cb(nil, errors)
            } else
            if let library = library {
                                
                shader.pipelineStateDesc = MTLRenderPipelineDescriptor()
                shader.pipelineStateDesc.vertexFunction = library.makeFunction(name: "__procVertex")
                shader.pipelineStateDesc.fragmentFunction = library.makeFunction(name: "__shaderMain")
                shader.pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
                
                shader.pipelineStateDesc.colorAttachments[0].isBlendingEnabled = true
                shader.pipelineStateDesc.colorAttachments[0].rgbBlendOperation = .add
                shader.pipelineStateDesc.colorAttachments[0].alphaBlendOperation = .add
                shader.pipelineStateDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                
                do {
                    shader.pipelineState = try self.core.device.makeRenderPipelineState(descriptor: shader.pipelineStateDesc)
                    shader.isValid = true
                } catch {
                    shader.isValid = false
                }

                if shader.isValid == true {
                    cb(shader, errors)
                }
            }
        }
        
        core.device.makeLibrary(source: parsedCode, options: nil, completionHandler: compiledCB)
    }
    
    /// Splits the parameters into key and value pairs
    func splitParameters(_ parameters: String) -> [String: String]
    {
        var rc : [String: String] = [:]
        
        let cArray = parameters.split(separator: ",")
        for param in cArray {
            let dArray = param.split(separator: ":")
            if dArray.count == 2 {
                let key = dArray[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = dArray[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                rc[key] = value
            }
        }
        return rc
    }
    
    func getHeaderCode(noOp: Bool = false) -> String
    {
        return """
        
        #include <metal_stdlib>
        #include <simd/simd.h>
        using namespace metal;

        typedef struct
        {
            float4 clipSpacePosition [[position]];
            float2 textureCoordinate;
            float2 viewportSize;
        } RasterizerData;

        typedef struct
        {
            float           time;
            unsigned int    frame;
        } __MetalData;

        typedef struct
        {
            float2          uv;
            float2          size;
            float           time;
            unsigned int    frame;

            float4          outColor;

            texture2d<float> slot0;
            texture2d<float> slot1;
            texture2d<float> slot2;
            texture2d<float> slot3;

            constant float4 *parameters;
        } Data;

        typedef struct
        {
            vector_float2 position;
            vector_float2 textureCoordinate;
        } VertexData;


        float4 getLinearSample(texture2d<float> texture, float2 uv)
        {
            constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
            return texture.sample(textureSampler, float2(uv.x, 1.0 - uv.y));
        }

        float4 getNearestSample(texture2d<float> texture, float2 uv)
        {
            constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
            return texture.sample(textureSampler, float2(uv.x, 1.0 - uv.y));
        }

        // Quad Vertex Function
        vertex RasterizerData
        __procVertex(uint vertexID [[ vertex_id ]],
                     constant VertexData *vertexArray [[ buffer(0) ]],
                     constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])

        {
            RasterizerData out;
            
            float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
            float2 viewportSize = float2(*viewportSizePointer);
            
            out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
            out.clipSpacePosition.z = 0.0;
            out.clipSpacePosition.w = 1.0;
            
            out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
            out.viewportSize = viewportSize;

            return out;
        }
        
        void mainImage(thread Data &data);

        fragment float4 __shaderMain( RasterizerData in [[stage_in]],
                                      constant __MetalData &metalData [[buffer(0)]],
                                      texture2d<float> slot0 [[ texture(1) ]],
                                      texture2d<float> slot1 [[ texture(2) ]],
                                      texture2d<float> slot2 [[ texture(3) ]],
                                      texture2d<float> slot3 [[ texture(4) ]],
                                      constant float4 *parameters [[ buffer(5) ]])
        {
            float2 uv = in.textureCoordinate;
            float2 size = in.viewportSize;

            Data data;
            data.uv = uv;
            data.size = size;
            data.time = metalData.time;
            data.frame = metalData.frame;
            data.outColor = float4(0,0,0,1);

            data.slot0 = slot0;
            data.slot1 = slot1;
            data.slot2 = slot2;
            data.slot3 = slot3;

            data.parameters = parameters;

            \(noOp ? "//" : "")mainImage(data);
            return data.outColor;
        }
        
        """
    }
}

