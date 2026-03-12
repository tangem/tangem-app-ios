//
//  VirtualAccountUtilities.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk
import TangemPay

public enum VirtualAccountUtilities {
    static var derivationPath: DerivationPath {
        TangemPayUtilities.derivationPath
    }

    static var mandatoryCurve: EllipticCurve {
        TangemPayUtilities.mandatoryCurve
    }

    /// VA uses Polygon (chainId 137)
    static var blockchain: Blockchain {
        .polygon(testnet: false)
    }

    // [REDACTED_TODO_COMMENT]
    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
                decimalCount: 6,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(
                blockchain,
                derivationPath: derivationPath
            )
        )
    }

    static var fiatItem: FiatItem {
        TangemPayUtilities.fiatItem
    }

    static func getKey(from repository: KeysRepository) -> Wallet.PublicKey? {
        TangemPayUtilities.getKey(from: repository)
    }

    static func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try TangemPayUtilities.makeAddress(using: walletPublicKey)
    }

    /// Checks whether the derived wallet at the payment derivation path exists in the keys repository.
    static func hasDerivedWallet(in keysRepository: KeysRepository) -> Bool {
        getKey(from: keysRepository) != nil
    }

    static func _prepareForSign(challengeResponse: PaymentAccountGetChallengeResponse) throws -> SignRequestData {
        let signingRequestMessage = Self.makeCustomerWalletSigningRequestMessage(nonce: challengeResponse.nonce)
        let eip191Message = Self.makeEIP191Message(content: signingRequestMessage)

        guard let eip191MessageData = eip191Message.data(using: .utf8) else {
            throw Error.failedToCreateEIP191Message(content: signingRequestMessage)
        }

        let hash = eip191MessageData.sha3(.keccak256)
        return SignRequestData(message: signingRequestMessage, hash: hash)
    }

    private static func makeCustomerWalletSigningRequestMessage(nonce: String) -> String {
        // This message format is defined by backend
        "Tangem Pay wants to sign in with your account. Nonce: \(nonce)"
    }

    private static func makeEIP191Message(content: String) -> String {
        "\u{19}Ethereum Signed Message:\n\(content.count)\(content)"
    }
}

public extension VirtualAccountUtilities {
    struct SignRequestData: PaymentAccountSignRequestData {
        public let message: String
        public let hash: Data
    }

    enum Error: Swift.Error {
        case failedToCreateEIP191Message(content: String)
    }
}
