//
//  Data+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Data {
    static func randomData(count: Int) -> Data {
        return Data(repeating: UInt8.random(in: 0 ... 255), count: count)
    }
}
