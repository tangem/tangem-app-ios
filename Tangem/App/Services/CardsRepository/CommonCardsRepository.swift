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
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding
    @Injected(\.scannedCardsRepository) private var scannedCardsRepository: ScannedCardsRepository
    @Injected(\.assemblyProvider) private var assemblyProvider: AssemblyProviding
    
    var lastScanResult: ScanResult = .notScannedYet
    var didScanPublisher: PassthroughSubject<CardInfo, Never> = .init()
    
    private(set) var cards = [String: ScanResult]()
    
    private var bag: Set<AnyCancellable> = .init()
    private let legacyCardMigrator: LegacyCardMigrator = .init()
    
    deinit {
        print("CardsRepository deinit")
    }
    
    func scan(with batch: String? = nil, _ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        sdkProvider.prepareScan()
        sdkProvider.sdk.startSession(with: AppScanTask(targetBatch: batch)) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
                Analytics.logScan(card: response.card)
                completion(.success(processScan(response.getCardInfo())))
            }
        }
    }
    
    func scanPublisher(with batch: String? = nil) ->  AnyPublisher<ScanResult, Error>  {
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
    
    private func processScan(_ cardInfo: CardInfo) -> ScanResult {
        let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
        interaction.donate(completion: nil)
        
        legacyCardMigrator.migrateIfNeeded(for: cardInfo)
        scannedCardsRepository.add(cardInfo)
        sdkProvider.didScan(cardInfo.card)
        didScanPublisher.send(cardInfo)
        
        let cm = assemblyProvider.assembly.makeCardModel(from: cardInfo)
        let result: ScanResult = .card(model: cm)
        cards[cardInfo.card.cardId] = result
        lastScanResult = result
        cm.getCardInfo()
        return result
    }
}


/// Temporary solution to migrate default tokens of old miltiwallet cards to TokenItemsRepository. Remove at Q3-Q4'22
fileprivate class LegacyCardMigrator {
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository
    @Injected(\.scannedCardsRepository) private var scannedCardsRepository: ScannedCardsRepository
    
    private var userPrefsService: UserPrefsService = .init()
    
    //Save default blockchain and token to main tokens repo.
    func migrateIfNeeded(for cardInfo: CardInfo) {
        let cardId = cardInfo.card.cardId
      
        //Migrate only multiwallet cards
        guard cardInfo.isMultiWallet else {
            return
        }
        
        //Check if we have anything to migrate. It's impossible to get default token without default blockchain
        guard let defaultBlockchain = cardInfo.defaultBlockchain else {
            return
        }
        
        //Migrate only known cards.
        guard scannedCardsRepository.cards.keys.contains(cardId) else {
            // Newly scanned card. Save and forgot.
            userPrefsService.migratedCardsWithDefaultTokens.append(cardId)
            return
        }
        
        //Migrate only once.
        guard !userPrefsService.migratedCardsWithDefaultTokens.contains(cardId) else {
            return
        }

        let derivationPath = defaultBlockchain.derivationPath(for: .legacy)
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: derivationPath)
        let tokens = cardInfo.defaultToken.map { [$0] } ?? []
        let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
        var entries = tokenItemsRepository.getItems(for: cardId)
        entries.insert(entry, at: 0)
        
        //We need to preserve order of token items
        tokenItemsRepository.removeAll(for: cardId)
        tokenItemsRepository.append(entries, for: cardId)
        
        userPrefsService.migratedCardsWithDefaultTokens.append(cardId)
    }
}
