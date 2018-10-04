//
//  CoinMarketOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum CoinMarketError: Error {
    case noNetworkInfo
    case requestFailure(String?)
}

enum CoinMarketNetwork: String {
    case btc = "bitcoin"
    case eth = "ethereum"
}

class CoinMarketOperation: AsynchronousOperation {
    
    static let coinMarket = "https://api.coinmarketcap.com/v1/ticker/?convert=USD&lmit=10"
    
    let network: CoinMarketNetwork
    let completion: (Result<Double>) -> Void
    
    init(network: CoinMarketNetwork, completion: @escaping (Result<Double>) -> Void) {
        self.network = network
        self.completion = completion
    }
    
    override func main() {
        Alamofire.request(CoinMarketOperation.coinMarket, method:.get).responseJSON { [weak self] response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                guard let item = json.arrayValue.first(where: {
                    return $0["id"].stringValue == self?.network.rawValue
                }) else {
                    self?.failOperationWith(error: CoinMarketError.noNetworkInfo)
                    return
                }
                
                let priceUSD = item["price_usd"].doubleValue
                self?.completeOperationWith(price: priceUSD)
                
            case .failure(let error):
                self?.failOperationWith(error: CoinMarketError.requestFailure(error.localizedDescription))
            }
        }
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
