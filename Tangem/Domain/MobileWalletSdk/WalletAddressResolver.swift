//
//  MobileWalletAddressResolver.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemMobileWalletSdk
import BlockchainSdk

// MARK: - NetworkAddressPair

struct NetworkAddressPair {
    let blockchainNetwork: BlockchainNetwork
    let address: String
}

// MARK: - WalletAddressResolver

/// Resolves a single blockchain address from key infos. Used by features (e.g. initial token sync) that need [network: address] pairs.
struct WalletAddressResolver {
    /// Resolves address for the given blockchain using the provided key infos.
    /// - Throws: `WalletAddressResolver.Error` if the curve has no key, derived keys are missing, or address generation fails.
    func resolveAddress(
        for blockchain: Blockchain,
        keyInfos: [KeyInfo]
    ) throws -> NetworkAddressPair {
        guard let keyInfo = keyInfos.first(where: { $0.curve == blockchain.curve }) else {
            throw Error.noKeyInfoForCurve(blockchain.curve)
        }

        let seedKey = keyInfo.publicKey

        let derivationType: Wallet.PublicKey.DerivationType?
        switch blockchain {
        case .cardano:
            guard let derivationPath = blockchain.derivationPath(for: .v3),
                  let firstKey = keyInfo.derivedKeys[derivationPath],
                  let secondPath = try? CardanoUtil().extendedDerivationPath(for: derivationPath),
                  let secondKey = keyInfo.derivedKeys[secondPath] else {
                throw Error.missingCardanoDerivedKeys
            }
            derivationType = .double(
                first: .init(path: derivationPath, extendedPublicKey: firstKey),
                second: .init(path: secondPath, extendedPublicKey: secondKey)
            )
        case .hedera, .chia:
            throw Error.unsupportedBlockchain(blockchain)
        default:
            guard let derivationPath = blockchain.derivationPath(for: .v3),
                  let extendedPublicKey = keyInfo.derivedKeys[derivationPath] else {
                throw Error.missingDerivedKey(blockchain: blockchain)
            }
            derivationType = .plain(.init(path: derivationPath, extendedPublicKey: extendedPublicKey))
        }

        let walletPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: derivationType)
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: blockchain.derivationPath(for: .v3))

        do {
            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            let address: Address

            switch blockchain {
            case .quai:
                guard let extendedPublicKey = walletPublicKey.derivationType?.hdKey.extendedPublicKey else {
                    throw Error.quaiRequiresDerivationType
                }
                let zoneDerivedResult = try QuaiDerivationUtils().derive(
                    extendedPublicKey: extendedPublicKey,
                    with: .default
                )
                let quaiWalletPublicKey = Wallet.PublicKey(
                    seedKey: zoneDerivedResult.key.publicKey,
                    derivationType: .none
                )
                address = try addressService.makeAddress(for: quaiWalletPublicKey, with: .default)
            default:
                address = try addressService.makeAddress(for: walletPublicKey, with: .default)
            }

            return NetworkAddressPair(blockchainNetwork: blockchainNetwork, address: address.value)
        } catch {
            throw Error.addressGenerationFailed(blockchain: blockchain, underlying: error)
        }
    }
}

extension WalletAddressResolver {
    enum Error: Swift.Error {
        case noKeyInfoForCurve(EllipticCurve)
        case unsupportedBlockchain(Blockchain)
        case missingCardanoDerivedKeys
        case missingDerivedKey(blockchain: Blockchain)
        case quaiRequiresDerivationType
        case addressGenerationFailed(blockchain: Blockchain, underlying: Swift.Error)
    }
}