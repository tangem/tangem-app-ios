//
//  VisaConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemSdk
import BlockchainSdk
import TangemVisa
import TangemFoundation

struct VisaConfig: CardContainer {
    let card: CardDTO
    let activationLocalState: VisaCardActivationLocalState

    init(card: CardDTO, activationLocalState: VisaCardActivationLocalState) {
        self.card = card
        self.activationLocalState = activationLocalState
    }

    private var defaultBlockchain: Blockchain {
        VisaUtilities.visaBlockchain
    }
}

extension VisaConfig: UserWalletConfig {
    var emailConfig: EmailConfig? {
        .visaDefault()
    }

    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var defaultName: String {
        "Tangem Visa"
    }

    var createWalletCurves: [EllipticCurve] {
        [defaultBlockchain.curve]
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [StorageEntry] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = StorageEntry(blockchainNetwork: network, tokens: [])
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        defaultBlockchains
    }

    var embeddedBlockchain: StorageEntry? {
        defaultBlockchains.first
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        GeneralNotificationEventsFactory().makeNotifications(for: card)
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .visa
    }

    var cardHeaderImage: ImageType? {
        Assets.Cards.visa
    }

    var hasDefaultToken: Bool {
        // Visa wallet must be recognized as single wallet cards, therefore they shouldn't have a default token
        false
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .available
        case .passcode:
            return .hidden
        case .longTap:
            return .hidden
        case .send:
            return .hidden
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .resetToFactory:
            return .hidden
        case .receive:
            return .available
        case .withdrawal:
            return .hidden
        case .hdWallets:
            return .hidden
        case .staking:
            return .hidden
        case .topup:
            return .hidden
        case .tokenSynchronization:
            return .hidden
        case .referralProgram:
            return .hidden
        case .swapping:
            return .hidden
        case .displayHashesCount:
            return .hidden
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .promotion:
            return .hidden
        case .nft:
            return .hidden
        case .iCloudBackup:
            return .hidden
        case .mnemonicBackup:
            return .hidden
        case .userWalletAccessCode:
            return .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return VisaWalletManagerFactory()
    }
}

extension VisaConfig: VisaCardOnboardingStepsBuilderFactory {
    func makeOnboardingStepsBuilder(
        backupService: BackupService
    ) -> OnboardingStepsBuilder {
        return VisaOnboardingStepsBuilder(
            cardId: card.cardId,
            isAccessCodeSet: card.isAccessCodeSet,
            activationLocalState: activationLocalState
        )
    }
}
