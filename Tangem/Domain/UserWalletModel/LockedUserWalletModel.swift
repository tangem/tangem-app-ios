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
import TangemVisa
import TangemFoundation

class LockedUserWalletModel: UserWalletModel {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokensManager: UserTokensManager = LockedUserTokensManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    let nftManager: NFTManager = NotSupportedNFTManager()
    let walletImageProvider: WalletImageProviding
    let config: UserWalletConfig

    var isUserWalletLocked: Bool { true }

    var isTokensListEmpty: Bool { false }

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var hasBackupCards: Bool {
        userWallet.walletInfo.hasBackupCards
    }

    var hasImportedWallets: Bool { false }

    var emailConfig: EmailConfig? { nil }

    var signer: TangemSigner {
        fatalError("Should not be called for locked wallets")
    }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<UpdateResult, Never> { _updatePublisher.eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        userWallet.walletInfo.tangemApiAuthData
    }

    var totalBalance: TotalBalanceState {
        .loading(cached: .none)
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: totalBalance)
    }

    var analyticsContextData: AnalyticsContextData {
        userWallet.walletInfo.analyticsContextData
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

    var keysRepository: KeysRepository {
        CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: .init(userWalletIdSeed: Data()),
            keys: .cardWallet(keys: [])
        )
    }

    var keysDerivingInteractor: any KeysDeriving {
        fatalError("Should not be called for locked wallets")
    }

    var name: String { userWallet.name }
    let backupInput: OnboardingInput? = nil
    let userWallet: StoredUserWallet

    private let _updatePublisher: PassthroughSubject<UpdateResult, Never> = .init()

    init(with userWallet: StoredUserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory().makeConfig(walletInfo: userWallet.walletInfo)
        walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: userWallet.walletInfo)
    }

    func validate() -> Bool {
        // Nothing to validate for locked wallets
        return true
    }

    func update(type: UpdateRequest) {}

    func addAssociatedCard(cardId: String) {}
}

extension LockedUserWalletModel: MainHeaderSupplementInfoProvider {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }
}

extension LockedUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        guard case .cardWallet(let cardInfo) = userWallet.walletInfo else {
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
    func serializePublic() -> StoredUserWallet {
        return userWallet
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo {
        fatalError("Should not be called for locked wallets")
    }
}

extension LockedUserWalletModel: AssociatedCardIdsProvider {
    var associatedCardIds: Set<String> {
        switch userWallet.walletInfo {
        case .cardWallet(let cardInfo):
            return cardInfo.associatedCardIds
        case .mobileWallet:
            return []
        }
    }
}
