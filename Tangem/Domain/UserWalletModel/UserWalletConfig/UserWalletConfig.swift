//
//  UserWalletConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemSdk
import BlockchainSdk

protocol UserWalletConfig: OnboardingStepsBuilderFactory {
    var emailConfig: EmailConfig? { get }

    var cardsCount: Int { get }

    var cardSetLabel: String? { get }

    var defaultName: String { get }

    /// Actual state of current card's curves or main card's curves in case of biometrics
    var existingCurves: [EllipticCurve] { get }

    /// Curves to create during card initialization
    var createWalletCurves: [EllipticCurve] { get }

    var derivationStyle: DerivationStyle? { get }

    var generalNotificationEvents: [GeneralNotificationEvent] { get }

    var canSkipBackup: Bool { get }

    var canImportKeys: Bool { get }

    var isWalletsCreated: Bool { get }
    /// All blockchains supported by this user wallet.
    var supportedBlockchains: Set<Blockchain> { get }

    /// Blockchains to be added to the tokens list by default on wallet creation.
    var defaultBlockchains: [StorageEntry] { get }

    /// Blockchains to be added to the tokens list on every scan. E.g. demo blockchains.
    var persistentBlockchains: [StorageEntry]? { get }

    /// Blockchain which embedded in the card.
    var embeddedBlockchain: StorageEntry? { get }

    var emailData: [EmailCollectedData] { get }

    var userWalletIdSeed: Data? { get }

    var productType: Analytics.ProductType { get }

    var cardHeaderImage: ImageType? { get }

    var cardSessionFilter: SessionFilter { get }

    var hasDefaultToken: Bool { get }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory

    func makeMainHeaderProviderFactory() -> MainHeaderProviderFactory
}

extension UserWalletConfig {
    func hasFeature(_ feature: UserWalletFeature) -> Bool {
        getFeatureAvailability(feature).isAvailable
    }

    func isFeatureVisible(_ feature: UserWalletFeature) -> Bool {
        !getFeatureAvailability(feature).isHidden
    }

    func getDisabledLocalizedReason(for feature: UserWalletFeature) -> String? {
        getFeatureAvailability(feature).disabledLocalizedReason
    }

    var emailConfig: EmailConfig? {
        .default
    }

    var canSkipBackup: Bool {
        true
    }

    var canImportKeys: Bool {
        false
    }

    var derivationStyle: DerivationStyle? {
        return nil
    }

    var hasDefaultToken: Bool {
        (defaultBlockchains.first?.tokens.count ?? 0) > 0
    }
}

struct TOU {
    let id: String
    let url: URL
}

protocol CardContainer {
    var card: CardDTO { get }
}

extension UserWalletConfig where Self: CardContainer {
    var existingCurves: [EllipticCurve] {
        card.walletCurves
    }

    var isWalletsCreated: Bool {
        !card.wallets.isEmpty
    }

    var cardSessionFilter: SessionFilter {
        let shouldSkipCardId = card.backupStatus?.isActive ?? false

        if shouldSkipCardId, let userWalletIdSeed {
            let userWalletId = UserWalletId(with: userWalletIdSeed)
            let filter = UserWalletIdPreflightReadFilter(userWalletId: userWalletId)
            return .custom(filter)
        }

        return .cardId(card.cardId)
    }

    func makeMainHeaderProviderFactory() -> MainHeaderProviderFactory {
        return CommonMainHeaderProviderFactory()
    }
}

extension UserWalletConfig where Self: CardContainer, Self: BackupServiceFactory {
    func makeBackupService() -> BackupService {
        let factory = GenericBackupServiceFactory(isAccessCodeSet: card.isAccessCodeSet)
        return factory.makeBackupService()
    }
}

extension UserWalletConfig where Self: CardContainer, Self: TangemSdkFactory {
    var tangemSigner: TangemSigner {
        .init(filter: cardSessionFilter, sdk: makeTangemSdk(), twinKey: nil)
    }

    func makeTangemSdk() -> TangemSdk {
        let factory = GenericTangemSdkFactory(isAccessCodeSet: card.isAccessCodeSet)
        return factory.makeTangemSdk()
    }
}

typealias CardUserWalletConfig = UserWalletConfig & BackupServiceFactory & TangemSdkFactory & CardContainer
