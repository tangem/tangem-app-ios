//
//  TwinConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct TwinConfig: CardContainer {
    let card: CardDTO
    private let walletData: WalletData
    private let twinData: TwinData

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    init(card: CardDTO, walletData: WalletData, twinData: TwinData) {
        self.card = card
        self.walletData = walletData
        self.twinData = twinData
    }
}

extension TwinConfig: UserWalletConfig {
    var cardSetLabel: String? {
        Localization.cardLabelCardCount(cardsCount)
    }

    var cardsCount: Int {
        2
    }

    var cardName: String {
        "Twin"
    }

    var mandatoryCurves: [EllipticCurve] {
        [.secp256k1]
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
        return defaultBlockchains
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner {
        guard let walletPublicKey = card.wallets.first?.publicKey,
              let pairWalletPublicKey = twinData.pairPublicKey else {
            return .init(with: card.cardId, sdk: makeTangemSdk())
        }

        let twinKey = TwinKey(key1: walletPublicKey, key2: pairWalletPublicKey)
        return .init(with: twinKey, sdk: makeTangemSdk())
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        TwinCardsUtils.makeCombinedWalletKey(for: card, pairData: twinData)
    }

    var productType: Analytics.ProductType {
        .twin
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
        case .send:
            return .available
        case .longHashes:
            return .hidden
        case .signedHashesCounter:
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
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return .hidden
        case .onlineImage:
            return .available
        case .staking:
            return .available
        case .topup:
            return .available
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
        case .seedPhrase:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        }
    }

    func makeWalletModelsFactory() throws -> WalletModelsFactory {
        guard let savedPairKey = twinData.pairPublicKey else {
            throw CommonError.noData
        }

        return TwinsWalletModelFactory(pairPublicKey: savedPairKey)
    }

    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
        return TwinOnboardingStepsBulder(card: card, twinData: twinData, touId: tou.id)
    }

    func makeTangemSdk() -> TangemSdk {
        TwinTangemSdkFactory(isAccessCodeSet: card.isAccessCodeSet).makeTangemSdk()
    }
}
