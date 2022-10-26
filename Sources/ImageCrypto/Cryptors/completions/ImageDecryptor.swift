//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import Foundation
import UIKit
import CryptoKit

/// An object decrypts an image using a given key.
open class ImageDecryptor: ImageCryptor {
    
    public override init() {
        super.init()
    }
    
    private func _decrypt(_ ciImage: CIImage,
                         using key: String,
                         completion: @escaping CryptionHandler) {
        if ciImage.extent.width < 10 || ciImage.extent.height < 2 {
            return completion(.failure(CryptionError.invalidInputData))
        }
        
        guard let bgraPixelBuffer = CVPixelBuffer.create32BGRA(from: ciImage,
                                                               ciContext: ciContext),
              let rgbPixelBuffer = bgraPixelBuffer.bgraToRGB() else {
            return completion(.failure(CryptionError.systemError))
        }
        
        guard var rgbPixelData = rgbPixelBuffer.purePixelData else {
            return completion(.failure(CryptionError.systemError))
        }
        
        let (nonce, tag, widthPadding) = extractTagAndNonce(from: &rgbPixelData,
                           width: rgbPixelBuffer.width,
                           height: rgbPixelBuffer.height)
        
        guard let nonce = nonce,
              let sealedBox = try? AES.GCM.SealedBox(nonce: nonce,
                                                     ciphertext: rgbPixelData,
                                                     tag: tag) else {
            return completion(.failure(CryptionError.invalidInputData))
        }
        
        let key = SymmetricKey(from: key)
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
            return completion(.failure(CryptionError.invalidKey))
        }
        
        rgbPixelBuffer.copy(from: decryptedData)
        
        let decryptedImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
        let rect = CGRect(x: 0, y: 0,
                          width: decryptedImage.extent.width - CGFloat(widthPadding),
                          height: decryptedImage.extent.height - 1)
        let resultImage = decryptedImage.cropped(to: rect)
        
        completion(.success(CryptedImage(ciImage: resultImage)))
    }
    
    private func extractTagAndNonce(from data: inout Data, width: Int, height: Int) -> (nonce: AES.GCM.Nonce?, tag: Data, widthPadding: Int) {
        let lastRowStartIndex = 3 * width * (height - 1)
        let nonceRange = lastRowStartIndex...lastRowStartIndex+11
        let tagRange = lastRowStartIndex+12...lastRowStartIndex+27
        let nonce = try? AES.GCM.Nonce(data: data[nonceRange]) // 12 bytes
        let tag = data[tagRange] // 16 bytes
        
        let widthPadding = Int(data[lastRowStartIndex+28])
        
        // remove last row
        data.removeLast(3 * width)
        
        return (nonce, tag, widthPadding)
    }
}

public extension ImageDecryptor {
    
    /// Decrypt a given image data as an image using a key that you specified then
    /// deliver the result asynchronously.
    ///
    /// - Parameter imageData: Image data that you want to decrypt. It must have
    ///   not been changed since it was encrypted.
    /// - Parameter keyString: A key that you use when you decrypt
    ///   the image. It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be less than the encrypted
    /// image's. This is becuase the result image removes the padding width,
    /// the tag and the nonce on the last row of the image.
    func decrypt(_ imageData: Data,
                        using keyString: String,
                        completion: @escaping CryptionHandler) {
        queue.async { [weak self] in
            guard !keyString.isEmpty else {
                return completion(.failure(CryptionError.invalidKey))
            }
            
            guard let ciImage = CIImage(data: imageData) else {
                return completion(.failure(CryptionError.invalidInputData))
            }
            
            self?._decrypt(ciImage, using: keyString, completion: completion)
        }
    }
    
    /// Decrypt a given UIImage object using a key that you specified then
    /// deliver the result asynchronously.
    ///
    /// - Parameter uiImage: An UIImage object that you want to decrypt. It must have
    ///   not been changed since it was encrypted.
    /// - Parameter keyString: A key that you use when you decrypt
    ///   the image. It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be less than the encrypted
    /// image's. This is becuase the result image removes the padding width,
    /// the tag and the nonce on the last row of the image.
    func decrypt(_ uiImage: UIImage,
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
            
            self?._decrypt(ciImage, using: keyString, completion: completion)
        }
    }
    
    /// Decrypt a given CIImage object using a key that you specified then
    /// deliver the result asynchronously.
    ///
    /// - Parameter ciImage: An CIImage object that you want to decrypt. It must have
    ///   not been changed since it was encrypted.
    /// - Parameter keyString: A key that you use when you decrypt
    ///   the image. It must not be empty string.
    /// - Parameter completion: An escaping closure that'll be invoked when the
    ///   process finishes or an error occurs.
    ///
    /// The height and the width of the result image will be less than the encrypted
    /// image's. This is becuase the result image removes the padding width,
    /// the tag and the nonce on the last row of the image.
    func decrypt(_ ciImage: CIImage,
                        using keyString: String,
                        completion: @escaping CryptionHandler) {
        queue.async { [weak self] in
            guard !keyString.isEmpty else {
                return completion(.failure(CryptionError.invalidKey))
            }
            
            self?._decrypt(ciImage, using: keyString, completion: completion)
        }
    }
}
