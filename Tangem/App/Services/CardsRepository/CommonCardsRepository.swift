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


    private(set) var cards = [String: CardViewModel]()

    private var bag: Set<AnyCancellable> = .init()

    deinit {
        print("CardsRepository deinit")
    }

    func scan(with batch: String? = nil, _ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        sdkProvider.setup(with: TangemSdkConfigFactory().makeDefaultConfig())
        sdkProvider.sdk.startSession(with: AppScanTask(targetBatch: batch)) { [unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
                completion(.success(processScan(response.getCardInfo())))
            }
        }
    }

    func scanPublisher(with batch: String? = nil) -> AnyPublisher<CardViewModel, Error>  {
        Deferred {
            Future { [weak self] promise in
                self?.scan(with: batch) { result in
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

    private func processScan(_ cardInfo: CardInfo) -> CardViewModel {
        let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
        interaction.donate(completion: nil)
        saltPayRegistratorProvider.reset()
        cardInfo.primaryCard.map { backupServiceProvider.backupService.setPrimaryCard($0) }
        let cm = CardViewModel(cardInfo: cardInfo)
        tangemApiService.setAuthData(cardInfo.card.tangemApiAuthData)
        supportChatService.initialize(with: cm.supportChatEnvironment)
        walletConnectServiceProvider.initialize(with: cm)

        if SaltPayUtil().isPrimaryCard(batchId: cardInfo.card.batchId),
           let wallet = cardInfo.card.wallets.first {
            try? saltPayRegistratorProvider.initialize(cardId: cardInfo.card.cardId,
                                                       walletPublicKey: wallet.publicKey,
                                                       cardPublicKey: cardInfo.card.cardPublicKey)
        }

        cm.didScan()
        cards[cardInfo.card.cardId] = cm
        return cm
    }
}
