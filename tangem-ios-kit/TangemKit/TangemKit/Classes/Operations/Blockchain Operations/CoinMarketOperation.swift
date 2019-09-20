//
//  CoinMarketOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

enum CoinMarketError: Error {
    case noNetworkInfo
    case responseDataError
    case requestFailure(String?)
}

public enum CoinMarketNetwork: String {
    case btc = "bitcoin"
    case eth = "ethereum"
}

public class CoinMarketOperation: GBAsyncOperation {

    static let coinMarket = "https://api.coinmarketcap.com/v1/ticker/?convert=USD&lmit=10"

    let network: CoinMarketNetwork
    let completion: (TangemObjectResult<Double>) -> Void

   public init(network: CoinMarketNetwork, completion: @escaping (TangemObjectResult<Double>) -> Void) {
        self.network = network
        self.completion = completion
    }

    override public func main() {
        let url = URL(string: CoinMarketOperation.coinMarket)
        let urlRequest = URLRequest(url: url!)
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    guard let item = try JSON(data: data).arrayValue.first(where: {
                        return $0["id"].stringValue == self.network.rawValue
                    }) else {
                        self.failOperationWith(error: CoinMarketError.noNetworkInfo)
                        return
                    }
                    
                    let priceUSD = item["price_usd"].doubleValue
                    self.completeOperationWith(price: priceUSD)
                } catch {
                    self.failOperationWith(error: CoinMarketError.responseDataError)
                }
            case .failure(let error):
                self.failOperationWith(error: CoinMarketError.requestFailure(error.localizedDescription))
            }
        }
        
        task.resume()
    }

    func completeOperationWith(price: Double) {
        guard !isCancelled else {
            return
        }

        completion(.success(price))
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
