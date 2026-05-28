//
//  HederaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hiero

final class HederaAddressService: AddressService {
    private let isTestnet: Bool
    private let addressValidator: HederaAddressValidator

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        addressValidator = HederaAddressValidator(isTestnet: isTestnet)
    }

    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        BSDKLogger.warning(
            """
            Address for the Hedera blockchain (Testnet: \(isTestnet)) is requested but can't be provided. \
            Obtain actual address using `Wallet.address`
            """
        )
        return PlainAddress(value: "", type: addressType)
    }

    func validate(_ address: String) -> Bool {
        return addressValidator.isValid(address: address)
    }

    func validateCustomTokenAddress(_ address: String) -> Bool {
        if validate(address) {
            return true
        }

        return HederaTokenContractAddressConverter.extractEVMAddressBody(from: address) != nil
    }
}
