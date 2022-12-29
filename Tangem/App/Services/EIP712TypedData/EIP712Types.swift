//
//  EIP712Types.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum EIP712Types {
    case eip712Domain
    case permit

    var key: String {
        switch self {
        case .eip712Domain:
            return "EIP712Domain"
        case .permit:
            return "Permit"
        }
    }

    var types: [EIP712Type] {
        switch self {
        case .eip712Domain:
            return [
                EIP712Type(name: "name", type: "string"),
                EIP712Type(name: "version", type: "string"),
                EIP712Type(name: "chainId", type: "uint256"),
                EIP712Type(name: "verifyingContract", type: "address"),
            ]
        case .permit:
            return [
                EIP712Type(name: "owner", type: "address"),
                EIP712Type(name: "spender", type: "address"),
                EIP712Type(name: "value", type: "uint256"),
//                EIP712Type(name: "nonce", type: "uint256"),
                EIP712Type(name: "deadline", type: "uint256"),
            ]
        }
    }
}
