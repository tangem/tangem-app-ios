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
    var verificationState: VerifyCardState?
    var artworkInfo: ArtworkInfo?
	var twinCardInfo: TwinCardInfo?
}

enum ScanResult: Equatable {
    case card(model: CardViewModel)
    case unsupported
	case notScannedYet
    
    var wallet: Wallet? {
        switch self {
        case .card(let model):
            return model.state.wallet
        default:
            return nil
        }
    }
    
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

class CardsRepository {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    weak var featuresService: AppFeaturesService!
    
    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
	
	private let twinCardFileDecoder: TwinCardFileDecoder
    private let warningsConfigurator: WarningsConfigurator
	
    init(twinCardFileDecoder: TwinCardFileDecoder, warningsConfigurator: WarningsConfigurator) {
		self.twinCardFileDecoder = twinCardFileDecoder
        self.warningsConfigurator = warningsConfigurator
	}
    
    func scan(_ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        tangemSdk.config = Config()
        tangemSdk.startSession(with: TapScanTask()) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.log(error: error)
                completion(.failure(error))
            case .success(let response):
				guard response.card.cardId != nil else {
					completion(.failure(TangemSdkError.unknownError))
					return
				}
				
				Analytics.logScan(card: response.card)
				completion(.success(processScan(response.getCardInfo())))
            }
        }
    }

	private func processScan(_ cardInfo: CardInfo) -> ScanResult {
        self.featuresService.setupFeatures(for: cardInfo.card)
        self.warningsConfigurator.setupWarnings(for: cardInfo.card)
	   
		if !self.featuresService.linkedTerminal {
			self.tangemSdk.config.linkedTerminal = false
		}
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayedNumbersCount = 4
        }
        
		let cm = self.assembly.makeCardModel(from: cardInfo)
		let res: ScanResult = cm == nil ? .unsupported : .card(model: cm!)
		self.cards[cardInfo.card.cardId!] = res
		self.lastScanResult = res
		return res
	}
}
