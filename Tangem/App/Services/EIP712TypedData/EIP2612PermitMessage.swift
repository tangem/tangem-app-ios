//
//  EIP2612PermitMessage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

/// https://eips.ethereum.org/EIPS/eip-2612

import Foundation

struct EIP2612PermitMessage: Encodable, JSONEncodable {
    let owner: String
    let spender: String
    let value: String
    let nonce: Int?
    let deadline: Int

    /// - Parameters:
    ///   - owner: Wallet address
    ///   - spender: Contract address
    ///   - value: Amount
    ///   - nonce: Order number transaction on this owner address. Can be used only once
    ///   - deadline: The owner can limit the time a Permit is valid for by setting deadline to a value in the near future
    init(
        owner: String,
        spender: String,
        value: String,
        nonce: Int?,
        deadline: Int
    ) {
        self.owner = owner
        self.spender = spender
        self.value = value
        self.nonce = nonce
        self.deadline = deadline
    }
}
