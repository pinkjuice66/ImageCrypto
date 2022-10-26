//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import Foundation
import CoreVideo

func testData_BGRA(of size: Int) -> Data {
    let array = [UInt8](repeating: 0, count: size)
        .enumerated().map { offset, value -> UInt8 in
            if offset % 4 == 0 {
                return 230
            } else if offset % 4 == 1 {
                return 20
            } else if offset % 4 == 2 {
                return 100
            } else if offset % 4 == 3 {
                return 50
            }
            return 0
        }
    let data = Data(array)
    
    return data
}

func testData_RGB(of size: Int) -> Data {
    let array = [UInt8](repeating: 0, count: size)
        .enumerated().map { offset, value -> UInt8 in
            if offset % 3 == 0 {
                return 230
            } else if offset % 3 == 1 {
                return 20
            } else if offset % 3 == 2 {
                return 100
            }
            return 0
        }
    let data = Data(array)
    
    return data
}

// This is for test data.
extension CVPixelBuffer {
    
    static func createTestBuffer_32BGRA(width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer!
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            nil,
                            &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        let data = Data(repeating: 150, count: bytesPerRow * height)
        
        if width * 4 == bytesPerRow {
            data.withUnsafeBytes { p in
                memcpy(baseAddress, p.baseAddress, p.count)
            }
        } else {
            for row in 0..<height {
                data.withUnsafeBytes { p in
                    memcpy(baseAddress.advanced(by: row * bytesPerRow),
                           p.baseAddress?.advanced(by: row * bytesPerRow),
                           4 * width)
                }
            }
        }

        return pixelBuffer
    }
    
    static func createTestBuffer_24RGB(width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer!
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_24RGB,
                            nil,
                            &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
        
        let data = Data(repeating: 150, count: bytesPerRow * height)
        
        if width * 3 == bytesPerRow {
            data.withUnsafeBytes { p in
                memcpy(baseAddress, p.baseAddress, p.count)
            }
        } else {
            for row in 0..<height {
                data.withUnsafeBytes { p in
                    memcpy(baseAddress.advanced(by: row * bytesPerRow),
                           p.baseAddress?.advanced(by: row * bytesPerRow),
                           3 * width)
                }
            }
        }

        return pixelBuffer
    }
}
