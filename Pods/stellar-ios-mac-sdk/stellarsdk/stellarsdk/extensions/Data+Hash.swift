//
//  Data+Hash.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

#if XC9
import CSwiftyCommonCrypto
#else
import CommonCrypto
#endif

import Foundation

public extension String {
    var sha256Hash: Data {
        get {
             let data = self.data(using: .utf8)!
             var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

             _ = digest.withUnsafeMutableBytes { (digestBytes) in
                 data.withUnsafeBytes { (stringBytes) in
                 CC_SHA256(stringBytes, CC_LONG(data.count), digestBytes)
             }
         }
         return digest
         }
     }
}

