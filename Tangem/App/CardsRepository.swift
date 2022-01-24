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
#if !CLIP
import BlockchainSdk
#endif

import Intents

struct CardInfo {
    var card: Card
    var walletData: WalletData?
    var artwork: CardArtwork = .notLoaded
    var twinCardInfo: TwinCardInfo?
    var isTangemNote: Bool
    var isTangemWallet: Bool
    var derivedKeys: [Data:[DerivationPath:ExtendedPublicKey]] = [:]
    var primaryCard: PrimaryCard? = nil
    
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
        guard let walletData = walletData else { return nil }
        
        guard let curve = isTangemNote ? EllipticCurve.secp256k1 : card.supportedCurves.first else {
            return nil
        }
        
        let blockchainName = isTangemNote ? (walletData.blockchain.lowercased() == "binance" ? "bsc": walletData.blockchain)
            : walletData.blockchain
        
        return Blockchain.from(blockchainName: blockchainName, curve: curve)
    }
    
    var defaultToken: Token? {
        guard let token = walletData?.token, let blockchain = defaultBlockchain else { return nil }
        
        return Token(name: token.name,
                     symbol: token.symbol,
                     contractAddress: token.contractAddress,
                     decimalCount: token.decimals,
                     blockchain: blockchain)
    }
    
    var artworkInfo: ArtworkInfo? {
        switch artwork {
        case .notLoaded, .noArtwork: return nil
        case .artwork(let artwork): return artwork
        }
    }
    
    var isMultiWallet: Bool {
        if isTangemNote {
            return false
        }
        
        if card.isTwinCard {
            return false
        }
        
        if card.isStart2Coin {
            return false
        }
        
        if card.firmwareVersion.major < 4,
           !card.supportedCurves.contains(.secp256k1) {
            return false
        }
        
        return true
    }
}

enum CardArtwork: Equatable {
    static func == (lhs: CardArtwork, rhs: CardArtwork) -> Bool {
        switch (lhs, rhs) {
        case (.notLoaded, .notLoaded), (.noArtwork, .noArtwork): return true
        case (.artwork(let lhsArt), .artwork(let rhsArt)): return lhsArt == rhsArt
        default: return false
        }
    }
    
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
                #if !CLIP
                let interaction = INInteraction(intent: ScanTangemCardIntent(), response: nil)
                interaction.donate(completion: nil)
                self.scannedCardsRepository.add(response.getCardInfo())
                #endif
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
        #if !CLIP
        if let cm = cards[card.cardId] {
            cm.cardModel?.onSign(card)
        }
        #endif
    }
}
