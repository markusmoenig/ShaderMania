//
//  Utils.swift
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import AVFoundation
import Photos

/// MMRect class
class MMRect
{
    var x : Float
    var y: Float
    var width: Float
    var height: Float
    
    init( _ x : Float, _ y : Float, _ width: Float, _ height : Float, scale: Float = 1 )
    {
        self.x = x * scale; self.y = y * scale; self.width = width * scale; self.height = height * scale
    }
    
    init()
    {
        x = 0; y = 0; width = 0; height = 0
    }
    
    init(_ rect : MMRect)
    {
        x = rect.x; y = rect.y
        width = rect.width; height = rect.height
    }
    
    func set( _ x : Float, _ y : Float, _ width: Float, _ height : Float, scale: Float = 1 )
    {
        self.x = x * scale; self.y = y * scale; self.width = width * scale; self.height = height * scale
    }
    
    /// Copy the content of the given rect
    func copy(_ rect : MMRect)
    {
        x = rect.x; y = rect.y
        width = rect.width; height = rect.height
    }
    
    /// Returns true if the given point is inside the rect
    func contains( _ x : Float, _ y : Float ) -> Bool
    {
        if self.x <= x && self.y <= y && self.x + self.width >= x && self.y + self.height >= y {
            return true;
        }
        return false;
    }
    
    /// Returns true if the given point is inside the scaled rect
    func contains( _ x : Float, _ y : Float, _ scale : Float ) -> Bool
    {
        if self.x <= x && self.y <= y && self.x + self.width * scale >= x && self.y + self.height * scale >= y {
            return true;
        }
        return false;
    }
    
    /// Intersect the rects
    func intersect(_ rect: MMRect)
    {
        let left = max(x, rect.x)
        let top = max(y, rect.y)
        let right = min(x + width, rect.x + rect.width )
        let bottom = min(y + height, rect.y + rect.height )
        let width = right - left
        let height = bottom - top
        
        if width > 0 && height > 0 {
            x = left
            y = top
            self.width = width
            self.height = height
        } else {
            copy(rect)
        }
    }
    
    /// Merge the rects
    func merge(_ rect: MMRect)
    {
        width = width > rect.width ? width : rect.width + (rect.x - x)
        height = height > rect.height ? height : rect.height + (rect.y - y)
        x = min(x, rect.x)
        y = min(y, rect.y)
    }
    
    /// Returns the cordinate of the right edge of the rectangle
    func right() -> Float
    {
        return x + width
    }
    
    /// Returns the cordinate of the bottom of the rectangle
    func bottom() -> Float
    {
        return y + height
    }
    
    /// Shrinks the rectangle by the given x and y amounts
    func shrink(_ x : Float,_ y : Float)
    {
        self.x += x
        self.y += y
        self.width -= x * 2
        self.height -= y * 2
    }
    
    /// Clears the rect
    func clear()
    {
        set(0, 0, 0, 0)
    }
}

func makeCGIImage(texture: MTLTexture, forImage: Bool) -> CGImage?
{
    let width = texture.width
    let height = texture.height
    let pixelByteCount = 4 * MemoryLayout<UInt8>.size
    let imageBytesPerRow = width * pixelByteCount
    let imageByteCount = imageBytesPerRow * height
    
    let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: imageByteCount, alignment: pixelByteCount)
    defer {
        imageBytes.deallocate()
    }

    texture.getBytes(imageBytes,
                     bytesPerRow: imageBytesPerRow,
                     from: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else { return nil }
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let bitmapContext = CGContext(data: nil,
                                        width: width,
                                        height: height,
                                        bitsPerComponent: 8,
                                        bytesPerRow: imageBytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo) else { return nil }
    bitmapContext.data?.copyMemory(from: imageBytes, byteCount: imageByteCount)
    let image = bitmapContext.makeImage()
    return image

}

struct RenderSettings {
    var size : CGSize = .zero
    var fps: Int32 = 6   // frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"

    var outputURL : URL!
}

class ImageAnimator {

// Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
static let kTimescale: Int32 = 600

let settings: RenderSettings
let videoWriter: VideoWriter
var images: [CGImage]!

var frameNum = 0

class func saveToLibrary(videoURL: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else { return }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            if !success {
                //print("Could not save video to photo library:", error)
            }
        }
    }
}

