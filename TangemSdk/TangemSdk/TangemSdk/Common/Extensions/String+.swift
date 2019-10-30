//
//  String+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto

public extension String {
    func remove(_ substring: String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
    
    func sha256() -> Data {
        let data = Data(Array(utf8))
        if #available(iOS 13.0, *) {
            let digest = SHA256.hash(data: data)
            return Data(digest)
        } else {
            guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
                return Data()
            }
            CC_SHA256((data as NSData).bytes, CC_LONG(count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
            return res as Data
        }
    }
    
    func sha512() -> Data {
        let data = Data(Array(utf8))
        if #available(iOS 13.0, *) {
            let digest = SHA512.hash(data: data)
            return Data(digest)
        } else {
            guard let res = NSMutableData(length: Int(CC_SHA512_DIGEST_LENGTH)) else {
                return Data()
            }
            CC_SHA512((data as NSData).bytes, CC_LONG(count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
            return res as Data
        }
    }
}
