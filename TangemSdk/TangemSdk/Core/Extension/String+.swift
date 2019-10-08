//
//  String+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public extension String {
    func remove(_ substring: String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
    
    @available(iOS 13.0, *)
    func sha256() -> Data {
        let data = Array(utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }
}
