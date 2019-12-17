//
//  StellarSdk+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine
import SwiftyJSON

extension AccountService {
    func getAccountDetails(accountId: String) -> AnyPublisher<AccountResponse, Error> {
        let future = Future<AccountResponse, Error> {[weak self] promise in
            self?.getAccountDetails(accountId: accountId) {response -> Void in
                switch response {
                case .success(let accountResponse):
                    promise(.success(accountResponse))
                case .failure(let error):
                    promise(.failure(error.parseError()))
                }
            }
        }
        
        return AnyPublisher(future)
    }
}


extension LedgersService {
    func getLatestLedger() -> AnyPublisher<LedgerResponse, Error> {
        let future = Future<LedgerResponse, Error> {[weak self] promise in
            self?.getLedgers(cursor: nil, order: Order.descending, limit: 1) { response -> Void in
                switch response {
                case .success(let ledgerResponse):
                    if let lastLedger = ledgerResponse.records.first {
                        promise(.success(lastLedger))
                    } else {
                        promise(.failure("Couldn't find latest ledger"))
                    }
                case .failure(let error):
                    promise(.failure(error.parseError()))
                }
            }
        }
        
        return AnyPublisher(future)
    }
}

extension TransactionsService {
    func postTransaction(transactionEnvelope:String) -> AnyPublisher<SubmitTransactionResponse, Error> {
        let future = Future<SubmitTransactionResponse, Error> { [weak self] promise in
            self?.postTransaction(transactionEnvelope: transactionEnvelope, response: { response -> (Void) in
                switch response {
                case .success(let submitResponse):
                    promise(.success(submitResponse))
                case .failure(let error):
                    promise(.failure(error.parseError()))
                }
            })
        }
        
        return AnyPublisher(future)
    }
}

extension HorizonRequestError {
    var message: String {
        switch self {
        case .emptyResponse:
            return "emptyResponse"
        case .beforeHistory(let message, _):
            return message
        case .badRequest(let message, _):
            return message
        case .errorOnStreamReceive(let message):
            return message
        case .forbidden(let message, _):
            return message
        case .internalServerError(let message, _):
            return message
        case .notAcceptable(let message, _):
            return message
        case .notFound(let message, _):
            return message
        case .notImplemented(let message, _):
            return message
        case .parsingResponseFailed(let message):
            return message
        case .rateLimitExceeded(let message, _):
            return message
        case .requestFailed(let message):
            return message
        case .staleHistory(let message, _):
            return message
        case .unauthorized(let message):
            return message
        }
    }
    
    func parseError() -> String {
        let hotizonMessage = message
        let json = JSON(parseJSON: hotizonMessage)
        let detailMessage = json["detail"].stringValue
        let extras = json["extras"]
        let codes = extras["result_codes"].rawString() ?? ""
        let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : hotizonMessage
        return errorMessage
    }
}
