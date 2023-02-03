//
//  EIP712Domain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// A struct represents EIP712 Domain
public struct EIP712Domain: Codable, JSONEncodable {
    let name: String
    let version: String
    let chainId: Int
    let verifyingContract: String

    init(name: String, version: String, chainId: Int, verifyingContract: String) {
        self.name = name
        self.version = version
        self.chainId = chainId
        self.verifyingContract = verifyingContract
    }
}
