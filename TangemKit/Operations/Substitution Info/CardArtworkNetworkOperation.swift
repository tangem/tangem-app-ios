//
//  CardArtworkNetworkOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import GBAsyncOperation

class CardArtworkNetworkOperation: GBAsyncOperation {

    let artworkId: String
    let card: CardViewModel
    let completion: (TangemObjectResult<UIImage>) -> Void

    init(card: CardViewModel, artworkId: String, completion: @escaping (TangemObjectResult<UIImage>) -> Void) {
        self.card = card
        self.artworkId = artworkId
        self.completion = completion
    }

    override func main() {
        let url = "https://verify.tangem.com/card/artwork"

        let parameters = ["CID"        : card.cardID.replacingOccurrences(of: " ", with: ""),
                          "publicKey"  : card.cardPublicKey,
                          "artworkId"  : artworkId]
        
        var components = URLComponents(string: url)!
        components.queryItems = parameters.map { (key, value) in 
            URLQueryItem(name: key, value: value) 
        }
        
        let urlRequest = URLRequest(url: components.url!)
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    self.failOperationWith(error: "Invalid image data")
                    return
                }
                
                self.completeOperationWith(image: image)
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }

    func completeOperationWith(image: UIImage) {
        guard !isCancelled else {
            return
        }

        completion(.success(image))
        finish()
    }


    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }

        completion(.failure(error))
        finish()
    }

}
