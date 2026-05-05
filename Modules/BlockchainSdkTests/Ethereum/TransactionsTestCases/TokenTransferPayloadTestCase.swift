//
//  TokenTransferPayloadTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

extension EthereumTransactionTests {
    enum TokenTransferPayloadTestCase {
        // MARK: - Positive cases

        struct Success {
            let name: Comment
            let token: Token
            let refPayload: String

            static let usdcToken_correctPayload: Self = .init(
                name: "USDC Token",
                token: .usdcToken,
                refPayload: "0xa9059cbb00000000000000000000000075739a5bd4b781cf38c59b9492ef9639e46688bf00000000000000000000000000000000000000000000000000000000000003e8"
            )

            static let nftERC721Token_correctPayload: Self = .init(
                name: "NFT ERC721 Token",
                token: .nftERC721Token,
                refPayload: [
                    "0x42842e0e", // Prefix data
                    "000000000000000000000000d0eee5dae303c76548c2bc2d4fbe753fdb014d00", // Source address
                    "00000000000000000000000075739a5bd4b781cf38c59b9492ef9639e46688bf", // Destination address
                    "0000000000000000000000000000000000000000000000000000000000000bda", // Token ID
                ].joined(separator: "")
            )

            static let nftERC1155Token_correctPayload: Self = .init(
                name: "NFT ERC1155 Token",
                token: .nftERC1155Token,
                refPayload: [
                    "0xf242432a", // Prefix data
                    "000000000000000000000000d0eee5dae303c76548c2bc2d4fbe753fdb014d00", // Source address
                    "00000000000000000000000075739a5bd4b781cf38c59b9492ef9639e46688bf", // Destination address
                    "00000000000000000000000000000000000000000000000000000000000000fb", // Token ID
                    "00000000000000000000000000000000000000000000000000000000000003e8", // Amount
                    "00000000000000000000000000000000000000000000000000000000000000a0", // Bytes offset (160)
                    "0000000000000000000000000000000000000000000000000000000000000000", // Bytes length (32)
                ].joined(separator: "")
            )
        }

        // MARK: - Negative cases

        struct Failure {
            let name: Comment
            let token: Token
            let error: EthereumTransactionBuilderError

            static let nftUnknownStandardToken_throwsError: Self = .init(
                name: "NFT Unknown Standard Token",
                token: .nftUnknownStandardToken,
                error: .unsupportedContractType
            )
        }
    }
}
