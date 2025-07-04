//
//  XDCAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct XDCAddressService {
    // MARK: - Private Properties

    private let ethereumAddressService = AddressServiceFactory(blockchain: .ethereum(testnet: false)).makeAddressService()
    private let converter = XDCAddressConverter()
}

// MARK: - AddressProvider protocol conformance

extension XDCAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let ethAddress = try ethereumAddressService.makeAddress(for: publicKey, with: .default).value

        switch addressType {
        case .default:
            let xdcAddress = converter.convertToXDCAddress(ethAddress)
            return PlainAddress(value: xdcAddress, publicKey: publicKey, type: addressType)
        case .legacy:
            return PlainAddress(value: ethAddress, publicKey: publicKey, type: addressType)
        }
    }
}

// MARK: - AddressValidator protocol conformance

extension XDCAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let converted = try? converter.convertToETHAddress(address) else {
            return false
        }

        return ethereumAddressService.validate(converted)
    }
}
