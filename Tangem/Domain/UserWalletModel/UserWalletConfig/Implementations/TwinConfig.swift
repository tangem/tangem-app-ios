//
//  TwinConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemSdk
import BlockchainSdk
import TangemAssets
import TangemFoundation

struct TwinConfig: CardContainer {
    let card: CardDTO
    private let walletData: WalletData
    private let twinData: TwinData

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var twinKey: TwinKey? {
        if let walletPublicKey = card.wallets.first?.publicKey,
           let pairWalletPublicKey = twinData.pairPublicKey {
            return TwinKey(key1: walletPublicKey, key2: pairWalletPublicKey)
        }

        return nil
    }

    init(card: CardDTO, walletData: WalletData, twinData: TwinData) {
        self.card = card
        self.walletData = walletData
        self.twinData = twinData
    }
}

extension TwinConfig: UserWalletConfig {
    var cardsCount: Int {
        2
    }

    var defaultName: String {
        "Twin"
    }

    var createWalletCurves: [EllipticCurve] {
        [.secp256k1]
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [TokenItem] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = TokenItem.blockchain(network)
        return [entry]
    }

    var persistentBlockchains: [TokenItem] {
        return defaultBlockchains
    }

    var embeddedBlockchain: TokenItem? {
        return defaultBlockchains.first
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        GeneralNotificationEventsFactory().makeNotifications(for: card)
    }

    var tangemSigner: TangemSigner {
        if let twinKey {
            return CardSigner(filter: cardSessionFilter, sdk: makeTangemSdk(), twinKey: twinKey)
        }

        return CardSigner(filter: cardSessionFilter, sdk: makeTangemSdk(), twinKey: nil)
    }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        if let firstWalletPiblicKey = card.wallets.first?.publicKey,
           let pairWalletPiblicKey = twinData.pairPublicKey {
            return TwinCardsUtils.makeCombinedWalletKey(for: firstWalletPiblicKey, pairPublicKey: pairWalletPiblicKey)
        }

        return nil
    }

    var productType: Analytics.ProductType {
        .twin
    }

    var cardHeaderImage: ImageType? {
        Assets.Cards.twins
    }

    var cardSessionFilter: SessionFilter {
        if let twinKey {
            let filter = TwinPreflightReadFilter(twinKey: twinKey)
            return .custom(filter)
        }

        return .cardId(card.cardId)
    }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "card"]
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .hidden
        case .passcode:
            if twinData.pairPublicKey != nil {
                return .available
            }

            return .disabled()
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .signing:
            return .available
        case .longHashes:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .available
        case .exchange:
            return .available
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .resetToFactory:
            return .available
        case .hdWallets:
            return .hidden
        case .staking:
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
        case .nft:
            return .hidden
        case .iCloudBackup:
            return .hidden
        case .mnemonicBackup:
            return .hidden
        case .userWalletAccessCode:
            return .hidden
        case .userWalletBackup:
            return .hidden
        case .isBalanceRestrictionActive:
            return .hidden
        case .userWalletUpgrade:
            return .hidden
        case .cardSettings:
            return .available
        case .nfcInteraction:
            return .available
        case .transactionPayloadLimit:
            return .available
        case .tangemPay:
            return .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        guard let savedPairKey = twinData.pairPublicKey else {
            throw CommonError.noData
        }

        return TwinWalletManagerFactory(pairPublicKey: savedPairKey)
    }

    func makeOnboardingStepsBuilder(
        backupService: BackupService
    ) -> OnboardingStepsBuilder {
        return TwinOnboardingStepsBuilder(
            cardId: card.cardId,
            hasWallets: !card.wallets.isEmpty,
            twinData: twinData
        )
    }

    func makeTangemSdk() -> TangemSdk {
        TwinTangemSdkFactory(isAccessCodeSet: card.isAccessCodeSet).makeTangemSdk()
    }
}
