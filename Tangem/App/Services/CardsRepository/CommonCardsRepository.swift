//
//  CardsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import enum TangemSdk.EllipticCurve
import struct TangemSdk.Card
import struct TangemSdk.ExtendedPublicKey
import struct TangemSdk.WalletData
import struct TangemSdk.ArtworkInfo
import struct TangemSdk.PrimaryCard
import struct TangemSdk.DerivationPath
import class TangemSdk.TangemSdk
import enum TangemSdk.TangemSdkError

import Intents

class CommonCardsRepository: CardsRepository {
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    @Injected(\.saletPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding
    @Injected(\.supportChatService) private var supportChatService: SupportChatServiceProtocol

    weak var delegate: CardsRepositoryDelegate? = nil

    private(set) var models = [CardViewModel]()

    private var bag: Set<AnyCancellable> = .init()

    deinit {
        print("CardsRepository deinit")
    }

    func scan(with batch: String? = nil, requestBiometrics: Bool,  _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        Analytics.reset()
        Analytics.log(.readyToScan)

        var config = TangemSdkConfigFactory().makeDefaultConfig()
        if requestBiometrics {
            config.accessCodeRequestPolicy = .alwaysWithBiometrics
        }
        sdkProvider.setup(with: config)

        sdkProvider.sdk.startSession(with: AppScanTask(targetBatch: batch)) { [unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
                self.acceptTOSIfNeeded(response.getCardInfo(), completion)
            }
        }
    }

    func scanPublisher(with batch: String? = nil, requestBiometrics: Bool = false) -> AnyPublisher<CardViewModel, Error>  {
        Deferred {
            Future { [weak self] promise in
                self?.scan(with: batch, requestBiometrics: requestBiometrics) { result in
                    switch result {
                    case .success(let scanResult):
                        promise(.success(scanResult))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func add(_ cardModel: CardViewModel) {
        add([cardModel])
    }

    func add(_ cardModels: [CardViewModel]) {
        models.append(contentsOf: cardModels)
    }

    func removeModel(withUserWalletId userWalletId: Data) {
        models.removeAll {
            $0.userWalletId == userWalletId
        }
    }

    func clear() {
        models = []
    }

    func didSwitchToModel(_ cardModel: CardViewModel) {
        let cardInfo = cardModel.cardInfo
        startInitializingServices(for: cardInfo)
        finishInitializingServices(for: cardModel, cardInfo: cardInfo)
    }

    private func acceptTOSIfNeeded(_ cardInfo: CardInfo, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        let touURL = UserWalletConfigFactory(cardInfo).makeConfig().touURL

        guard let delegate, !AppSettings.shared.termsOfServicesAccepted.contains(touURL.absoluteString) else {
            completion(.success(processScan(cardInfo)))
            return
        }

        delegate.showTOS(at: touURL) { accepted in
            if accepted {
                AppSettings.shared.termsOfServicesAccepted.insert(touURL.absoluteString)
                completion(.success(self.processScan(cardInfo)))
            } else {
                completion(.failure(TangemSdkError.userCancelled))
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func startInitializingServices(for cardInfo: CardInfo) {
        let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
        interaction.donate(completion: nil)

        saltPayRegistratorProvider.reset()
        if let primaryCard = cardInfo.primaryCard {
            backupServiceProvider.backupService.setPrimaryCard(primaryCard)
        }
    }

    private func finishInitializingServices(for cardModel: CardViewModel, cardInfo: CardInfo) {
        tangemApiService.setAuthData(cardInfo.card.tangemApiAuthData)
        supportChatService.initialize(with: cardModel.supportChatEnvironment)
        walletConnectServiceProvider.initialize(with: cardModel)

        if SaltPayUtil().isPrimaryCard(batchId: cardInfo.card.batchId),
           let wallet = cardInfo.card.wallets.first {
            try? saltPayRegistratorProvider.initialize(cardId: cardInfo.card.cardId,
                                                       walletPublicKey: wallet.publicKey,
                                                       cardPublicKey: cardInfo.card.cardPublicKey)
        }
    }

    private func processScan(_ cardInfo: CardInfo) -> CardViewModel {
        startInitializingServices(for: cardInfo)

        // [REDACTED_TODO_COMMENT]
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        let cardModel = CardViewModel(cardInfo: cardInfo, config: config)

        finishInitializingServices(for: cardModel, cardInfo: cardInfo)

        cardModel.didScan()
        if cardInfo.card.hasWallets && !models.contains(where: { $0.userWalletId == cardInfo.card.userWalletId }) {
            models.append(cardModel)
        }
        return cardModel
    }
}
