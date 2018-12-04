//
//  CardArtworkNetworkOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import GBAsyncOperation
import Alamofire
import TangemKit

class CardArtworkNetworkOperation: GBAsyncOperation {

    let artworkId: String
    let card: Card
    let completion: (Result<UIImage>) -> Void

    init(card: Card, artworkId: String, completion: @escaping (Result<UIImage>) -> Void) {
        self.card = card
        self.artworkId = artworkId
        self.completion = completion
    }

    override func main() {
        let url = "https://verify.tangem.com/card/verify-and-get-info"

        let parameters = ["CID"        : card.cardID.replacingOccurrences(of: " ", with: ""),
                          "publicKey"  : card.cardPublicKey,
                          "artworkId"  : artworkId]

        Alamofire.request(url, parameters: parameters, encoding: URLEncoding.default).responseData { (response) in
            switch response.result {
            case .success(let value):
                guard let image = UIImage(data: value) else {
                    self.failOperationWith(error: "Invalid image data")
                    return
                }

                self.completeOperationWith(image: image)
            case.failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
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
