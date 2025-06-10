//
//  VisaWalletPublicKeyUtility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

public struct VisaWalletPublicKeyUtility {
    private let visaUtilities: VisaUtilities

    public init(isTestnet: Bool) {
        visaUtilities = .init(isTestnet: isTestnet)
    }

    public func findKeyWithoutDerivation(targetAddress: String, on card: Card) throws(SearchError) -> Data {
        let wallet = try findWalletOnVisaCurve(on: card)

        try validatePublicKey(targetAddress: targetAddress, publicKey: wallet.publicKey)

        return wallet.publicKey
    }

    public func findKeyWithDerivation(targetAddress: String, derivationPath: DerivationPath, on card: Card) throws(SearchError) -> Data {
        let wallet = try findWalletOnVisaCurve(on: card)

        guard let extendedPublicKey = wallet.derivedKeys.keys[derivationPath] else {
            throw .missingDerivedKeys
        }

        try validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: extendedPublicKey, derivationPath: derivationPath)

        return wallet.publicKey
    }

    public func validatePublicKey(targetAddress: String, publicKey: Data) throws(SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: Wallet.PublicKey(seedKey: publicKey, derivationType: .none),
                with: AddressType.default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    public func validateExtendedPublicKey(
        targetAddress: String,
        extendedPublicKey: ExtendedPublicKey,
        derivationPath: DerivationPath
    ) throws(SearchError) {
        let addressService = visaUtilities.addressService

        let createdAddress: Address
        do {
            createdAddress = try addressService.makeAddress(
                for: Wallet.PublicKey(
                    seedKey: extendedPublicKey.publicKey,
                    derivationType: .plain(.init(
                        path: derivationPath,
                        extendedPublicKey: extendedPublicKey
                    ))
                ),
                with: AddressType.default
            )
        } catch {
            throw .failedToGenerateAddress(error)
        }

        try validateCreatedAddress(targetAddress: targetAddress, createdAddress: createdAddress)
    }

    private func validateCreatedAddress(targetAddress: String, createdAddress: any Address) throws(SearchError) {
        guard createdAddress.value.caseInsensitiveCompare(targetAddress) == .orderedSame else {
            throw .addressesNotMatch
        }
    }

    private func findWalletOnVisaCurve(on card: Card) throws(SearchError) -> Card.Wallet {
        guard let wallet = card.wallets.first(where: { $0.curve == visaUtilities.visaBlockchain.curve }) else {
            throw .missingWalletOnTargetCurve
        }

        return wallet
    }
}

public extension VisaWalletPublicKeyUtility {
    enum SearchError: Error {
        case failedToGenerateDerivationPath
        case missingWalletOnTargetCurve
        case missingDerivedKeys
        case failedToGenerateAddress(Error)
        case addressesNotMatch
    }
}
