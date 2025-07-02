//
//  Data+.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk
import TangemFoundation

extension Data {
    func cardanoStakingKey() -> Data {
        let stakingKeyBytes = Data(
            bytes[bytes.count / 2 ..< bytes.count]
        ).trailingZeroPadding(toLength: 192)

        return Data(stakingKeyBytes)
    }
}
