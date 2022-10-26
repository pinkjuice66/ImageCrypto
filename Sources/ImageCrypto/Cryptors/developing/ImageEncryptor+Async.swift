//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import UIKit
import CryptoKit

private extension ImageEncryptor {

    static func _encrypt(_ ciImage: CIImage, using keyString: String) throws -> CryptedImage {
        if ciImage.extent.width < 10 || ciImage.extent.height < 1 {
            throw CryptionError.invalidInputData
        }
        
        let paddingWidth = CVPixelBuffer.getPaddingWidth24RGB(for: Int(ciImage.extent.width)) / 3
        guard let bgraPixelBuffer = CVPixelBuffer.createWithExtension32BGRA(from: ciImage,
                                                                            heightExtended: 1
                                                                            , widthExtended: paddingWidth),
              let rgbPixelBuffer = bgraPixelBuffer.bgraToRGB() else {
            throw CryptionError.systemError
        }
        
        guard var rgbPixelData = rgbPixelBuffer.purePixelData else {
            throw CryptionError.systemError
        }
        
        // remove the last row of the image because last row is reserved for the tag and the nonce
        rgbPixelData.removeLast(CVPixelBufferGetWidth(rgbPixelBuffer) * 3)
        
        do {
            let key = SymmetricKey(from: keyString)
            let sealedBox = try AES.GCM.seal(rgbPixelData, using: key)
            
            let paddingWidthData = Data([UInt8(paddingWidth)])
            rgbPixelBuffer.copy(from: sealedBox.ciphertext + sealedBox.nonce + sealedBox.tag + paddingWidthData)

            let encryptedCIImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
            return CryptedImage(ciImage: encryptedCIImage)
        } catch {
            throw error
        }
    }
}

private extension ImageEncryptor {
    
    /// Encrypt a given image data as an image using a key that you specified then
    /// return the encrypted image asynchronously.
    ///
    /// - Parameter imageData: Image data that you want to encrypt such as jpeg
    ///   or png data.
    /// - Parameter keyString: A key string that you use when you encrypt and
    ///   decrypt the image. It must not be empty string.
    /// - Returns: An encrypted image.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    static func encrypt(_ imageData: Data,
                        using keyString: String) async throws -> CryptedImage {
        guard !keyString.isEmpty else {
            throw CryptionError.invalidKey
        }
        
        guard let ciImage = CIImage(data: imageData) else {
            throw CryptionError.invalidInputData
        }
        
        return try _encrypt(ciImage, using: keyString)
    }
    
    /// Encrypt a given CIImage object using a key that you specified then
    /// return the encrypted image asynchronously.
    ///
    /// - Parameter ciImage: A CIImage object that you want to encrypt.
    /// - Parameter keyString: A key string that you use when you encrypt
    ///   and decrypt the image. It must not be empty string.
    /// - Returns: An encrypted image.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    static func encrypt(_ uiImage: UIImage,
                      using keyString: String) async throws -> CryptedImage {
        guard !keyString.isEmpty else {
            throw CryptionError.invalidKey
        }
        
        guard let cgImage = uiImage.cgImage else {
            throw CryptionError.invalidInputData
        }
        let ciImage = CIImage(cgImage: cgImage)
        
        return try _encrypt(ciImage, using: keyString)
    }
    
    /// Encrypt a given CIImage using a key that you specified then deliver the
    /// result asynchronously.
    ///
    /// - Parameter ciImage: A CIImage object that you want to encrypt.
    /// - Parameter keyString: A key that you use when you encrypt
    ///   and decrypt the image. It must not be empty string.
    /// - Returns: An encrypted image.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    static func encrypt(_ ciImage: CIImage,
                      using keyString: String) async throws -> CryptedImage {
        guard !keyString.isEmpty else {
            throw CryptionError.invalidKey
        }
        
        return try _encrypt(ciImage, using: keyString)
    }
}
