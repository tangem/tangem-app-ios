//
//  AdaliteNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON

class AdaliteNetworkProvider: CardanoNetworkProvider {
    private let adaliteUrl: AdaliteUrl
    private let provider = MoyaProvider<AdaliteTarget>()
    
    init(baseUrl: AdaliteUrl) {
        adaliteUrl = baseUrl
    }
    
    @available(iOS 13.0, *)
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(.send(base64EncodedTx: transaction.base64EncodedString(), url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        getUnspents(addresses: addresses)
            .flatMap { unspents -> AnyPublisher<CardanoAddressResponse, Error> in
                self.getBalance(addresses: addresses)
                    .map { balanceResponse -> CardanoAddressResponse in
                        let balance = balanceResponse.reduce(Decimal(0), { $0 + $1.balance })
                        let txHashes = balanceResponse.reduce([String](), { $0 + $1.transactions })
                        return CardanoAddressResponse(balance: balance, recentTransactionsHashes: txHashes, unspentOutputs: unspents)
                    }
                    .eraseToAnyPublisher()
            }
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    private func getUnspents(addresses: [String]) -> AnyPublisher<[CardanoUnspentOutput], Error> {
        provider
            .requestPublisher(.unspents(addresses: addresses, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
            .tryMap { json throws -> [CardanoUnspentOutput] in
                let unspentOutputsJson = json["Right"].arrayValue
                let unspentOutputs = unspentOutputsJson.map{ json -> CardanoUnspentOutput in
                    let output = CardanoUnspentOutput(address: json["cuAddress"].stringValue,
                                                      amount: Decimal(json["cuCoins"]["getCoin"].doubleValue),
                                                      outputIndex: json["cuOutIndex"].intValue,
                                                      transactionHash: json["cuId"].stringValue)
                    return output
                }
                return unspentOutputs
            }
            .eraseToAnyPublisher()
    }
    
    private func getBalance(addresses: [String]) -> AnyPublisher<[AdaliteBalanceResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: { [weak self] in
            guard let self = self else { return .emptyFail }
            
            return self.provider
                .requestPublisher(.address(address: $0, url: self.adaliteUrl))
                .filterSuccessfulStatusAndRedirectCodes()
                .mapSwiftyJSON()
                .tryMap {json throws -> AdaliteBalanceResponse in
                    let addressData = json["Right"]
                    guard let balanceString = addressData["caBalance"]["getCoin"].string,
                          let balance = Decimal(balanceString) else {
                        throw json["Left"].stringValue
                    }
                    
                    let convertedValue = balance / Blockchain.cardano(shelley: false).decimalValue
                    
                    var transactionList = [String]()
                    if let transactionListJSON = addressData["caTxList"].array {
                        transactionList = transactionListJSON.map({ return $0["ctbId"].stringValue })
                    }
                    
                    let response = AdaliteBalanceResponse(balance: convertedValue, transactions: transactionList)
                    return response
                }
                .eraseToAnyPublisher()
        })
    }
}
