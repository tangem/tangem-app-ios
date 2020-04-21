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
import RxSwift
import SwiftyJSON

extension AccountService {
    func getAccountDetails(accountId: String) -> Observable<AccountResponse> {
        return Observable.create {[unowned self] observer -> Disposable in
            self.getAccountDetails(accountId: accountId) { response -> Void in
                switch response {
                case .success(let accountResponse):
                    observer.onNext(accountResponse)
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}



extension LedgersService {
    func getLatestLedger() -> Observable<LedgerResponse> {
        return Observable.create{[unowned self] observer in
            self.getLedgers(cursor: nil, order: Order.descending, limit: 1) { response -> Void in
                switch response {
                case .success(let ledgerResponse):
                    if let lastLedger = ledgerResponse.records.first {
                        observer.onNext(lastLedger)
                    } else {
                        observer.onError("Couldn't find latest ledger")
                    }
                case .failure(let error):
                    observer.onError(error.parseError())
                }
            }
            return Disposables.create()
        }
    }
}

extension TransactionsService {
    @available(iOS 13.0, *)
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
