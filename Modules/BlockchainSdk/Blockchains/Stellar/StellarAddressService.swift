//
//  StellarAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

struct StellarAddressService {}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension StellarAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsEdKey()

        let stellarPublicKey = try PublicKey(Array(publicKey.blockchainKey))
        let keyPair = KeyPair(publicKey: stellarPublicKey)
        let address = keyPair.accountId

        return PlainAddress(value: address, type: addressType)
    }

    private func validateAddress(_ address: String) -> Bool {
        // A StrKey account id is `G` + 55 upper-case base32 characters. The SDK's base32 decoder is
        // case-insensitive and `KeyPair(accountId:)` never checks the trailing CRC16, so without this a
        // one-character typo (or a lower-cased address Horizon rejects) was accepted and, for an uncreated
        // destination, funded as a brand-new account nobody holds the key for.
        guard address.range(of: Constants.strKeyAccountIdPattern, options: .regularExpression) != nil else {
            return false
        }

        // Length, version byte, payload size and checksum (`decodeCheck`); also guards the
        // `[1...count - 3]` slice `KeyPair(accountId:)` performs.
        return address.isValidEd25519PublicKey()
    }

    private func validateContractAddress(_ contractAddress: String) -> Bool {
        // Fast fail if format doesn't look like a valid asset ID
        let pattern = "^[A-Za-z0-9]{1,12}[:-]G[A-Z2-7]{55}(-1)?$"
        guard contractAddress.range(of: pattern, options: .regularExpression) != nil else {
            return false
        }

        let normalizedContractAddress = StellarAssetIdParser().normalizeAssetId(contractAddress)
        guard let issuer = normalizedContractAddress.split(separator: "-", omittingEmptySubsequences: false).map(String.init)[safe: 1],
              validateAddress(issuer)
        else {
            return false
        }

        return true
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension StellarAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        validateAddress(address)
    }

    func validateCustomTokenAddress(_ address: String) -> Bool {
        validateContractAddress(address)
    }
}

// MARK: - Constants

private extension StellarAddressService {
    enum Constants {
        static let strKeyAccountIdPattern = "^G[A-Z2-7]{55}$"
    }
}
