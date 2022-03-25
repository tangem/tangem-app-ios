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

protocol CardsRepositoryDelegate: AnyObject {
    func onWillScan()
    func onDidScan(_ cardInfo: CardInfo)
}

class CardsRepository {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    weak var scannedCardsRepository: ScannedCardsRepository!
    weak var tokenItemsRepository: TokenItemsRepository!
    weak var userPrefsService: UserPrefsService!
    
    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
    
    weak var delegate: CardsRepositoryDelegate? = nil
	
    deinit {
        print("CardsRepository deinit")
    }
    
    func scan(with batch: String? = nil, _ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        delegate?.onWillScan()
        tangemSdk.startSession(with: AppScanTask(tokenItemsRepository: tokenItemsRepository,
                                                 userPrefsService: userPrefsService,
                                                 targetBatch: batch)) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
				Analytics.logScan(card: response.card)
                let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
                interaction.donate(completion: nil)
                self.scannedCardsRepository.add(response.getCardInfo())
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
        delegate?.onDidScan(cardInfo)
        
        let cm = assembly.makeCardModel(from: cardInfo)
        let result: ScanResult = .card(model: cm)
        cards[cardInfo.card.cardId] = result
        lastScanResult = result
        cm.getCardInfo()
        return result
	}
}

extension CardsRepository: SignerDelegate {
    func onSign(_ card: Card) {
        if let cm = cards[card.cardId] {
            cm.cardModel?.onSign(card)
        }
    }
}
