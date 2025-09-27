//
//  QuaiTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing
import WalletCore
import BigInt

struct QuaiTransactionTests {
    private let protoUtils = QuaiProtobufUtils()

    @Test
    func transferCoinTransaction() throws {
        // given
        let input = EthereumSigningInput.with { input in
            input.chainID = BigUInt(9).serialize()
            input.nonce = BigUInt(23).serialize()
            input.toAddress = "0x0027405CF43C57277b20D866f0f0bDca0D59071A"

            input.transaction = .with { transaction in
                transaction.contractGeneric = .with {
                    $0.data = Data(hexString: "0x")
                }
            }

            input.txMode = .legacy
            input.gasLimit = BigInt(28000).serialize()
            input.gasPrice = BigInt(7465326404574).serialize()
        }

        // when
        let unsignedProto = protoUtils.buildUnsignedProto(signingInput: input)
        let hashForSign = unsignedProto.sha3(.keccak256)

        // then
        #expect(hashForSign.hexString == "465C7B09097A66E4ED4078DEEDC7F810B9F29C67D1BB6B89E4E03E82A13E2E79")
    }
}
