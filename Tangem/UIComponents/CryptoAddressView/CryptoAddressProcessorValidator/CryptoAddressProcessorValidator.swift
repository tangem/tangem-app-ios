//
//  CryptoAddressProcessorValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CryptoAddressProcessorValidator {
    func validate(destination: String) throws
    func canEmbedAdditionalField(into address: String) -> Bool
}
