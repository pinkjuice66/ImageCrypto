//
//  Created by Jinseok Park on 2022/10/24.
//  Copyright © 2022 Jinseok Park. All rights reserved.

import Foundation
import CryptoKit

internal extension SymmetricKey {
    
    /// Init with not empty string. It automatically apply SHA256 to a given
    /// keyString
    init(from keyString: String) {
        var sha256 = SHA256()
        let keyData = keyString.data(using: .utf8)!
        sha256.update(data: keyData)
        let hashedKeyData = Data(sha256.finalize())
        self = SymmetricKey(data: hashedKeyData)
    }
}

