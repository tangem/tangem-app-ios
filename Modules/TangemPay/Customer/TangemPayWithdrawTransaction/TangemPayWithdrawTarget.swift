//
//  TangemPayWithdrawTarget.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayWithdrawTarget: Hashable, Sendable {
    public let chainId: Int
    public let tokenContractAddress: String

    public init(chainId: Int, tokenContractAddress: String) {
        self.chainId = chainId
        self.tokenContractAddress = tokenContractAddress
    }
}
