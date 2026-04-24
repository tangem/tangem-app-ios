//
//  KoinosNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine
import TangemNetworkUtils

class KoinosNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    let koinosNetworkParams: KoinosNetworkParams

    private let node: NodeInfo
    private let provider: TangemProvider<KoinosTarget>

    init(
        node: NodeInfo,
        koinosNetworkParams: KoinosNetworkParams,
        configuration: TangemProviderConfiguration
    ) {
        self.node = node
        provider = TangemProvider<KoinosTarget>(configuration: configuration)
        self.koinosNetworkParams = koinosNetworkParams
    }

    func getKoinBalance(address: String, koinContractId: String) -> AnyPublisher<KoinosMethod.ReadContract.Response, Error> {
        Result {
            try Koinos_Contracts_Token_balance_of_arguments.with {
                $0.owner = address.base58DecodedData
            }
            .serializedData()
            .base64URLEncodedString()
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { provider, args in
            provider.requestJSONRPCPublisher(
                for: .getKoinBalance(args: args, koinContractId: koinContractId)
            )
        }
        .eraseToAnyPublisher()
    }

    func getRC(address: String) -> AnyPublisher<KoinosMethod.GetAccountRC.Response, Error> {
        requestJSONRPCPublisher(
            for: .getRc(address: address)
        )
        .eraseToAnyPublisher()
    }

    func getResourceLimits() -> AnyPublisher<KoinosMethod.GetResourceLimits.Response, Error> {
        requestJSONRPCPublisher(
            for: .getResourceLimits
        )
        .eraseToAnyPublisher()
    }

    func getNonce(address: String) -> AnyPublisher<KoinosMethod.GetAccountNonce.Response, Error> {
        requestJSONRPCPublisher(
            for: .getNonce(address: address)
        )
        .eraseToAnyPublisher()
    }

    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosMethod.SubmitTransaction.Response, Error> {
        requestJSONRPCPublisher(
            for: .submitTransaction(transaction: transaction)
        )
        .eraseToAnyPublisher()
    }

    func getTransactions(transactionIDs: [String]) -> AnyPublisher<KoinosMethod.GetTransactions.Response, Error> {
        requestJSONRPCPublisher(
            for: .getTransactions(transactionIDs: transactionIDs)
        )
        .eraseToAnyPublisher()
    }

    func getKoinContractId() -> AnyPublisher<KoinosMethod.GetContractId.Response, Error> {
        requestPublisher(for: .getKoinContractID)
    }
}

private extension KoinosNetworkProvider {
    func requestPublisher<T: Decodable>(
        for target: KoinosTarget.KoinosTargetType
    ) -> AnyPublisher<T, Error> {
        provider.requestPublisher(KoinosTarget(node: node, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: .withSnakeCaseStrategy)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func requestJSONRPCPublisher<T: Decodable>(
        for target: KoinosTarget.KoinosTargetType
    ) -> AnyPublisher<T, Error> {
        let publisher: AnyPublisher<JSONRPC.Response<T, JSONRPC.APIError>, Error> = requestPublisher(for: target)
        return publisher
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
