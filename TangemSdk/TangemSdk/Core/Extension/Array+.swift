//
//  Array+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

extension Array where Element == Tlv {
    /// Convinience extension for TLV array serialization
    var bytes: Data {
        return Data(self.reduce([], { $0 + $1.bytes }))
    }
}
