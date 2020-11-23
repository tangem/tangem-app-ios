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
	let twinCardInfo: TwinCardInfo?
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

    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
	
	private let twinCardFileDecoder: TwinCardFileDecoder
	
	init(twinCardFileDecoder: TwinCardFileDecoder) {
		self.twinCardFileDecoder = twinCardFileDecoder
	}
    
    func scan(_ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
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
                
                let cardInfo = CardInfo(card: response.card,
                                        verificationState: response.verifyResponse.verificationState,
										artworkInfo: response.verifyResponse.artworkInfo,
										twinCardInfo: self.decodeTwinFile(from: response))
                
               
                let cm = self.assembly.makeCardModel(from: cardInfo)
                let res: ScanResult = cm == nil ? .unsupported : .card(model: cm!)
                self.cards[cardInfo.card.cardId!] = res
				self.lastScanResult = res
                completion(.success(res))
            }
        }
    }
	
	private func decodeTwinFile(from response: TapScanTaskResponse) -> TwinCardInfo? {
		guard
			let cardId = response.card.cardId,
			let pairCid = TwinCardsUtils.makePairCid(for: cardId),
			let twinSeries = TwinCardSeries.series(for: response.card.cardId)
			else { return nil }
		
		var pairPublicKey: Data?
		for file in response.files {
			do {
				let twinFile = try twinCardFileDecoder.decode(file)
				pairPublicKey = twinFile.publicKey
				break
			} catch {
				print("File doesn't contain twin card dara")
			}
		}
		return TwinCardInfo(cid: cardId, series: twinSeries, pairCid: pairCid, pairPublicKey: pairPublicKey)
	}
	
}
