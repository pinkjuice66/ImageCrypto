//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import UIKit
import CryptoKit

open class ImageCryptor {
    public typealias CryptionHandler = (Result<CryptedImage, Error>) -> (Void)
    
    public init() { }
    
    public enum CryptionError: Error {
        case invalidKey
        case invalidInputData
        case systemError
    }
    
    public struct CryptedImage {
        public var ciImage: CIImage
        public var uiImage: UIImage {
            UIImage(ciImage: ciImage)
        }
        public var pngData: Data? {
            CIContext().pngRepresentation(of: ciImage,
                                        format: .BGRA8,
                                        colorSpace: ciImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!)
        }
    }
    
    lazy internal var queue = DispatchQueue(label: "com.encryptor", target: .global())
    
    lazy internal var ciContext = CIContext()
}
