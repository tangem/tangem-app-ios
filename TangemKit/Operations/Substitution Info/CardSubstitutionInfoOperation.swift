//
//  CardSubstitutionInfoOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

import GBAsyncOperation

public class CardSubstitutionInfoOperation: GBAsyncOperation {
    
    let card: CardViewModel
    let completion: (CardViewModel) -> Void 
    
    let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    
    public init(card: CardViewModel, completion: @escaping (CardViewModel) -> Void) {
        self.card = card
        self.completion = completion
    }
    
    override public func main() {
        fetchSubstitutionInfo()
    }
    
    // MARK: Fetch operations
    
    func fetchSubstitutionInfo() {
        let operation = CardDetailsNetworkOperation(card: card) { (result) in
            switch result {
            case .success(let substitutionInfo):
                self.handleSubstitutionInfoLoaded(substitutionInfo: substitutionInfo)
            case .failure(let error):
                print(error)
                self.completeOperation()
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleSubstitutionInfoLoaded(substitutionInfo: CardDetailsNetworkOperationResponse) {
        guard let result = substitutionInfo.results.first else {
            completeOperation()
            return
        }
        
        card.substituteDataFrom(result)
       
        if let hashesPath = Bundle(for: CardViewModel.self).path(forResource: "hashes", ofType: "plist"),
            let hashes = NSDictionary(contentsOfFile: hashesPath) as? [String : String],
            let appArtworkHash = hashes[card.imageName],
            appArtworkHash == (result.artwork?.hash ?? appArtworkHash) {
            completeOperation()
        } else {
            let cardId = result.cardId.lowercased()
            if cardId.starts(with: "bc") {
                let id =  "card_\(cardId[cardId.startIndex...cardId.index(cardId.startIndex, offsetBy: 3)])"
                fetchArtwork(artworkId: id)
                return
            }
            
            guard let artworkId = result.artwork?.artworkId else {
                completeOperation()
                return
            }
            
            fetchArtwork(artworkId: artworkId)
        }
    }
    
    func fetchArtwork(artworkId: String) {
        let operation = CardArtworkNetworkOperation(card: card, artworkId: artworkId) { (result) in
            switch result {
            case .success(let image):
                self.card.substitutionImage = image
                self.completeOperation()
            case .failure(let error):
                print(error)
                self.completeOperation()
            }
        }
        operationQueue.addOperation(operation)
    }
    
    // MARK: Operation completion
    
    func completeOperation() {
        guard !isCancelled else {
            return
        }
        
        completion(card)
        finish()
    }
    
}
