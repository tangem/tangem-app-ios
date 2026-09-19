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
    /// Contract address of the token being sent, if any. Tokens sent to their own contract are lost.
    private let tokenContractAddress: String?
    private let addressService: AddressService
    private let allowSameAddressTransaction: Bool
    private let blockchain: Blockchain

    init(
        walletAddresses: [String],
        tokenContractAddress: String? = nil,
        addressService: AddressService,
        allowSameAddressTransaction: Bool,
        blockchain: Blockchain
    ) {
        self.walletAddresses = walletAddresses
        self.tokenContractAddress = tokenContractAddress
        self.addressService = addressService
        self.allowSameAddressTransaction = allowSameAddressTransaction
        self.blockchain = blockchain
    }

    private func isOwnAddress(_ address: String) -> Bool {
        walletAddresses.contains { isSameAddress($0, address) }
    }

    private func isTokenContractAddress(_ address: String) -> Bool {
        guard let tokenContractAddress else {
            return false
        }

        return isSameAddress(tokenContractAddress, address)
    }

    private func isSameAddress(_ lhs: String, _ rhs: String) -> Bool {
        guard let canonicalRhs = EVMAddressUtils.canonicalAddress(rhs, blockchain: blockchain) else {
            return lhs == rhs
        }

        return EVMAddressUtils.canonicalAddress(lhs, blockchain: blockchain) == canonicalRhs
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

        if isTokenContractAddress(resolvedAddress) {
            throw SendAddressServiceError.tokenContractAddress
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
    case tokenContractAddress
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
        case .tokenContractAddress:
            return Localization.sendErrorAddressIsTokenContract
        case .invalidAddress:
            return Localization.sendRecipientAddressError
        case .additionalFieldRequired:
            return Localization.sendValidationDestinationTagRequiredDescription
        }
    }
}
