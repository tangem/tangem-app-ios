//
//  CardsRepository.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.Card
import struct TangemSdk.WalletData
import struct TangemSdk.ArtworkInfo
import class TangemSdk.TangemSdk
#if !CLIP
import BlockchainSdk
#endif

import Intents

struct CardInfo {
    var card: Card
    var walletData: WalletData?
    var artwork: CardArtwork = .notLoaded
    var artworkInfo: ArtworkInfo?
    var twinCardInfo: TwinCardInfo?
    
    var imageLoadDTO: ImageLoadDTO {
        ImageLoadDTO(cardId: card.cardId,
                     cardPublicKey: card.cardPublicKey,
                     artwotkInfo: artworkInfo)
    }
    
    var isTestnet: Bool {
        if card.batchId == "99FF" { //[REDACTED_TODO_COMMENT]
            return card.cardId.starts(with: card.batchId.reversed())
        }
        
        return defaultBlockchain?.isTestnet ?? false
    }
    
    var defaultBlockchain: Blockchain? {
        guard let walletData = walletData, let curve = card.supportedCurves.first else { return nil }
        
        return Blockchain.from(blockchainName: walletData.blockchain, curve: curve)
    }
    
    var defaultToken: Token? {
        guard let token = walletData?.token, let blockchain = defaultBlockchain else { return nil }
        
        return Token(name: token.name,
                     symbol: token.symbol,
                     contractAddress: token.contractAddress,
                     decimalCount: token.decimals,
                     blockchain: blockchain)
    }
}

enum CardArtwork {
    case notLoaded, noArtwork, artwork(ArtworkInfo)
}

struct ImageLoadDTO: Equatable {
    let cardId: String
    let cardPublicKey: Data
    let artwotkInfo: ArtworkInfo?
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
    weak var scannedCardsRepository: ScannedCardsRepository!
    
    var cards = [String: ScanResult]()
	var lastScanResult: ScanResult = .notScannedYet
    
    weak var delegate: CardsRepositoryDelegate? = nil
	
    deinit {
        print("CardsRepository deinit")
    }
    
    func scan(with batch: String? = nil, _ completion: @escaping (Result<ScanResult, Error>) -> Void) {
        Analytics.log(event: .readyToScan)
        delegate?.onWillScan()
        tangemSdk.startSession(with: TapScanTask(targetBatch: batch)) {[unowned self] result in
            switch result {
            case .failure(let error):
                Analytics.logCardSdkError(error, for: .scan)
                completion(.failure(error))
            case .success(let response):
				Analytics.logScan(card: response.card)
                #if !CLIP
                let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
                interaction.donate(completion: nil)
                self.scannedCardsRepository.add(response.card)
                #endif
				completion(.success(processScan(response.getCardInfo())))
            }
        }
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
        #if !CLIP
        if let cm = cards[card.cardId] {
            cm.cardModel?.onSign(card)
        }
        #endif
    }
}
