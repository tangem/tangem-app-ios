//
//  JointOperationFeeConstants.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum JointOperationFeeConstants {
    static let baseGas = BigUInt(110_000)
    static let deployGas = BigUInt(300_000)
    static let gasPriceMarginPercent = BigUInt(100)
    static let safeTxGasBufferPercent = BigUInt(50)
    static let gasPriceCeilingMultiplier = BigUInt(4)
    static let allowedBaseGas: Set<BigUInt> = [baseGas, baseGas + deployGas]
    static let zeroAddress = "0x0000000000000000000000000000000000000000"

    static var refundReceiver: String {
        switch FeatureStorage.instance.tangemAPIType {
        case .prod:
            return prodRefundReceiver
        case .dev, .stage, .mock:
            return devRefundReceiver
        }
    }

    private static let prodRefundReceiver = "0x2fD66Abd3BFeffA81851A9C61c10E979369A031c"
    private static let devRefundReceiver = "0x5F2C435DF8D00D0cF842a52Dd166B1Dcd69734C2"
}
