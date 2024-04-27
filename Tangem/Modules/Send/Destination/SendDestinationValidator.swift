//
//  SendDestinationValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// class?
struct SendDestinationValidator {
    let addressService: SendAddressService

    func validate(_ input: SendAddress) async throws -> SendAddress {
        let validatedAddress = try await addressService.validate(address: input.value ?? "")
        return SendAddress(value: validatedAddress, source: input.source)
    }
}
