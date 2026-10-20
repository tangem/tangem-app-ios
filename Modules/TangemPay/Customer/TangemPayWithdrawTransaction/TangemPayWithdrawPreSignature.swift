//
//  TangemPayWithdrawPreSignature.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct TangemPayWithdrawPreSignature {
    public let sender: String
    public let hash: Data
    public let salt: Data
    public let structuredData: EIP712TypedData

    public var isHashConsistent: Bool {
        structuredData.signHash == hash
    }

    public var isCollateralWithdraw: Bool {
        let declaredTypes = structuredData.types.mapValues { fields in fields.map { "\($0.type) \($0.name)" } }

        return structuredData.primaryType == Collateral.primaryType
            && declaredTypes == Collateral.types
            && structuredData.domain[DomainKey.name]?.stringValue == Collateral.name
            && structuredData.domain[DomainKey.version]?.stringValue == Collateral.version
    }

    public init(sender: String, hash: Data, salt: Data, structuredData: EIP712TypedData) {
        self.sender = sender
        self.hash = hash
        self.salt = salt
        self.structuredData = structuredData
    }
}

// MARK: - Order withdraw data

public extension TangemPayWithdrawPreSignature {
    init(_ withdrawData: TangemPayOrderResponse.Data.WithdrawData) {
        self.init(
            sender: withdrawData.senderAddress,
            hash: Data(hexString: withdrawData.hash),
            salt: Data(hexString: withdrawData.salt),
            structuredData: withdrawData.structuredData
        )
    }
}

// MARK: - Collateral

private extension TangemPayWithdrawPreSignature {
    enum Collateral {
        static let name = "Collateral"
        static let version = "2"
        static let primaryType = "Withdraw"
        static let types: [String: [String]] = [
            "EIP712Domain": ["string name", "string version", "uint256 chainId", "address verifyingContract", "bytes32 salt"],
            "Withdraw": ["address user", "address asset", "uint256 amount", "address recipient", "uint256 nonce"],
        ]
    }

    enum DomainKey {
        static let name = "name"
        static let version = "version"
    }
}
