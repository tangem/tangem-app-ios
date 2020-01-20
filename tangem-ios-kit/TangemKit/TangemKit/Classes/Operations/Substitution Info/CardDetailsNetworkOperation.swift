//
//  CardDetailsNetworkOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import GBAsyncOperation

struct CardDetailsNetworkOperationResponse: Codable {

    var results: [CardNetworkDetails]

    enum CodingKeys: String, CodingKey {
        case results
    }

}

class CardDetailsNetworkOperation: GBAsyncOperation {

    let card: CardViewModel
    let completion: (TangemObjectResult<CardDetailsNetworkOperationResponse>) -> Void

    init(card: CardViewModel, completion: @escaping (TangemObjectResult<CardDetailsNetworkOperationResponse>) -> Void) {
        self.card = card
        self.completion = completion
    }

    override func main() {
        let urlString = "https://verify.tangem.com/card/verify-and-get-info"

        let request = ["CID"        : card.cardID.replacingOccurrences(of: " ", with: ""),
                       "publicKey"  : card.cardPublicKey]

        let parameters = ["requests" : [request]]
        
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.httpMethod = "POST"
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            self.failOperationWith(error: String(describing: error))
        }
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    let results = try JSONDecoder().decode(CardDetailsNetworkOperationResponse.self, from: data)
                    self.completeOperationWith(results: results)
                } catch {
                    self.failOperationWith(error: String(describing: error))
                }
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }

        task.resume()
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
