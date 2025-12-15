//
//  XRPAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct XRPAddressService {
    let curve: EllipticCurve

    init(curve: EllipticCurve) {
        self.curve = curve
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension XRPAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        var key: Data
        switch curve {
        case .secp256k1:
            key = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        case .ed25519, .ed25519_slip0010:
            try publicKey.blockchainKey.validateAsEdKey()
            key = [UInt8(0xED)] + publicKey.blockchainKey
        default:
            fatalError("unsupported curve")
        }
        let input = key.sha256Ripemd160
        let buffer = [0x00] + input
        let checkSum = Data(buffer.getDoubleSHA256()[0 ..< 4])
        let address = XRPBase58.getString(from: buffer + checkSum)

        return PlainAddress(value: address, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension XRPAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if XRPSeedWallet.validate(address: address) {
            return true
        }

        if let _ = try? XRPAddress.decodeXAddress(xAddress: address) {
            return true
        }

        return false
    }

    func validateCustomTokenAddress(_ address: String) -> Bool {
        do {
            let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: address)
            guard validate(issuer) else {
                return false
            }

            switch currency.count {
            case 3:
                return currency.range(of: "^[A-Za-z0-9?!@#$%^&*<>(){}\\[\\]|]{3}$", options: .regularExpression) != nil
            case 40:
                return currency.range(of: "^[A-Fa-f0-9]{40}$", options: .regularExpression) != nil
            default:
                return false
            }
        } catch {
            return false
        }
    }

    func resolveAddress(_ address: String) -> String {
        if let address = try? XRPAddress.decodeXAddress(xAddress: address) {
            return address.rAddress
        }

        return address
    }
}

@available(iOS 13.0, *)
extension XRPAddressService: AddressAdditionalFieldService {
    func canEmbedAdditionalField(into address: String) -> Bool {
        let xAddress = try? XRPAddress(xAddress: address)
        return xAddress == nil
    }
}
