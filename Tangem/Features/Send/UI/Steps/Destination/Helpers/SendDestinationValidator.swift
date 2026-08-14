//
//  SendDestinationValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import BlockchainSdk

protocol SendDestinationValidator {
    func validate(destination: String) throws(SendAddressServiceError)
    func canEmbedAdditionalField(into address: String) -> Bool
}

class CommonSendDestinationValidator {
    private let walletAddresses: [String]
    private let addressService: AddressService
    private let allowSameAddressTransaction: Bool
    private let blockchain: Blockchain

    init(
        walletAddresses: [String],
        addressService: AddressService,
        allowSameAddressTransaction: Bool,
        blockchain: Blockchain
    ) {
        self.walletAddresses = walletAddresses
        self.addressService = addressService
        self.allowSameAddressTransaction = allowSameAddressTransaction
        self.blockchain = blockchain
    }

    private func isOwnAddress(_ address: String) -> Bool {
        guard let canonicalAddress = EVMAddressUtils.canonicalAddress(address, blockchain: blockchain) else {
            return walletAddresses.contains(address)
        }

        return walletAddresses.contains { EVMAddressUtils.canonicalAddress($0, blockchain: blockchain) == canonicalAddress }
    }
}

extension CommonSendDestinationValidator: SendDestinationValidator {
    func validate(destination address: String) throws(SendAddressServiceError) {
        if address.isEmpty {
            throw SendAddressServiceError.emptyAddress
        }

        // e.g. XRP xAddress
        let resolvedAddress = addressService.resolveAddress(address)
        if !allowSameAddressTransaction, isOwnAddress(resolvedAddress) {
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

enum SendAddressServiceError {
    case emptyAddress
    case sameAsWalletAddress
    case invalidAddress
    case additionalFieldRequired
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
        case .additionalFieldRequired:
            return Localization.sendValidationDestinationTagRequiredDescription
        }
    }
}
