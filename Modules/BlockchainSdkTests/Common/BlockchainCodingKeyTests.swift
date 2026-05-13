//
//  BlockchainCodingKeyTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Testing
import CryptoKit
import TangemSdk
import WalletCore
@testable import BlockchainSdk

struct BlockchainCodingKeyTests {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test
    func codingKeys() throws {
        BlockchainSdk.Blockchain.allMainnetCases.forEach {
            let recoveredFromCodable = try? decoder.decode(Blockchain.self, from: try encoder.encode($0))
            #expect(recoveredFromCodable == $0, "\($0.displayName)")
        }
    }
}
