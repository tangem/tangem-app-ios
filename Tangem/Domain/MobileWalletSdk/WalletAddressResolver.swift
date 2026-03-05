//
//  WalletAddressResolver.swift
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
        let derivationType = try makeDerivationType(for: blockchain, keyInfo: keyInfo)
        let walletPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: derivationType)
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: blockchain.derivationPath(for: .v3))

        do {
            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            let address = try makeAddress(for: blockchain, walletPublicKey: walletPublicKey, addressService: addressService)
            return NetworkAddressPair(blockchainNetwork: blockchainNetwork, address: address.value)
        } catch {
            throw Error.addressGenerationFailed(blockchain: blockchain, underlying: error)
        }
    }

    private func makeDerivationType(for blockchain: Blockchain, keyInfo: KeyInfo) throws -> Wallet.PublicKey.DerivationType? {
        switch blockchain {
        case .cardano(let extended):
            if extended {
                guard let derivationPath = blockchain.derivationPath(for: .v3),
                      let firstKey = keyInfo.derivedKeys[derivationPath],
                      let secondPath = try? CardanoUtil().extendedDerivationPath(for: derivationPath),
                      let secondKey = keyInfo.derivedKeys[secondPath] else {
                    throw Error.missingCardanoDerivedKeys
                }
                return .double(
                    first: .init(path: derivationPath, extendedPublicKey: firstKey),
                    second: .init(path: secondPath, extendedPublicKey: secondKey)
                )
            } else {
                guard let derivationPath = blockchain.derivationPath(for: .v3),
                      let extendedPublicKey = keyInfo.derivedKeys[derivationPath] else {
                    throw Error.missingDerivedKey(blockchain: blockchain)
                }
                return .plain(.init(path: derivationPath, extendedPublicKey: extendedPublicKey))
            }
        case .hedera, .chia:
            throw Error.unsupportedBlockchain(blockchain)
        default:
            guard let derivationPath = blockchain.derivationPath(for: .v3),
                  let extendedPublicKey = keyInfo.derivedKeys[derivationPath] else {
                throw Error.missingDerivedKey(blockchain: blockchain)
            }
            return .plain(.init(path: derivationPath, extendedPublicKey: extendedPublicKey))
        }
    }

    private func makeAddress(
        for blockchain: Blockchain,
        walletPublicKey: Wallet.PublicKey,
        addressService: AddressService
    ) throws -> Address {
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
            return try addressService.makeAddress(for: quaiWalletPublicKey, with: .default)
        default:
            return try addressService.makeAddress(for: walletPublicKey, with: .default)
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
