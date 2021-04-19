//
//  RosettaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import SwiftCBOR

class RosettaNetworkProvider: CardanoNetworkProvider {
    
    private let provider: MoyaProvider<RosettaTarget> = .init()
    private let baseUrl: RosettaUrl
    
    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
    
    init(baseUrl: RosettaUrl) {
        self.baseUrl = baseUrl
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        AnyPublisher<RosettaBalanceResponse, Error>.multiAddressPublisher(addresses: addresses, requestFactory: { address in
            self.provider
                .requestPublisher(.address(baseUrl: self.baseUrl, addressBody: RosettaAddressBody(networkIdentifier: .mainNet, accountIdentifier: RosettaAccountIdentifier(address: address))))
                .mapNotEmptyString()
                .tryMap { [unowned self] (response: String) -> RosettaBalanceResponse in
                    guard let data = response.data(using: .utf8) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    var balanceResponse = try self.decoder.decode(RosettaBalanceResponse.self, from: data)
                    balanceResponse.address = address
                    return balanceResponse
                }
                .eraseToAnyPublisher()
        })
        .map { (addressesResponses: [RosettaBalanceResponse]) -> CardanoAddressResponse in
            let cardanoCurrencySymbol = "ADA"
            var balance = Decimal(0)
            var unspentOutputs = [CardanoUnspentOutput]()
            
            addressesResponses.forEach { response in
                response.coins.forEach { coin in
                    if coin.amount?.currency?.symbol == cardanoCurrencySymbol,
                       let splittedIdentifier = coin.coinIdentifier?.identifier?.split(separator: ":"),
                       splittedIdentifier.count == 2,
                       let index = Int(splittedIdentifier[1]) {
                        unspentOutputs.append(CardanoUnspentOutput(address: response.address ?? "",
                                                                   amount: coin.amount?.valueDecimal ?? 0,
                                                                   outputIndex: index,
                                                                   transactionHash: String(splittedIdentifier[0])))
                    }
                }
                response.balances.forEach { b in
                    if b.currency?.symbol == cardanoCurrencySymbol {
                        balance += b.valueDecimal ?? 0
                    }
                }
            }
            
            balance = balance / Blockchain.cardano(shelley: false).decimalValue
            
            return CardanoAddressResponse(balance: balance,
                                          recentTransactionsHashes: [],
                                          unspentOutputs: unspentOutputs)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        let txHex: String = CBOR.array(
            [CBOR.utf8String(transaction.toHexString())]
        ).encode().toHexString()
        return provider.requestPublisher(.submitTransaction(baseUrl: self.baseUrl,
                                                            submitBody: RosettaSubmitBody(networkIdentifier: .mainNet,
                                                                                          signedTransaction: txHex)))
            .mapNotEmptyString()
            .tryMap { [unowned self] (resp: String) -> String in
                print(resp)
                guard let data = resp.data(using: .utf8) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                let submitResponse = try self.decoder.decode(RosettaSubmitResponse.self, from: data)
                return submitResponse.transactionIdentifier.hash ?? ""
            }
            .eraseToAnyPublisher()
    }
}
