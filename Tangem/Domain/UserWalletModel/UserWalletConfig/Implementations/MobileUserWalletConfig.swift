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

    var defaultName: String { "Wallet" }

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

    var defaultBlockchains: [TokenItem] {
        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

        let entries: [TokenItem] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return TokenItem.blockchain(network)
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return TokenItem.blockchain(network)
        }

        return entries
    }

    var persistentBlockchains: [TokenItem] { [] }

    var embeddedBlockchain: TokenItem? { nil }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: mobileWalletInfo)
    }

    var userWalletIdSeed: Data? {
        mobileWalletInfo.keys.first?.publicKey
    }

    var userWalletAccessCodeStatus: UserWalletAccessCodeStatus {
        mobileWalletInfo.accessCodeStatus
    }

    var productType: Analytics.ProductType {
        .mobileWallet
    }

    var cardHeaderImage: ImageType? {
        return nil
    }

    var cardSessionFilter: SessionFilter { .cardId("") }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "mobile"]
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode: return .hidden
        case .passcode: return .hidden
        case .longTap: return .hidden
        case .signing: return .available
        case .longHashes: return .available
        case .backup: return .hidden
        case .twinning: return .hidden
        case .exchange: return .available
        case .walletConnect: return .available
        case .multiCurrency: return .available
        case .resetToFactory: return .hidden
        case .hdWallets: return .available
        case .staking: return .available
        case .referralProgram: return .available
        case .swapping: return .available
        case .displayHashesCount: return .available
        case .transactionHistory: return .hidden
        case .accessCodeRecoverySettings: return .hidden
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
            return .available
        case .userWalletBackup:
            return .available
        case .isBalanceRestrictionActive:
            return .available
        case .userWalletUpgrade:
            return .available
        case .cardSettings:
            return .hidden
        case .nfcInteraction:
            return .hidden
        case .transactionPayloadLimit:
            return .hidden
        case .tangemPay:
            if userWalletAccessCodeStatus == .set {
                return .available
            }
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
