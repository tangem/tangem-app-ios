//
//  CardSubstitutionInfoOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

import GBAsyncOperation

public class CardSubstitutionInfoOperation: GBAsyncOperation {
    
    let card: Card
    let completion: (Card) -> Void 
    
    let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    
    public init(card: Card, completion: @escaping (Card) -> Void) {
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
       
        if let hashesPath = Bundle(for: Card.self).path(forResource: "hashes", ofType: "plist"),
            let hashes = NSDictionary(contentsOfFile: hashesPath) as? [String : String],
            let appArtworkHash = hashes[card.imageName],
            appArtworkHash == result.artwork?.hash {
            completeOperation()
        } else {
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
