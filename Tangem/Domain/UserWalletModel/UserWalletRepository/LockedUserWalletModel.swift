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

class LockedUserWalletModel: UserWalletModel {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    let userTokensManager: UserTokensManager = LockedUserTokensManager()
    let userTokenListManager: UserTokenListManager = LockedUserTokenListManager()
    let nftManager: NFTManager = NotSupportedNFTManager()
    let walletImageProvider: WalletImageProviding
    let config: UserWalletConfig
    var signer: TangemSigner

    var tokensCount: Int? { nil }

    var cardsCount: Int { config.cardsCount }

    var hasBackupCards: Bool {
        userWallet.walletInfo.hasBackupCards
    }

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

    private let userWallet: StoredUserWallet

    init(with userWallet: StoredUserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory().makeConfig(walletInfo: userWallet.walletInfo)
        signer = TangemSigner(filter: .cardId(""), sdk: .init(), twinKey: nil)
        walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: userWallet.walletInfo)
    }

    func updateWalletName(_ name: String) {
        // Renaming locked wallets is prohibited
    }

    func validate() -> Bool {
        // Nothing to validate for locked wallets
        return true
    }

    func onBackupUpdate(type: BackupUpdateType) {}

    func addAssociatedCard(cardId: String) {}

    func cleanup() {
        switch userWallet.walletInfo {
        case .cardWallet(let cardInfo):
            try? visaRefreshTokenRepository.deleteToken(cardId: cardInfo.card.cardId)

            if AppSettings.shared.saveAccessCodes {
                do {
                    let accessCodeRepository = AccessCodeRepository()
                    try accessCodeRepository.deleteAccessCode(for: Array(cardInfo.associatedCardIds))
                } catch {
                    Analytics.error(error: error)
                    AppLogger.error(error: error)
                }
            }
        case .mobileWallet(let mobileWalletInfo):
            return
        }
    }
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
