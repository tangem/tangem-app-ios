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
    let visaWalletPublicKeyUtility: VisaWalletPublicKeyUtility

    init(isTestnet: Bool) {
        visaWalletPublicKeyUtility = VisaWalletPublicKeyUtility(isTestnet: isTestnet)
    }

    func findApprovePair(for targetAddress: String, userWalletModels: [UserWalletModel]) -> VisaOnboardingTangemWalletDeployApproveViewModel.ApprovePair? {
        for userWalletModel in userWalletModels {
            if userWalletModel.isUserWalletLocked {
                continue
            }

            let config = userWalletModel.config
            let sessionFilter = config.cardSessionFilter
            guard
                let wallet = userWalletModel.keysRepository.keys.first(where: { $0.curve == VisaUtilities.mandatoryCurve })
            else {
                continue
            }

            do {
                var derivationPath: DerivationPath?
                if let derivationStyle = config.derivationStyle,
                   let path = VisaUtilities.visaDerivationPath(style: derivationStyle) {
                    derivationPath = path
                }

                let publicKeys = try findPublicKey(for: targetAddress, derivationPath: derivationPath, in: wallet)
                return .init(
                    sessionFilter: sessionFilter,
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
        in wallet: KeyInfo
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

    private func findLegacyPublicKey(for targetAddress: String, in wallet: KeyInfo) throws(VisaWalletPublicKeyUtility.SearchError) -> Data {
        let publicKey = wallet.publicKey

        try visaWalletPublicKeyUtility.validatePublicKey(targetAddress: targetAddress, publicKey: publicKey)

        return publicKey
    }
}
