//
//  CardDetailsNetworkOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import TangemKit
import Alamofire
import GBAsyncOperation

struct CardDetailsNetworkOperationResponse: Codable {

    var results: [CardNetworkDetails]

    enum CodingKeys: String, CodingKey {
        case results
    }

}

class CardDetailsNetworkOperation: GBAsyncOperation {

    let card: Card
    let completion: (Result<CardDetailsNetworkOperationResponse>) -> Void

    init(card: Card, completion: @escaping (Result<CardDetailsNetworkOperationResponse>) -> Void) {
        self.card = card
        self.completion = completion
    }

    override func main() {
        let url = "https://verify.tangem.com/card/verify-and-get-info"

        let request = ["CID"        : card.cardID.replacingOccurrences(of: " ", with: ""),
                       "publicKey"  : card.cardPublicKey]

        let parameters = ["requests" : [request]]

        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseData(completionHandler: { (response) in
            switch response.result {
            case .success(let value):
                let decoder = JSONDecoder()
                let results = try! decoder.decode(CardDetailsNetworkOperationResponse.self, from: value)
                self.completeOperationWith(results: results)
            case.failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        })
    }

    func completeOperationWith(results: CardDetailsNetworkOperationResponse) {
        guard !isCancelled else {
            return
        }

        completion(.success(results))
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
