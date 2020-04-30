//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import RxSwift
import SwiftyJSON

class CardanoNetworkService {
    private var adaliteUrl: AdaliteUrl = .url1
    private let provider = MoyaProvider<AdaliteTarget>()
    
    @available(iOS 13.0, *)
    func send(base64EncodedTx: String) -> AnyPublisher<String, Error> {
        return provider
            .requestPublisher(.send(base64EncodedTx: base64EncodedTx, url: adaliteUrl))
            .mapNotEmptyString()
            .eraseError()
    }
    
    func getInfo(address: String) -> Single<(AdaliteBalanceResponse,[AdaliteUnspentOutput])> {
        return getUnspents(address: address)
            .flatMap { unspentsResponse -> Single<(AdaliteBalanceResponse,[AdaliteUnspentOutput])> in
                return self.getBalance(address: address)
                    .map { balanceResponse -> (AdaliteBalanceResponse,[AdaliteUnspentOutput]) in
                        return (balanceResponse, unspentsResponse)
                }
        }
        .catchError { error throws in
            if case MoyaError.statusCode(let response) = error {
                if self.adaliteUrl == .url1 {
                    self.adaliteUrl = .url2
                }
            }
            throw error
        }
        .retry(2)
    }
    
    private func getUnspents(address: String) -> Single<[AdaliteUnspentOutput]> {
        return provider
            .rx
            .request(.unspents(address: address, url: adaliteUrl))
            .mapSwiftyJSON()
            .map { json throws -> [AdaliteUnspentOutput] in
                let unspentOutputsJson = json["Right"].arrayValue
                let unspentOutputs = unspentOutputsJson.map{ json -> AdaliteUnspentOutput in
                    let output = AdaliteUnspentOutput(id: json["cuId"].stringValue, index: json["cuOutIndex"].intValue)
                    return output
                }
                return unspentOutputs
        }
    }
    
    private func getBalance(address: String) -> Single<AdaliteBalanceResponse> {
        return provider
            .rx
            .request(.address(address: address, url: adaliteUrl))
            .mapSwiftyJSON()
            .map {json throws -> AdaliteBalanceResponse in                
                guard let balanceString = json["Right"]["caBalance"]["getCoin"].string,
                    let balance = Decimal(balanceString) else {
                        throw json["Left"].stringValue
                }
                
                let convertedValue = balance/Decimal(1000000)
                
                var transactionList = [String]()
                if let transactionListJSON = json["Right"]["caTxList"].array {
                    transactionList = transactionListJSON.map({ return $0["ctbId"].stringValue })
                }
                
                let response = AdaliteBalanceResponse(balance: convertedValue, transactionList: transactionList)
                return response
        }
    }
}
