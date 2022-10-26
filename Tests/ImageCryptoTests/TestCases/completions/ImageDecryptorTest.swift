//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import XCTest
@testable import ImageCrypto

class ImageDecryptorTest: XCTestCase {
    
    var sut: ImageDecryptor!
    
    var encryptedImageData: Data!
    
    var originalImageBufferData_24RGB: Data!
    
    let validKey = "test"
    let emptyKey = ""
    let invalidKey = "zz"
    let invalidInputData = Data(repeating: 20, count: 4*300*600)
    let timeout: TimeInterval = 3
    
    override func setUp() {
        super.setUp()
        sut = ImageDecryptor()
        
        let url = Bundle.module.url(forResource: "encrypted_320x421", withExtension: "png")!
        encryptedImageData = try! Data(contentsOf: url)
        
        let originalDataURL = Bundle.module.url(forResource: "original_280x420", withExtension: "jpg")!
        let ciImage = CIImage(contentsOf: originalDataURL)!
        let pixelBuffer = CVPixelBuffer.create32BGRA(from: ciImage)!
        let rgb = pixelBuffer.bgraToRGB()!
        originalImageBufferData_24RGB = rgb.purePixelData!
    }
    
    override func tearDown() {
        sut = nil
        encryptedImageData = nil
        originalImageBufferData_24RGB = nil
        super.tearDown()
    }
    
    func testDecryptData_validArguments() {
        let expectation = expectation(description: "image decryption_validArguments_imageData")
        
        sut.decrypt(encryptedImageData, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDecryptUIImage_validArguments() {
        let expectation = expectation(description: "image decryption_validArguments_uiImage")
        let uiImage = UIImage(data: encryptedImageData)!

        sut.decrypt(uiImage, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
    }

    func testDecryptCIImage_validArguments() {
        let expectation = expectation(description: "image decryption_validArguments_ciImage")
        let ciImage = CIImage(data: encryptedImageData)!
        sut.decrypt(ciImage, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
    }
    
    func testOperatingThread_isNotMainThread() {
        let expectation = expectation(description: "thread")
        
        sut.decrypt(encryptedImageData, using: validKey) { result in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDecrypt_EmptyKey() {
        let expectation = expectation(description: "emptyKey")
        
        sut.decrypt(encryptedImageData,
                    using: emptyKey) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as! ImageCryptor.CryptionError,
                               ImageCryptor.CryptionError.invalidKey)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDecrypt_invalidInput() {
        let expectation = expectation(description: "invalidInput")
        
        sut.decrypt(invalidInputData,
                    using: validKey) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as! ImageCryptor.CryptionError,
                               ImageCryptor.CryptionError.invalidInputData)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testDecrypt_invalidKey() {
        let expectation = expectation(description: "invalidKey")
        
        sut.decrypt(encryptedImageData,
                    using: invalidKey) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as! ImageCryptor.CryptionError,
                               ImageCryptor.CryptionError.invalidKey)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
}
