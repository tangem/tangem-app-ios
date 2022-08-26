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

        cardInfo.primaryCard.map { backupServiceProvider.backupService.setPrimaryCard($0) }

        let cm = CardViewModel(cardInfo: cardInfo)
        cm.getLegacyMigrator()?.migrateIfNeeded()
        tangemApiService.setAuthData(cardInfo.card.tangemApiAuthData)
        walletConnectServiceProvider.initialize(with: cm)
        cm.didScan()
        cards[cardInfo.card.cardId] = cm
        return cm
    }
}


/// Temporary solution to migrate default tokens of old miltiwallet cards to TokenItemsRepository. Remove at Q3-Q4'22
class LegacyCardMigrator {
    private let cardId: String
    private let embeddedEntry: StorageEntry
    private let tokenItemsRepository: TokenItemsRepository

    init(cardId: String, embeddedEntry: StorageEntry) {
        self.cardId = cardId
        self.embeddedEntry = embeddedEntry

        tokenItemsRepository = CommonTokenItemsRepository(key: cardId)
    }

    // Save default blockchain and token to main tokens repo.
    func migrateIfNeeded() {
        // Migrate only once.
        guard !AppSettings.shared.migratedCardsWithDefaultTokens.contains(cardId) else {
            return
        }

        var entries = tokenItemsRepository.getItems()
        entries.insert(embeddedEntry, at: 0)

        // We need to preserve order of token items
        tokenItemsRepository.removeAll()
        tokenItemsRepository.append(entries)

        AppSettings.shared.migratedCardsWithDefaultTokens.append(cardId)
    }
}
