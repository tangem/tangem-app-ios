//
//  BlockBookUTXOProviderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemNetworkUtils
@testable import BlockchainSdk

@Suite("BlockBook fee rate conversion")
struct BlockBookUTXOProviderTests {
    @Test(
        "Fee rate per kilobyte becomes satoshi per byte over 1000 bytes, rounded up",
        arguments: [
            (Decimal(string: "0.01")!, Decimal(1000)),
            (Decimal(string: "0.01004544")!, Decimal(1005)),
            (Decimal(string: "0.00002048")!, Decimal(3)),
        ]
    )
    func feeRatePerByte(feePerKilobyte: Decimal, expectedSatoshiPerByte: Decimal) throws {
        let sut = BlockBookUTXOProvider(
            blockchain: .ravencoin(testnet: false),
            blockBookConfig: NowNodesBlockBookConfig(apiKeyHeaderName: nil, apiKeyHeaderValue: nil),
            networkConfiguration: TangemProviderConfiguration(logOptions: nil, urlSessionConfiguration: .ephemeral)
        )

        let satoshiPerByte = try sut.convertFeeRate(feePerKilobyte)

        #expect(satoshiPerByte == expectedSatoshiPerByte)
    }
}
