//
//  MobileUserWalletConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemAssets
import TangemMobileWalletSdk
import TangemFoundation
import TangemLocalization

struct MobileUserWalletConfig {
    let mobileWalletInfo: MobileWalletInfo
}

extension MobileUserWalletConfig: UserWalletConfig {
    var cardsCount: Int { 0 }

    var cardSetLabel: String {
        Localization.hwMobileWallet
    }

    var defaultName: String { Localization.hwMobileWallet }

    var existingCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var derivationStyle: DerivationStyle? {
        .v3
    }

    var createWalletCurves: [EllipticCurve] {
        existingCurves
    }

    var tangemSigner: TangemSigner {
        MobileWalletSigner(userWalletConfig: self)
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        []
    }

    var isWalletsCreated: Bool { true }

    var supportedBlockchains: Set<Blockchain> {
        var blockchains = SupportedBlockchains(version: .v2).blockchains()
        blockchains.remove(.hedera(curve: .ed25519_slip0010, testnet: false))
        return blockchains
    }

    var defaultBlockchains: [StorageEntry] {
        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

        let entries: [StorageEntry] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var persistentBlockchains: [StorageEntry]? { nil }

    var embeddedBlockchain: StorageEntry? { nil }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: mobileWalletInfo)
    }

    var userWalletIdSeed: Data? {
        mobileWalletInfo.keys.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .mobileWallet
    }

    var cardHeaderImage: ImageType? {
        return nil
    }

    var cardSessionFilter: SessionFilter { .cardId("") }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode: return .hidden
        case .passcode: return .hidden
        case .longTap: return .hidden
        case .send: return .available
        case .longHashes: return .available
        case .signedHashesCounter: return .hidden
        case .backup: return .hidden
        case .twinning: return .hidden
        case .exchange: return .available
        case .walletConnect: return .available
        case .multiCurrency: return .available
        case .resetToFactory: return .hidden
        case .receive: return .available
        case .withdrawal: return .available
        case .hdWallets: return .available
        case .staking: return .available
        case .topup: return .available
        case .tokenSynchronization: return .available
        case .referralProgram: return .hidden
        case .swapping: return .available
        case .displayHashesCount: return .available
        case .transactionHistory: return .hidden
        case .accessCodeRecoverySettings: return .hidden
        case .promotion: return .available
        case .nft: return .available
        case .iCloudBackup:
            if mobileWalletInfo.hasICloudBackup {
                return .disabled()
            }

            return .available
        case .mnemonicBackup:
            if mobileWalletInfo.hasMnemonicBackup {
                return .disabled()
            }

            return .available
        case .userWalletAccessCode:
            if mobileWalletInfo.isAccessCodeSet {
                return .disabled()
            }

            return .available
        case .userWalletBackup:
            return .available
        case .isBalanceRestrictionActive:
            return .available
        case .userWalletUpgrade:
            return .available
        case .cardSettings:
            return .hidden
        case .isHardwareLimited:
            return .hidden
        }
    }

    func makeBackupService() -> BackupService {
        fatalError("Implementation not required")
    }

    func makeTangemSdk() -> TangemSdk {
        fatalError("Implementation not required")
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> any WalletModelsFactory {
        CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> any AnyWalletManagerFactory {
        GenericWalletManagerFactory()
    }

    func makeMainHeaderProviderFactory() -> any MainHeaderProviderFactory {
        MobileMainHeaderProviderFactory()
    }

    func makeOnboardingStepsBuilder(backupService: BackupService) -> any OnboardingStepsBuilder {
        MobileOnboardingStepsBuilder(backupService: backupService)
    }
}
