//
//  TezosNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class TezosNetworkService {
    private let provider = MoyaProvider<TezosTarget>(
//        plugins: [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(formatter: NetworkLoggerPlugin.Configuration.Formatter(),
//                                                                                                                                    output: NetworkLoggerPlugin.Configuration.defaultOutput,
//                                                                                                                                    logOptions: .verbose))]
    )
    private var api: TezosTarget.TezosApi = .tezos
    
    func getInfo(address: String) -> AnyPublisher<TezosAddress, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                return self.provider
                    .requestPublisher(TezosTarget(api: self.api, endpoint: .addressData(address: address)))
                    .filterSuccessfulStatusCodes()
                    .map(TezosAddressResponse.self)
                    .eraseToAnyPublisher()
        }
        .tryCatch {[unowned self] in self.switchApi($0) }
        .retry(1)
        .tryMap { tezosAddress -> TezosAddress in
            guard let balanceString = tezosAddress.balance,
                let balance = Decimal(string: balanceString),
                let counterString = tezosAddress.counter,
                let counter = Int(counterString) else {
                    throw WalletError.failedToParseNetworkResponse
            }
            
            let balanceConverted = balance / Blockchain.tezos(curve: .ed25519).decimalValue
            return TezosAddress(balance: balanceConverted, counter: counter)
        }
        .eraseToAnyPublisher()
    }
    
    func checkPublicKeyRevealed(address: String) -> AnyPublisher<Bool, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] in
                return self.provider
                    .requestPublisher(TezosTarget(api: self.api, endpoint: .managerKey(address: address)))
                    .filterSuccessfulStatusCodes()
                    .mapString()
                    .cleanString()
                    .map { $0 == "null" ? false : true }
                    .tryCatch { error -> AnyPublisher<Bool, Error> in
                        if case MoyaError.stringMapping(_) = error {
                            return Just(false)
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                        }
                        throw error
                }
                .eraseToAnyPublisher()
        }
        .tryCatch {[unowned self] in self.switchApi($0) }
        .retry(1)
        .eraseToAnyPublisher()
    }
    
    func getHeader() -> AnyPublisher<TezosHeader, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                return self.provider
                    .requestPublisher(TezosTarget(api: self.api, endpoint: .getHeader))
                    .filterSuccessfulStatusCodes()
                    .map(TezosHeaderResponse.self)
                    .eraseToAnyPublisher()
        }
        .tryCatch {[unowned self] in self.switchApi($0) }
        .retry(1)
        .tryMap {headerResponse -> TezosHeader in
            guard let proto = headerResponse.protocol, let hash = headerResponse.hash else {
                throw WalletError.failedToParseNetworkResponse
            }
            
            return TezosHeader(protocol: proto, hash: hash)
        }
        .eraseToAnyPublisher()
    }
    
    func forgeContents(headerHash: String, contents: [TezosOperationContent]) -> AnyPublisher<String, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                return self.provider
                    .requestPublisher(TezosTarget(api: self.api,
                                                  endpoint: .forgeOperations(body: TezosForgeBody(branch: headerHash,
                                                                                                  contents: contents))))
                    .filterSuccessfulStatusCodes()
                    .mapString()
                    .cleanString()
                    .eraseToAnyPublisher()
        }
        .tryCatch {[unowned self] in self.switchApi($0) }
        .retry(1)
        .eraseToAnyPublisher()
    }
    
    private func switchApi<T>(_ error: Error) -> AnyPublisher<T, Error> {
        api = api == .tezos ? .tezosReserve : .tezos
        return Fail(error: error).eraseToAnyPublisher()
    }
    
    private func encodeSignature(_ signature: Data) -> String {
        let edsigPrefix = Data(hex: "09F5CD8612")
        let prefixedSignature = edsigPrefix + signature
        let checksum = prefixedSignature.sha256().sha256().prefix(4)
        let prefixedSignatureWithChecksum = prefixedSignature + checksum
//        let b58 =  String(base58: prefixedSignatureWithChecksum, alphabet: Base58String.btcAlphabet)
//        let b581 = Base58.encode(prefixedSignatureWithChecksum)
//        if b58 == b581 {
//            print("equals")
//        }
        return Base58.base58FromBytes(prefixedSignatureWithChecksum.bytes)
    }
}
