//
//  SendAddressService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

// MARK: - Service protocol

protocol SendAddressService {
    func validate(address: String) async throws -> String?
}

// MARK: - Default implementation

class DefaultSendAddressService: SendAddressService {
    private let walletModel: WalletModel
    private let addressService: AddressService

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
        addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
    }

    func validate(address: String) async throws -> String? {
        if address.isEmpty {
            return nil
        }

        if walletModel.wallet.addresses.contains(where: { $0.value == address }) {
            throw SendAddressServiceError.sameAsWalletAddress
        }

        if !addressService.validate(address) {
            throw SendAddressServiceError.invalidAddress
        }

        return address
    }
}

// MARK: - Service that can resolve an address (from a user-friendly one like in NEAR protocol)

class SendResolvableAddressService: SendAddressService {
    private let defaultAddressService: DefaultSendAddressService
    private let addressResolver: AddressResolver

    init(walletModel: WalletModel, addressResolver: AddressResolver) {
        defaultAddressService = DefaultSendAddressService(walletModel: walletModel)
        self.addressResolver = addressResolver
    }

    func validate(address: String) async throws -> String? {
        guard let validatedAddress = try await defaultAddressService.validate(address: address) else {
            return nil
        }

        do {
            return try await addressResolver.resolve(validatedAddress)
        } catch {
            throw SendAddressServiceError.invalidAddress
        }
    }
}

// MARK: - Errors

private enum SendAddressServiceError {
    case sameAsWalletAddress
    case invalidAddress
}

extension SendAddressServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .sameAsWalletAddress:
            return Localization.sendErrorAddressSameAsWallet
        case .invalidAddress:
            return Localization.sendRecipientAddressError
        }
    }
}
