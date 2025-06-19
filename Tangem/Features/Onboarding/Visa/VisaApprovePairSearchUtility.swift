//
//  VisaApprovePairSearchUtility.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk
import TangemVisa

struct VisaApprovePairSearchUtility {
    let visaUtilities: VisaUtilities
    let visaWalletPublicKeyUtility: VisaWalletPublicKeyUtility

    init(isTestnet: Bool) {
        visaUtilities = .init(isTestnet: isTestnet)
        visaWalletPublicKeyUtility = .init(isTestnet: isTestnet)
    }

    func findApprovePair(for targetAddress: String, userWalletModels: [UserWalletModel]) -> VisaOnboardingTangemWalletDeployApproveViewModel.ApprovePair? {
        for userWalletModel in userWalletModels {
            if userWalletModel.isUserWalletLocked {
                continue
            }

            guard
                let wallet = userWalletModel.keysRepository.keys.first(where: { $0.curve == visaUtilities.mandatoryCurve }),
                let config = userWalletModel.config as? CardUserWalletConfig
            else {
                continue
            }

            do {
                var derivationPath: DerivationPath?
                if let derivationStyle = config.derivationStyle,
                   let path = visaUtilities.visaBlockchain.derivationPath(for: derivationStyle) {
                    derivationPath = path
                }

                let publicKeys = try findPublicKey(for: targetAddress, derivationPath: derivationPath, in: wallet)
                return .init(
                    sessionFilter: config.cardSessionFilter,
                    seedPublicKey: publicKeys.seedKey,
                    derivedPublicKey: publicKeys.derivedKey,
                    derivationPath: derivationPath,
                    tangemSdk: config.makeTangemSdk()
                )
            } catch {
                VisaLogger.error("Failed to find approve pair in user wallet models list", error: error)
            }
        }

        return nil
    }

    private func findPublicKey(
        for targetAddress: String,
        derivationPath: DerivationPath?,
        in wallet: WalletPublicInfo
    ) throws(VisaWalletPublicKeyUtility.SearchError) -> (seedKey: Data, derivedKey: Data) {
        guard let derivationPath else {
            let legacyKey = try findLegacyPublicKey(for: targetAddress, in: wallet)
            return (legacyKey, legacyKey)
        }

        guard let extendedPublicKey = wallet.derivedKeys[derivationPath] else {
            throw .missingDerivedKeys
        }

        try visaWalletPublicKeyUtility.validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: extendedPublicKey, derivationPath: derivationPath)

        return (wallet.publicKey, extendedPublicKey.publicKey)
    }

    private func findLegacyPublicKey(for targetAddress: String, in wallet: WalletPublicInfo) throws(VisaWalletPublicKeyUtility.SearchError) -> Data {
        let publicKey = wallet.publicKey

        try visaWalletPublicKeyUtility.validatePublicKey(targetAddress: targetAddress, publicKey: publicKey)

        return publicKey
    }
}
