//
//  CommonDestinationViewModelValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonDestinationViewModelValidator {
    private let walletAddresses: [String]
    private let addressService: AddressService
    private let supportsCompound: Bool

    init(
        walletAddresses: [String],
        addressService: AddressService,
        supportsCompound: Bool
    ) {
        self.walletAddresses = walletAddresses
        self.addressService = addressService
        self.supportsCompound = supportsCompound
    }
}

extension CommonDestinationViewModelValidator: DestinationViewModelValidator {
    func validate(destination address: String) throws {
        if address.isEmpty {
            throw SendAddressServiceError.emptyAddress
        }

        // [REDACTED_TODO_COMMENT]
        if !supportsCompound, walletAddresses.contains(address) {
            throw SendAddressServiceError.sameAsWalletAddress
        }

        if !addressService.validate(address) {
            throw SendAddressServiceError.invalidAddress
        }

        // All checks completed
    }

    func canEmbedAdditionalField(into address: String) -> Bool {
        guard let addressAdditionalFieldService = addressService as? AddressAdditionalFieldService else {
            return true
        }

        return addressAdditionalFieldService.canEmbedAdditionalField(into: address)
    }
}

// MARK: - Errors

private enum SendAddressServiceError {
    case emptyAddress
    case sameAsWalletAddress
    case invalidAddress
}

extension SendAddressServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyAddress:
            return Localization.commonError
        case .sameAsWalletAddress:
            return Localization.sendErrorAddressSameAsWallet
        case .invalidAddress:
            return Localization.sendRecipientAddressError
        }
    }
}
