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

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }

    private func validateAddress(_ address: String) -> Bool {
        // Need verify for use KeyPair(accountId: address) in library stellar-sdk for skip bad condition [Array(([UInt8](data))[1...data.count - 3])]
        guard let baseData = address.base32DecodedData, baseData.count >= 4 else {
            return false
        }

        let keyPair = try? KeyPair(accountId: address)
        return keyPair != nil
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
