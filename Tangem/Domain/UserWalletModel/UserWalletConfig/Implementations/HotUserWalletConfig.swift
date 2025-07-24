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
    let hotWallet: HotWallet

    var transactionSigner: TransactionSigner {
        fatalError("Unimplemented")
    }
}

extension HotUserWalletConfig: UserWalletConfig {
    var cardsCount: Int { 0 }

    var cardSetLabel: String? { nil }

    var defaultName: String { "Hot Wallet" }

    var existingCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var createWalletCurves: [EllipticCurve] {
        existingCurves
    }

    var tangemSigner: TangemSigner {
        fatalError("Unimplemented")
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        GeneralNotificationEventsFactory().makeNotifications(for: hotWallet)
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
        CardEmailDataFactory().makeEmailData(for: hotWallet)
    }

    var userWalletIdSeed: Data? {
        hotWallet.wallets.first?.publicKey
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
        case .accessCode: .hidden
        case .passcode: .hidden
        case .longTap: .hidden
        case .send: .available
        case .longHashes: .available
        case .signedHashesCounter: .hidden
        case .backup: .hidden
        case .twinning: .hidden
        case .exchange: .available
        case .walletConnect: .available
        case .multiCurrency: .available
        case .resetToFactory: .hidden
        case .receive: .available
        case .withdrawal: .available
        case .hdWallets: .available
        case .staking: .available
        case .topup: .available
        case .tokenSynchronization: .available
        case .referralProgram: .hidden
        case .swapping: .available
        case .displayHashesCount: .available
        case .transactionHistory: .hidden
        case .accessCodeRecoverySettings: .hidden
        case .promotion: .available
        case .nft: .available
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

    func makeOnboardingStepsBuilder(backupService: BackupService, isPushNotificationsAvailable: Bool) -> any OnboardingStepsBuilder {
        #warning("Add asset")
        fatalError("Unimplemented")
    }
}
