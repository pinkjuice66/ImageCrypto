![logo](https://user-images.githubusercontent.com/44376599/198014705-493050cb-6349-4b5f-8742-37d45a926dfb.png)
![example](https://user-images.githubusercontent.com/44376599/198014793-c0a941bd-85d8-4e94-89b9-bb35c2340565.png)

![1.0.0](https://img.shields.io/github/v/release/pinkjuice66/ImageCrypto)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![SwiftPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager/)


## Features
- Encrypt and decrypt an image in a safe and a easy way.
- UIImage, CIImage, image format data(jpeg, png..) supported
- Good performance(0.4 secs taken for encrypting a 8.6MP image in M1 simulator)

## Usage
```swift
import ImageCrypto 

// encrypt an image
let encryptor = ImageEncryptor()
encryptor.encrypt(data, using: "your key") { result in
    if case let result(encryptedImage) = result {
        // do what you want with the encrypted image. 
    }
}

// decrypt an image
let decryptor = ImageDecryptor()
decryptor.decrypt(data, using: "your key") { result in
    if case let result(decryptedImage) = result {
        // do what you want with the decrypted image. 
    }
}
```

## Caution
If the encrypted image data change, there’s no way to recover original image. 

So never use lossy image format like jpeg for the encrypted image.

## Requirements
- iOS 13.0+
- Swift 5.6

## Installation
#### Swift Package Manager : https://github.com/pinkjuice66/ImageCrypto

## Author
Jinseok Park 

- contact : pinkjuice66@gmail.com

Distributed under the MIT license. See LICENSE for more information.
