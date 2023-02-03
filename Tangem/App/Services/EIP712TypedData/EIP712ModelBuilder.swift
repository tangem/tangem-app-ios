//
//  EIP712ModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct EIP712ModelBuilder {
    /// https://eips.ethereum.org/EIPS/eip-2612
    func permitTypedData(domain: EIP712Domain, message: EIP2612PermitMessage) throws -> EIP712TypedData {
        let types: [EIP712Types] = [.eip712Domain, .permit]

        return EIP712TypedData(
            types: types.reduce(into: [:]) { $0[$1.key] = $1.types },
            primaryType: EIP712Types.permit.key,
            domain: try domain.encodeToJSON(),
            message: try message.encodeToJSON()
        )
    }
}
