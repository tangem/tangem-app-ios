//
//  StellarSdk+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

extension AccountService {
    func getAccountDetails(accountId: String) -> AnyPublisher<AccountResponse, Error> {
        let future = Future<AccountResponse, Error> { [unowned self] promise in
            self.getAccountDetails(accountId: accountId) { response -> Void in
                switch response {
                case .success(let accountResponse):
                    promise(.success(accountResponse))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
    
    func checkTargetAccount(address: String, token: Token?) -> AnyPublisher<StellarTargetAccountResponse, Error> {
        getAccountDetails(accountId: address)
            .map { resp -> StellarTargetAccountResponse in
                guard let token = token else {
                    return StellarTargetAccountResponse(accountCreated: true, trustlineCreated: false)
                }
                
                let balance = resp.balances.filter { $0.assetCode == token.symbol && $0.assetIssuer == token.contractAddress }
                return StellarTargetAccountResponse(accountCreated: true, trustlineCreated: !balance.isEmpty )
            }
            .tryCatch { error -> AnyPublisher<StellarTargetAccountResponse, Error> in
                guard
                    let stellarError = error as? HorizonRequestError,
                    case .notFound = stellarError else {
                    throw error
                }
                return Just(StellarTargetAccountResponse(accountCreated: false, trustlineCreated: false))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

extension LedgersService {
    func getLatestLedger() -> AnyPublisher<LedgerResponse, Error> {
        let future = Future<LedgerResponse, Error> { [unowned self] promise in
            self.getLedgers(cursor: nil, order: Order.descending, limit: 1) { response -> Void in
                switch response {
                case .success(let ledgerResponse):
                    if let lastLedger = ledgerResponse.records.first {
                        promise(.success(lastLedger))
                    } else {
                        promise(.failure(StellarError.failedToFindLatestLedger))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}


extension HorizonRequestError {
    var message: String {
        switch self {
        case .emptyResponse:
            return StellarError.emptyResponse.localizedDescription
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
    
    func parseError() -> Error {
        let hotizonMessage = message
        let json = JSON(parseJSON: hotizonMessage)
        let detailMessage = json["detail"].stringValue
        let extras = json["extras"]
        let codes = extras["result_codes"].rawString() ?? ""
        let errorMessage: String = (!detailMessage.isEmpty && !codes.isEmpty) ? "\(detailMessage). Codes: \(codes)" : hotizonMessage
        return errorMessage
    }
}
