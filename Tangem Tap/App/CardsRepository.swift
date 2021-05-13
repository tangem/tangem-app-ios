//
//  CardsRepository.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CardInfo {
    var card: Card
    var artworkInfo: ArtworkInfo?
	var twinCardInfo: TwinCardInfo?
}

enum ScanResult: Equatable {
    case card(model: CardViewModel)
    case unsupported
	case notScannedYet
    
    var cardModel: CardViewModel? {
        switch self {
        case .card(let model):
            return model
        default:
            return nil
        }
    }
    
    var card: Card? {
        switch self {
        case .card(let model):
            return model.cardInfo.card
        default:
            return nil
        }
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
		switch (lhs, rhs) {
		
		case (.card, .card): return true
		case (.unsupported, .unsupported): return true
		case (.notScannedYet, .notScannedYet): return true
		default:
			return false
		}
    }
}

protocol CardsRepositoryDelegate: AnyObject {
    func onWillScan()
    func onDidScan(_ cardInfo: CardInfo)
}

class CardsRepository {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    weak var validatedCardsService: ValidatedCardsService!
    weak var scannedCardsRepository: ScannedCardsRepository!
    
    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
    
    weak var delegate: CardsRepositoryDelegate? = nil
	
    deinit {
        print("CardsRepository deinit")
    }
    
    func scan(_ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        delegate?.onWillScan()
        tangemSdk.startSession(with: TapScanTask(validatedCardsService: validatedCardsService)) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
				guard response.card.cardId != nil else {
					completion(.failure(TangemSdkError.unknownError))
					return
				}
				
				Analytics.logScan(card: response.card)
                self.scannedCardsRepository.add(response.card)
				completion(.success(processScan(response.getCardInfo())))
            }
        }
    }

	private func processScan(_ cardInfo: CardInfo) -> ScanResult {
        delegate?.onDidScan(cardInfo)
        
        let cm = assembly.makeCardModel(from: cardInfo)
        let result: ScanResult = .card(model: cm)
        cards[cardInfo.card.cardId!] = result
        lastScanResult = result
        cm.getCardInfo()
        return result
	}
}

extension CardsRepository: SignerDelegate {
    func onSign(_ signResponse: SignResponse) {
        if let cm = cards[signResponse.cardId] {
            cm.cardModel?.onSign(signResponse)
        }
    }
}
