//
//  CommonCryptoAddressProcessorValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct CommonCryptoAddressProcessorValidator {
    private let walletAddresses: [String]
    private let addressService: AddressService
    private let allowSameAddressTransaction: Bool

    init(
        walletAddresses: [String],
        addressService: AddressService,
        allowSameAddressTransaction: Bool
    ) {
        self.walletAddresses = walletAddresses
        self.addressService = addressService
        self.allowSameAddressTransaction = allowSameAddressTransaction
    }
}

// MARK: - CryptoAddressProcessorValidator

extension CommonCryptoAddressProcessorValidator: CryptoAddressProcessorValidator {
    func validate(destination address: String) throws {
        if address.isEmpty {
            throw SendAddressServiceError.emptyAddress
        }

        // e.g. XRP xAddress
        let resolvedAddress = addressService.resolveAddress(address)
        if !allowSameAddressTransaction, walletAddresses.contains(resolvedAddress) {
            throw SendAddressServiceError.sameAsWalletAddress
        }

        if !addressService.validate(address) {
            throw SendAddressServiceError.invalidAddress
        }
    }

    func canEmbedAdditionalField(into address: String) -> Bool {
        guard let additionalFieldService = addressService as? AddressAdditionalFieldService else {
            return true
        }

        return additionalFieldService.canEmbedAdditionalField(into: address)
    }
}
