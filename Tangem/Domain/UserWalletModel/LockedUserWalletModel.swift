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
import TangemMobileWalletSdk
import TangemPay
import struct TangemSdk.SignData
import struct TangemSdk.DerivationPath

final class LockedUserWalletModel: UserWalletModel {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    var userTokensManager: UserTokensManager { _userTokensManager }
    private let _userTokensManager = LockedUserTokensManager()
    let nftManager: NFTManager = NotSupportedNFTManager()
    let walletImageProvider: WalletImageProviding
    var config: UserWalletConfig

    var isUserWalletLocked: Bool { true }

    var tokensCount: Int? { nil }

    var cardSetLabel: String { config.cardSetLabel }

    var hasBackupCards: Bool { userWallet.walletInfo.hasBackupCards }

    var hasImportedWallets: Bool { false }

    var emailConfig: EmailConfig? { nil }

    var signer: TangemSigner {
        DummyTangemSigner(config: config)
    }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<UpdateResult, Never> { _updatePublisher.eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        if let tangemPayCustomerId = tangemPayManager.customerId {
            data.append(EmailCollectedData(type: .tangemPayCustomerId, data: tangemPayCustomerId))
        }
        data.append(EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue))

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

    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
        CommonWalletConnectAccountsWalletModelProvider(accountModelsManager: accountModelsManager)
    }

    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager {
        CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: _userTokensManager,
            derivationManager: nil
        )
    }

    var accountModelsManager: AccountModelsManager {
        DummyCommonAccountModelsManager()
    }

    var tangemPayManager: TangemPayManager {
        TangemPayBuilder(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            signer: signer
        )
        .buildTangemPayManager()
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

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> { .empty }
    var tangemPayAccount: TangemPayAccount? { nil }

    var keysDerivingInteractor: KeysDeriving {
        DummyKeysDeriving(config: config)
    }

    var tangemPayAuthorizingInteractor: TangemPayAuthorizing {
        DummyTangemPayAuthorizer()
    }

    var name: String { userWallet.name }
    let backupInput: OnboardingInput? = nil
    var userWallet: StoredUserWallet

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

    func update(type: UpdateRequest) {
        switch type {
        case .backupCompleted(let card, let associatedCardIds):
            if case .mobileWallet = userWallet.walletInfo {
                syncRemoteAfterUpgrade()
            }

            let cardInfo = CardInfo(
                card: CardDTO(card: card),
                walletData: .none,
                associatedCardIds: associatedCardIds
            )

            var mutableCardInfo = cardInfo
            mutableCardInfo.card.wallets = []
            userWallet.walletInfo = .cardWallet(mutableCardInfo)
            config = UserWalletConfigFactory().makeConfig(walletInfo: userWallet.walletInfo)
            userWalletRepository.savePublicData()
            updatePrivateDataAfterIncompletedBackup(cardInfo: cardInfo)
        case .newName:
            break
        case .accessCodeDidSet:
            break
        case .accessCodeDidSkip:
            break
        case .iCloudBackupCompleted:
            break
        case .mnemonicBackupCompleted:
            break
        }
    }

    func addAssociatedCard(cardId: String) {}

    func updatePrivateDataAfterIncompletedBackup(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        guard let encryptionKey = UserWalletEncryptionKey(config: config) else {
            return
        }

        let dataStorage = UserWalletDataStorage()

        guard let existingInfo = dataStorage.fetchPrivateData(encryptionKeys: [userWalletId: encryptionKey])[userWalletId] else {
            return
        }

        var mutableCardInfo = cardInfo

        switch existingInfo {
        case .cardWallet(let keys):
            for wallet in mutableCardInfo.card.wallets {
                if let existingDerivedKeys = keys[wallet.publicKey]?.derivedKeys {
                    mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                }
            }
        case .mobileWallet(let keys):
            for wallet in mutableCardInfo.card.wallets {
                if let existingDerivedKeys = keys[wallet.publicKey]?.derivedKeys {
                    mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                }
            }
        }

        dataStorage.savePrivateData(
            sensitiveInfo: .cardWallet(keys: mutableCardInfo.card.wallets),
            userWalletId: userWalletId,
            encryptionKey: encryptionKey
        )

        cleanMobileWallet()
    }

    private func syncRemoteAfterUpgrade() {
        runTask(in: self) { model in
            let walletCreationHelper = WalletCreationHelper(
                userWalletId: model.userWalletId,
                userWalletName: model.name,
                userWalletConfig: model.config
            )

            try? await walletCreationHelper.updateWallet()
        }
    }
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

        return AnalyticsContextData(
            productType: config.productType,
            batchId: cardInfo.card.batchId,
            firmware: cardInfo.card.firmwareVersion.stringValue,
            baseCurrency: config.embeddedBlockchain?.currencySymbol,
            userWalletId: userWalletId
        )
    }
}

extension LockedUserWalletModel: UserWalletSerializable {
    func serializePublic() -> StoredUserWallet {
        return userWallet
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo {
        // Replacing this with some dummy data may lead to overwrite real data on the disk, therefore do not return anything here.
        // Locked wallets should not be serialized, so this function should not be called, calling this method is a programmer error.
        preconditionFailure("'\(#function)' should not be called for locked wallets")
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

// MARK: - DisposableEntity protocol conformance

extension LockedUserWalletModel: DisposableEntity {
    func dispose() {
        walletModelsManager.dispose()
        accountModelsManager.dispose()
    }
}

private extension LockedUserWalletModel {
    func cleanMobileWallet() {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [userWalletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet after upgrade:", error: error)
        }
    }
}

// MARK: - Dummy stubs

private extension LockedUserWalletModel {
    struct DummyTangemSigner: TangemSigner {
        let hasNFCInteraction: Bool
        let latestSignerType: TangemSignerType?

        init(config: UserWalletConfig) {
            let signer = config.tangemSigner
            hasNFCInteraction = signer.hasNFCInteraction
            latestSignerType = signer.latestSignerType
        }

        func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
            stub()
        }

        func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
            stub()
        }

        func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
            stub()
        }

        private func stub<T>(for function: StaticString = #function) -> AnyPublisher<T, Error> {
            .anyFail(error: "Locked wallet does not support signing using '\(function)'")
        }
    }

    final class DummyKeysDeriving: KeysDeriving {
        let requiresCard: Bool

        init(config: UserWalletConfig) {
            requiresCard = config.tangemSigner.hasNFCInteraction
        }

        func deriveKeys(
            derivations: [Data: [DerivationPath]],
            completion: @escaping (Result<DerivationResult, Error>) -> Void
        ) {
            completion(.failure("Locked wallet does not support keys deriving using '\(#function)'"))
        }
    }

    final class DummyTangemPayAuthorizer: TangemPayAuthorizing {
        var syncNeededTitle: String { .empty }

        func authorize(
            customerWalletId: String,
            authorizationService: TangemPay.TangemPayAuthorizationService
        ) async throws -> TangemPayAuthorizingResponse {
            throw "Locked wallet does not support Tangem Pay authorization using '\(#function)'"
        }
    }
}
