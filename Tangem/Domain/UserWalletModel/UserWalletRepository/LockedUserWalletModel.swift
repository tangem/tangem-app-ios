//
//  LockedUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemSdk
import TangemNFT
import BlockchainSdk

class LockedUserWalletModel: UserWalletModel {
    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokensManager: UserTokensManager = LockedUserTokensManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    let nftManager: NFTManager = NotSupportedNFTManager()
    let walletImageProvider: WalletImageProviding
    let config: UserWalletConfig
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var hasBackupCards: Bool { userWallet.cardInfo?.card.backupStatus?.isActive ?? false }

    var hasImportedWallets: Bool { false }

    var emailConfig: EmailConfig? { nil }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<Void, Never> { .just }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        if case .card(let card) = userWallet.walletInfo {
            return .init(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
        } else {
            // unimplemented
            return .init(cardId: "", cardPublicKey: Data())
        }
    }

    var totalBalance: TotalBalanceState {
        .loading(cached: .none)
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: totalBalance)
    }

    var analyticsContextData: AnalyticsContextData {
        AnalyticsContextData(
            card: userWallet.cardInfo?.card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager { CommonUserTokensPushNotificationsManager(
        userWalletId: userWalletId,
        walletModelsManager: walletModelsManager,
        derivationManager: nil,
        userTokenListManager: userTokenListManager
    )
    }

    var refcodeProvider: RefcodeProvider? {
        return nil
    }

    var totalSignedHashes: Int {
        0
    }

    var keysRepository: KeysRepository { CommonKeysRepository(with: []) }
    var keysDerivingInteractor: any KeysDeriving {
        if let cardInfo = userWallet.cardInfo {
            return KeysDerivingCardInteractor(with: cardInfo)
        } else {
            fatalError("Unimplemented")
        }
    }

    var name: String { userWallet.name }

    let backupInput: OnboardingInput? = nil

    private let userWallet: StoredUserWallet

    init(with userWallet: StoredUserWallet) {
        self.userWallet = userWallet

        let walletInfo = userWallet.info

        config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)
        signer = TangemSigner(filter: .cardId(""), sdk: .init(), twinKey: nil)
        walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: walletInfo)
    }

    func updateWalletName(_ name: String) {
        // Renaming locked wallets is prohibited
    }

    func validate() -> Bool {
        // Nothing to validate for locked wallets
        return true
    }

    func onBackupUpdate(type: BackupUpdateType) {}

    func addAssociatedCard(_ cardId: String) {}
}

extension LockedUserWalletModel: MainHeaderSupplementInfoProvider {
    var isUserWalletLocked: Bool { true }

    var userWalletNamePublisher: AnyPublisher<String, Never> {
        .just(output: userWallet.name)
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }

    var isTokensListEmpty: Bool { false }
}

extension LockedUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        guard let cardInfo = userWallet.cardInfo else {
            return nil
        }

        let embeddedEntry = config.embeddedBlockchain
        let baseCurrency = embeddedEntry?.tokens.first?.symbol ?? embeddedEntry?.blockchainNetwork.blockchain.currencySymbol

        return AnalyticsContextData(
            productType: config.productType,
            batchId: cardInfo.card.batchId,
            firmware: cardInfo.card.firmwareVersion.stringValue,
            baseCurrency: baseCurrency,
            userWalletId: userWalletId
        )
    }
}

extension LockedUserWalletModel: UserWalletSerializable {
    func serialize() -> StoredUserWallet {
        userWallet
    }
}