class func removeFileAtURL(fileURL: URL) {
    do {
        try FileManager.default.removeItem(atPath: fileURL.path)
    }
    catch _ as NSError {
        // Assume file doesn't exist.
    }
}

init(renderSettings: RenderSettings) {
    settings = renderSettings
    videoWriter = VideoWriter(renderSettings: settings)
//        images = loadImages()
}

func render(appendPixelBuffers: ((VideoWriter)->Bool)?, completion: (()->Void)?) {

    // The VideoWriter will fail if a file exists at the URL, so clear it out first.
    ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)

    videoWriter.start()
    videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
        ImageAnimator.saveToLibrary(videoURL: self.settings.outputURL)
        completion?()
    }
}
}

class VideoWriter {

let renderSettings: RenderSettings

var videoWriter: AVAssetWriter!
var videoWriterInput: AVAssetWriterInput!
var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

var isReadyForData: Bool {
    return videoWriterInput?.isReadyForMoreMediaData ?? false
}

init(renderSettings: RenderSettings) {
    self.renderSettings = renderSettings
}

func start() {

    let avOutputSettings: [String: Any] = [
        AVVideoCodecKey: renderSettings.avCodecKey,
        AVVideoWidthKey: NSNumber(value: Float(renderSettings.size.width)),
        AVVideoHeightKey: NSNumber(value: Float(renderSettings.size.height))
    ]

    func createPixelBufferAdaptor() {
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.size.height))
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                  sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
    }

    func createAssetWriter(outputURL: URL) -> AVAssetWriter {
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter() failed")
        }

        guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
            fatalError("canApplyOutputSettings() failed")
        }

        return assetWriter
    }

    videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
    videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)

    if videoWriter.canAdd(videoWriterInput) {
        videoWriter.add(videoWriterInput)
    }
    else {
        fatalError("canAddInput() returned false")
    }

    // The pixel buffer adaptor must be created before we start writing.
    createPixelBufferAdaptor()

    if videoWriter.startWriting() == false {
        fatalError("startWriting() failed")
    }

    videoWriter.startSession(atSourceTime: CMTime.zero)

    precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
}

func render(appendPixelBuffers: ((VideoWriter)->Bool)?, completion: (()->Void)?) {

    precondition(videoWriter != nil, "Call start() to initialze the writer")

    let queue = DispatchQueue(label: "mediaInputQueue")
    videoWriterInput.requestMediaDataWhenReady(on: queue) {
        let isFinished = appendPixelBuffers?(self) ?? false
        if isFinished {
            self.videoWriterInput.markAsFinished()
            self.videoWriter.finishWriting() {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
        else {
            // Fall through. The closure will be called again when the writer is ready.
        }
    }
}

func addImage(image: CGImage, withPresentationTime presentationTime: CMTime) -> Bool {

    precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")

    //let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
    
    //let pixelBuffer = pixelBufferFromCGImage(image: image)

    #if os(OSX)
    let pixelBuffer = pixelBufferFromCGImage(image: image)
    #else
    let image = UIImage(cgImage: image)
    let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
    #endif
    
    return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
}

func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
    var pxbuffer: CVPixelBuffer? = nil
    let options: NSDictionary = [:]

    let width =  image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow

    let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, image.dataProvider!.data)
    let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)

    CVPixelBufferCreateWithBytes(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        x!,
        bytesPerRow,
        nil,
        nil,
        options,
        &pxbuffer
    )
    return pxbuffer!;
}

#if os(iOS)
class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {
    var pixelBufferOut: CVPixelBuffer?

    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
    if status != kCVReturnSuccess {
      fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
    }

    let pixelBuffer = pixelBufferOut!

    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    let data = CVPixelBufferGetBaseAddress(pixelBuffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                          bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

    context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))

    let horizontalRatio = size.width / image.size.width
    let verticalRatio = size.height / image.size.height
    //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
    let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit

    let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

    let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
    let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0

    context?.draw(image.cgImage!, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}
#endif
}
