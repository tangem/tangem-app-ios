//
//  HotUserWalletConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemAssets
import TangemHotSdk
import TangemFoundation

struct HotUserWalletConfig {
    let hotWalletInfo: HotWalletInfo
}

extension HotUserWalletConfig: UserWalletConfig {
    var cardsCount: Int { 0 }

    var cardSetLabel: String? {
        #warning("Add localization")
        return nil
    }

    var defaultName: String { "Mobile Wallet" }

    var existingCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var createWalletCurves: [EllipticCurve] {
        existingCurves
    }

    var tangemSigner: TangemSigner {
        MobileWalletSigner(hotWalletInfo: hotWalletInfo)
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        GeneralNotificationEventsFactory().makeNotifications(for: hotWalletInfo)
    }

    var isWalletsCreated: Bool { true }

    var supportedBlockchains: Set<Blockchain> { SupportedBlockchains(version: .v2).blockchains() }

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
        CardEmailDataFactory().makeEmailData(for: hotWalletInfo)
    }

    var userWalletIdSeed: Data? {
        hotWalletInfo.keys.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .hotWallet
    }

    var cardHeaderImage: ImageType? {
        #warning("Add asset")
        return nil
    }

    var cardSessionFilter: SessionFilter { .cardId("") }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            if hotWalletInfo.isAccessCodeSet {
                return .disabled()
            }

            return .available
        case .passcode: return .hidden
        case .longTap: return .hidden
        case .send: return .available
        case .longHashes: return .available
        case .signedHashesCounter: return .hidden
        case .backup: return .available
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
            if hotWalletInfo.hasICloudBackup {
                return .disabled()
            }

            return .available
        case .mnemonicBackup:
            if hotWalletInfo.hasMnemonicBackup {
                return .disabled()
            }

            return .available
        }
    }

    func makeBackupService() -> BackupService {
        fatalError("Unimplemented")
    }

    func makeTangemSdk() -> TangemSdk {
        fatalError("Unimplemented")
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> any WalletModelsFactory {
        CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> any AnyWalletManagerFactory {
        GenericWalletManagerFactory()
    }

    func makeMainHeaderProviderFactory() -> any MainHeaderProviderFactory {
        CommonMainHeaderProviderFactory()
    }

    func makeOnboardingStepsBuilder(backupService: BackupService) -> any OnboardingStepsBuilder {
        #warning("Add asset")
        fatalError("Unimplemented")
    }
}
