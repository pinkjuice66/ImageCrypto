//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import Foundation
import Accelerate
import CoreImage

internal extension CVPixelBuffer {
    
    var bytesPerRow: Int {
        CVPixelBufferGetBytesPerRow(self)
    }
    
    var width: Int {
        CVPixelBufferGetWidth(self)
    }
    
    var height: Int {
        CVPixelBufferGetHeight(self)
    }
    
    func lock(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferLockBaseAddress(self, flags)
    }
    
    func unlock(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferUnlockBaseAddress(self, flags)
    }
    
    var baseAddress: UnsafeMutableRawPointer? {
        CVPixelBufferGetBaseAddress(self)
    }
    
    var bytesPerPixel: Int {
        bytesPerRow / width
    }
}

internal extension CVPixelBuffer {
    
    /// Return only pixels data excluding padding of the row.
    /// It works only for a non planer image.
    var purePixelData: Data? {
        lock(.readOnly)
        defer {
            unlock(.readOnly)
        }
        guard let baseAddress = baseAddress else {
            return nil
        }
                
        // no padding exists
        if bytesPerRow == width * bytesPerPixel {
            return Data(bytesNoCopy: baseAddress,
                        count: bytesPerRow * height,
                        deallocator: .none)
        }
        
        var data = Data(capacity: width * bytesPerPixel * height)
        for row in 0..<height {
            let rowData = Data(bytesNoCopy: baseAddress.advanced(by: row * bytesPerRow),
                               count: width * bytesPerPixel,
                               deallocator: .none)
            data.append(rowData)
        }
        
        return data
    }
    
    /// Returns padding width for a given width.
    static func getPaddingWidth24RGB(for width: Int) -> Int {
        var pixelBuffer: CVPixelBuffer!
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            1,
                            kCVPixelFormatType_24RGB,
                            nil,
                            &pixelBuffer)
        pixelBuffer.lock(.readOnly)
        defer { pixelBuffer.unlock(.readOnly) }
        
        return pixelBuffer.bytesPerRow - 3 * pixelBuffer.width
    }
    
    /// Create CVPixelBuffer with CIImage.
    static func create32BGRA(from ciImage: CIImage, ciContext: CIContext = CIContext()) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(ciImage.extent.width),
                            Int(ciImage.extent.height),
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
        
        if let pixelBuffer = pixelBuffer {
            ciContext.render(ciImage, to: pixelBuffer)
        }
        
        return pixelBuffer
    }
    
    static func createWithExtension32BGRA(from ciImage: CIImage,
                                    ciContext: CIContext = CIContext(),
                                    heightExtended: Int,
                                    widthExtended: Int = 0) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(ciImage.extent.width) + widthExtended,
                            Int(ciImage.extent.height) + heightExtended,
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
        
        if let pixelBuffer = pixelBuffer {
            ciContext.render(ciImage, to: pixelBuffer)
        }
        
        return pixelBuffer
    }
    
    /// Copies data from given Data. If the size of given data is greater than
    /// a pixelBuffer, the image data will be cropped.
    /// It works only for a non planer image format.
    func copy(from data: Data) {
        lock(.init(rawValue: 0))
        defer { unlock(.init(rawValue: 0)) }
        
        guard let baseAddress = baseAddress else {
            return
        }
        
        // no padding exists
        if bytesPerRow == width * bytesPerPixel {
            let numberOfBytesToCopy = min(data.count, height * bytesPerRow)
            
            data.withUnsafeBytes { pointer in
                memcpy(baseAddress,
                       pointer.baseAddress,
                       numberOfBytesToCopy)
            }
            return
        }
        
        // padding exists
        var dataHeight = data.count/(width*bytesPerPixel)
        // when the data is not making a complete square
        let remainder = data.count % (width*bytesPerPixel)
        if remainder != 0 {
            // there's several extra data on the last row which is not enough
            // to compose one row. we need to consider this case.
            dataHeight = dataHeight + 1
        }
        
        // size(data) > size(pixelBuffer)
        if data.count > width * bytesPerPixel * height {
            for row in 0..<height {
                data.withUnsafeBytes { pointer in
                    memcpy(baseAddress.advanced(by: bytesPerRow * row),
                           pointer.baseAddress?.advanced(by: bytesPerPixel * width * row),
                           width * bytesPerPixel)
                }
            }
        } else { // size(data) <= size(pixelBuffer)
            for row in 0..<dataHeight {
                data.advanced(by: width * bytesPerPixel * row)
                    .withUnsafeBytes { pointer in
                        var numberOfBytesToCopy = width * bytesPerPixel
                        if pointer.count < width * bytesPerPixel {
                            numberOfBytesToCopy = remainder
                        }
                        memcpy(baseAddress.advanced(by: bytesPerRow * row),
                               pointer.baseAddress,
                               numberOfBytesToCopy)
                }
            }
        }
    }
    
    /// Creates a new CVPixelBuffer with format type 24RGB.
    func bgraToRGB() -> CVPixelBuffer? {
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue | CGImageByteOrderInfo.order32Little.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent)
        
        var sourceBuffer = vImage_Buffer()
        let inputCVImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(self).takeRetainedValue()
        vImageCVImageFormat_SetColorSpace(inputCVImageFormat,
                                          CGColorSpaceCreateDeviceRGB())

        var error = vImageBuffer_InitWithCVPixelBuffer(&sourceBuffer,
                                                   &format,
                                                   self,
                                                   inputCVImageFormat,
                                                   nil,
                                                   vImage_Flags(kvImageNoFlags))
    
        guard error == kvImageNoError else {
            return nil
        }
        
        defer {
            free(sourceBuffer.data)
        }

        var destinationBuffer = vImage_Buffer()

        error = vImageBuffer_Init(&destinationBuffer,
                                  sourceBuffer.height,
                                  sourceBuffer.width,
                                  24,
                                  vImage_Flags(kvImageNoFlags))

        guard error == kvImageNoError else {
            return nil
        }
        
        defer {
            free(destinationBuffer.data)
        }
        
        vImageConvert_BGRA8888toRGB888(&sourceBuffer,
                                       &destinationBuffer,
                                       vImage_Flags(kvImageNoFlags))
        
        var outputPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            CVPixelBufferGetWidth(self),
                            CVPixelBufferGetHeight(self),
                            kCVPixelFormatType_24RGB,
                            nil,
                            &outputPixelBuffer)
        guard let outputPixelBuffer = outputPixelBuffer else {
            return nil
        }
        
        var outputFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent)
        let outputCVImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(outputPixelBuffer).takeRetainedValue()
        vImageCVImageFormat_SetColorSpace(outputCVImageFormat,
                                          CGColorSpaceCreateDeviceRGB())
        
        error = vImageBuffer_CopyToCVPixelBuffer(&destinationBuffer,
                                                 &outputFormat,
                                                 outputPixelBuffer,
                                                 outputCVImageFormat,
                                                 nil,
                                                 vImage_Flags(kvImageNoFlags))

        guard error == kvImageNoError else {
            return nil
        }
        
        return outputPixelBuffer
    }
}
