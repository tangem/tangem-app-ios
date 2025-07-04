//
//  KoinosTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct KoinosTarget: TargetType {
    let node: NodeInfo
    let type: KoinosTargetType

    var baseURL: URL {
        node.url
    }

    var path: String {
        switch type {
        case .getKoinContractID: "v1/contract/koin/abi"
        default: ""
        }
    }

    var method: Moya.Method {
        switch type {
        case .getKoinContractID: .get
        default: .post
        }
    }

    var task: Task {
        switch type {
        case .getKoinContractID:
            return .requestPlain

        case .getKoinBalance(let args, let koinContractID):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.ReadContract.RequestParams(
                    contractId: koinContractID,
                    entryPoint: KoinosNetworkParams.BalanceOf.entryPoint,
                    args: args
                ),
                encoder: JSONEncoder.withSnakeCaseStrategy
            )

        case .getRc(let address):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.GetAccountRC.RequestParams(account: address)
            )

        case .getNonce(let address):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.GetAccountNonce.RequestParams(account: address)
            )

        case .getResourceLimits:
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: nil
            )

        case .submitTransaction(let transaction):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.SubmitTransaction.RequestParams(transaction: transaction, broadcast: true)
            )

        case .getTransactions(let transactionIDs):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.GetTransactions.RequestParams(transactionIds: transactionIDs)
            )
        }
    }

    var headers: [String: String]?

    init(node: NodeInfo, _ type: KoinosTargetType) {
        self.node = node
        self.type = type
    }
}

extension KoinosTarget {
    enum KoinosTargetType {
        case getKoinContractID
        case getKoinBalance(args: String, koinContractId: String)
        case getRc(address: String)
        case getNonce(address: String)
        case getResourceLimits
        case submitTransaction(transaction: KoinosProtocol.Transaction)
        case getTransactions(transactionIDs: [String])

        var method: String {
            switch self {
            case .getKoinContractID:
                ""
            case .getKoinBalance:
                "chain.read_contract"
            case .getRc:
                "chain.get_account_rc"
            case .getNonce:
                "chain.get_account_nonce"
            case .getResourceLimits:
                "chain.get_resource_limits"
            case .submitTransaction:
                "chain.submit_transaction"
            case .getTransactions:
                "transaction_store.get_transactions_by_id"
            }
        }
    }
}

private extension KoinosTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}

extension KoinosTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        type.method
    }
}
