//
//  CVPixelBufferExtensionTest.swift
//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import XCTest
@testable import ImageCrypto

class CVPixelBufferExtensionTest: XCTestCase {
    
    var originalImageData: Data!

    override func setUp() {
        super.setUp()
        let url = Bundle.module.url(forResource: "original_280x420", withExtension: "jpg")!
        originalImageData = try! Data(contentsOf: url)
    }
    
    override func tearDown() {
        originalImageData = nil
        super.tearDown()
    }

    func testPurePixelData_Padding_32BGRA() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_32BGRA(width: 200, height: 200)
        let purePixelData = pixelBuffer.purePixelData
        let expectedData = Data(repeating: 150, count: 200*4*200)
        
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(purePixelData, expectedData)
    }
    
    func testPurePixelData_Padding_24RGB() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_24RGB(width: 200, height: 200)
        let purePixelData = pixelBuffer.purePixelData
        let expectedData = Data(repeating: 150, count: 200*3*200)
        
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(purePixelData, expectedData)
    }
    
    func testPurePixelData_noPadding_32BGRA() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_32BGRA(width: 320, height: 200)
        let purePixelData = pixelBuffer.purePixelData
        let expectedData = Data(repeating: 150, count: 320*4*200)
        
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(purePixelData, expectedData)
    }
    
    func testPurePixelData_noPadding_24RGB() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_24RGB(width: 320, height: 200)
        let purePixelData = pixelBuffer.purePixelData
        let expectedData = Data(repeating: 150, count: 320*3*200)
        
        XCTAssertNotNil(expectedData)
        XCTAssertEqual(purePixelData, expectedData)
    }

    func testCreateWithExtension() {
        let ciImage = CIImage(data: originalImageData)!
        let pixelBuffer = CVPixelBuffer.createWithExtension32BGRA(from: ciImage, heightExtended: 1)!
        
        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        XCTAssertEqual(Int(ciImage.extent.width), bufferWidth)
        XCTAssertEqual(Int(ciImage.extent.height)+1, bufferHeight)
    }
    
    func testCopy_dataSizeIsLessOrEqualThanPixelBuffer_noPadding_32BGRA() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_32BGRA(width: 320, height: 640)
        let data = Data(repeating: 28, count: 4*320*640)
        pixelBuffer.copy(from: data)
        
        let copiedData = pixelBuffer.purePixelData!
        
        XCTAssertEqual(data, copiedData)
    }
    
    func testCopy_dataSizeIsLessOrEqualThanPixelBuffer_noPadding_24RGB() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_24RGB(width: 320, height: 640)
        let data = Data(repeating: 28, count: 3*320*640)
        pixelBuffer.copy(from: data)

        let copiedData = pixelBuffer.purePixelData!

        XCTAssertEqual(data, copiedData)
    }

    func testCopy_dataSizeIsLessOrEqualThanPixelBuffer_padding_32BGRA() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_32BGRA(width: 310, height: 640)
        let data = Data(repeating: 28, count: 4*310*640)
        pixelBuffer.copy(from: data)
        
        let copiedData = pixelBuffer.purePixelData!
        
        XCTAssertEqual(data, copiedData)
    }
    
    func testCopy_dataSizeIsLessOrEqualThanPixelBuffer_padding_24RGB() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_24RGB(width: 310, height: 640)
        let data = Data(repeating: 28, count: 3*310*640)
        pixelBuffer.copy(from: data)

        let copiedData = pixelBuffer.purePixelData!

        XCTAssertEqual(data, copiedData)
    }
    
    func testCopy_nonceAndTagIncluded() {
        let pixelBuffer = CVPixelBuffer.createTestBuffer_24RGB(width: 310, height: 641)
        let data = Data(repeating: 28, count: 3*310*640)
        let nonce = Data(repeating: 20, count: 12)
        let tag = Data(repeating: 30, count: 16)
        
        let totalData = data + nonce + tag
        
        pixelBuffer.copy(from: totalData)
        
        var pixelData = pixelBuffer.purePixelData!
        pixelData.removeLast(pixelData.count - totalData.count)
        
        XCTAssertEqual(pixelData, totalData)
    }
    
    func testBGRAToRGB() {
        let bgra = CVPixelBuffer.createTestBuffer_24RGB(width: 310, height: 640)
        let rgb = bgra.bgraToRGB()!
        
        let expectedData = Data(repeating: 150, count: 3 * 310 * 640)
        
        XCTAssertEqual(expectedData, rgb.purePixelData!)
    }
}
