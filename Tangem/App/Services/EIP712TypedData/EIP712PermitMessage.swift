//
//  EIP712PermitMessage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

/// https://eips.ethereum.org/EIPS/eip-2612

import Foundation

struct EIP712PermitMessage: Encodable, JSONEncodable {
    let owner: String
    let spender: String
    let value: String
    let nonce: Int
    let deadline: Int

    /// - Parameters:
    ///   - owner: Wallet address
    ///   - spender: Contract address
    ///   - value: amount ?
    ///   - nonce: number that can only be used once https://ru.wikipedia.org/wiki/Nonce
    ///   - deadline: The owner can limit the time a Permit is valid for by setting deadline to a value in the near future
    init(
        owner: String,
        spender: String,
        value: String,
        nonce: Int,
        deadline: Int
    ) {
        self.owner = owner
        self.spender = spender
        self.value = value
        self.nonce = nonce
        self.deadline = deadline
    }
}
