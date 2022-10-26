//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import XCTest
@testable import ImageCrypto

class ImageEncryptorTest: XCTestCase {

    var sut: ImageEncryptor!
    
    var originalImageData: Data!
    var originalImageData_performance: Data!
    
    let validKey = "test"
    let emptyKey = ""
    let timeout: TimeInterval = 3
    let invalidInputData = Data(repeating: 100, count: 300*4*1000)
    
    override func setUp() {
        super.setUp()
        sut = ImageEncryptor()
        
        let url = Bundle.module.url(forResource: "original_280x420", withExtension: "jpg")!
        originalImageData = try! Data(contentsOf: url)
        let url2 = Bundle.module.url(forResource: "original_2400x3589", withExtension: "jpg")!
        originalImageData_performance = try! Data(contentsOf: url2)
    }
    
    override func tearDown() {
        sut = nil
        originalImageData = nil
        super.tearDown()
    }
    
    func testOperatingThread_isNotMainThread() {
        let expectation = expectation(description: "image encryption_thread")
        
        sut.encrypt(originalImageData, using: validKey) { result in
            XCTAssertFalse(Thread.isMainThread)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }

    func testEncryptData_validArguments() {
        let expectation = expectation(description: "image encryption_validArguments_imageData")
        
        sut.encrypt(originalImageData, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptUIImage_validArguments() {
        let expectation = expectation(description: "image encryption_validArguments_uiImage")
        let uiImage = UIImage(systemName: "arrow.left")!
        
        sut.encrypt(uiImage, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptCIImage_validArguments() {
        let expectation = expectation(description: "image encryption_validArguments_ciImage")
        let uiImage = UIImage(systemName: "arrow.left")!
        let ciImage = CIImage(cgImage: uiImage.cgImage!)
        sut.encrypt(ciImage, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptSequentially() {
        let expectation = expectation(description: "image encryption_sequentially")
        expectation.expectedFulfillmentCount = 2
        
        sut.encrypt(originalImageData, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        let uiImage = UIImage(systemName: "arrow.left")!
        let ciImage = CIImage(cgImage: uiImage.cgImage!)
        sut.encrypt(ciImage, using: validKey) { result in
            let image = try? result.get()
            XCTAssertNotNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptData_invalidKey() {
        let expectation = expectation(description: "image encryption_invalidKey")
        
        sut.encrypt(originalImageData, using: emptyKey) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as! ImageCryptor.CryptionError, ImageCryptor.CryptionError.invalidKey)
            }
            let image = try? result.get()
            XCTAssertNil(image)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptData_invalidInputData() {
        let expectation = expectation(description: "image encryption_invalidData")
        
        sut.encrypt(invalidInputData, using: validKey) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as! ImageCryptor.CryptionError, ImageEncryptor.CryptionError.invalidInputData)
            }
            let image = try? result.get()
            XCTAssertNil(image)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
    
    func testEncryptData_performance() {
        let expectation = expectation(description: "image encryption_thread")
        
        sut.encrypt(originalImageData_performance, using: validKey) { result in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
}
