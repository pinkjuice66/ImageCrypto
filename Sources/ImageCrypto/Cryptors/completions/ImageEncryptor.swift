//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import Foundation
import CryptoKit
import UIKit

/// An object encrypts an image using a given key.
///
/// When encrypting, alpha channel data may not be preserved for preventing
/// premultiplied behavior, so if you have to preserve alpha channel,
/// consider other options.
///
/// Be sure you don't change encrypted image's data accidentally becuase
/// once you change the data of the image there's no way to recover it.
/// Don't use lossy image formats such as jpeg for that purpose,
/// instead use lossless formats like png.
open class ImageEncryptor: ImageCryptor {

    public override init() {
        super.init()
    }
    
    private func _encrypt(_ ciImage: CIImage,
                         using keyString: String,
                         completion: @escaping CryptionHandler) {
        if ciImage.extent.width < 10 || ciImage.extent.height < 1 {
            return completion(.failure(CryptionError.invalidInputData))
        }
        
        let paddingWidth = CVPixelBuffer.getPaddingWidth24RGB(for: Int(ciImage.extent.width)) / 3
        guard let bgraPixelBuffer = CVPixelBuffer.createWithExtension32BGRA(from: ciImage,
                                                                            ciContext: ciContext,
                                                                            heightExtended: 1,
                                                                            widthExtended: paddingWidth),
              let rgbPixelBuffer = bgraPixelBuffer.bgraToRGB() else {
            return completion(.failure(CryptionError.systemError))
        }
        
        guard var rgbPixelData = rgbPixelBuffer.purePixelData else {
            return completion(.failure(CryptionError.systemError))
        }
        
        // remove the last row of the image because last row is reserved for the tag and the nonce
        rgbPixelData.removeLast(CVPixelBufferGetWidth(rgbPixelBuffer) * 3)
        
        do {
            let key = SymmetricKey(from: keyString)
            let sealedBox = try AES.GCM.seal(rgbPixelData, using: key)
            let paddingWidthData = Data([UInt8(paddingWidth)])
            rgbPixelBuffer.copy(from: sealedBox.ciphertext + sealedBox.nonce + sealedBox.tag + paddingWidthData)

            let encryptedCIImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
            completion(.success(CryptedImage(ciImage: encryptedCIImage)))
        } catch {
            completion(.failure(CryptionError.systemError))
        }
    }
}

public extension ImageEncryptor {
    
    /// Encrypt a given image data as an image using a key that you specified then
    /// deliver the result asynchronously.
    ///
    /// - Parameter imageData: Image data that you want to encrypt such as jpeg
    ///   or png data.
    /// - Parameter keyString: A key that you use when you encrypt and
    ///   decrypt the image. It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    func encrypt(_ imageData: Data,
                      using keyString: String,
                      completion: @escaping CryptionHandler) {
        queue.async { [weak self] in
            guard !keyString.isEmpty else {
                return completion(.failure(CryptionError.invalidKey))
            }
            
            guard let ciImage = CIImage(data: imageData) else {
                return completion(.failure(CryptionError.invalidInputData))
            }
            
            self?._encrypt(ciImage, using: keyString, completion: completion)
        }
    }
    
    /// Encrypt a given UIImage using a key that you specified then deliver the
    /// result asynchronously.
    ///
    /// - Parameter uiImage: An UIImage object that you want to encrypt.
    /// - Parameter key: A key that you use when you encrypt and decrypt the image.
    ///   It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    func encrypt(_ uiImage: UIImage,
                      using keyString: String,
                      completion: @escaping CryptionHandler) {
        queue.async { [weak self] in
            guard !keyString.isEmpty else {
                return completion(.failure(CryptionError.invalidKey))
            }
            
            guard let cgImage = uiImage.cgImage else {
                return completion(.failure(CryptionError.invalidInputData))
            }
            let ciImage = CIImage(cgImage: cgImage)
            self?._encrypt(ciImage, using: keyString, completion: completion)
        }
    }
    
    /// Encrypt a given CIImage using a key that you specified then deliver the
    /// result asynchronously.
    ///
    /// - Parameter ciImage: A CIImage object that you want to encrypt.
    /// - Parameter keyString: A key that you use when you encrypt
    ///   and decrypt the image. It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be greater
    /// than original image's.
    /// This is becuase the result image includes the tag and the nonce and
    /// the additional info about paddings on the last row of the image. And
    /// it could have some extra width for the paddings.
    /// The length of the tag and the nonce is 28 bytes,
    /// so we need at least 10 pixels row which imply an image that
    /// has less than 10 pixels per row(i.e. width) will be invalid input.
    func encrypt(_ ciImage: CIImage,
                      using keyString: String,
                      completion: @escaping CryptionHandler) {
        queue.async { [weak self] in
            guard !keyString.isEmpty else {
                return completion(.failure(CryptionError.invalidKey))
            }
            
            self?._encrypt(ciImage, using: keyString, completion: completion)
        }
    }
}
