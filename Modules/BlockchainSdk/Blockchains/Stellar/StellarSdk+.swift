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

extension AccountService {
    func checkIsMemoRequired(for address: String) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BlockchainSdkError.empty))
                return
            }

            getAccountDetails(accountId: address) { response in
                switch response {
                case .success(let accountDetails):
                    let memoRequired = accountDetails.data["config.memo_required"] == "MQ=="
                    promise(.success(memoRequired))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAccountDetails(accountId: String) -> AnyPublisher<AccountResponse, Error> {
        let future = Future<AccountResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BlockchainSdkError.empty))
                return
            }

            getAccountDetails(accountId: accountId) { response in
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

                let currencyCodeAndIssuer = StellarAssetIdParser().getAssetCodeAndIssuer(from: token.contractAddress)

                let balance = resp.balances.filter {
                    $0.assetCode == currencyCodeAndIssuer?.assetCode && $0.assetIssuer == currencyCodeAndIssuer?.issuer
                }

                return StellarTargetAccountResponse(accountCreated: true, trustlineCreated: !balance.isEmpty)
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

extension FeeStatsService {
    func getFeeStats() -> AnyPublisher<FeeStatsResponse, Error> {
        Future<FeeStatsResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BlockchainSdkError.empty))
                return
            }

            getFeeStats { response in
                switch response {
                case .success(let details):
                    promise(.success(details))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension LedgersService {
    func getLatestLedger() -> AnyPublisher<LedgerResponse, Error> {
        let future = Future<LedgerResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BlockchainSdkError.empty))
                return
            }

            getLedgers(cursor: nil, order: Order.descending, limit: 1) { response in
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

extension TransactionsService {
    func postTransaction(transactionEnvelope: String) -> AnyPublisher<SubmitTransactionResponse, Error> {
        let future = Future<SubmitTransactionResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BlockchainSdkError.empty))
                return
            }

            postTransaction(transactionEnvelope: transactionEnvelope, response: { response in
                switch response {
                case .success(let submitResponse):
                    promise(.success(submitResponse))
                case .failure(let error):
                    promise(.failure(error))
                case .destinationRequiresMemo:
                    promise(.failure(StellarError.requiresMemo))
                }
            })
        }

        return AnyPublisher(future)
    }
}

extension OperationsService {
    func getAllOperations(accountId: String, recordsLimit: Int = 200) -> AnyPublisher<[OperationResponse], Error> {
        func processResponse(_ response: PageResponse<OperationResponse>.ResponseEnum, in promise: (Result<PageResponse<OperationResponse>, Error>) -> Void) {
            switch response {
            case .success(let details):
                promise(.success(details))
            case .failure(let error):
                promise(.failure(error))
            }
        }

        func pageRequest(prevPage: PageResponse<OperationResponse>) -> AnyPublisher<PageResponse<OperationResponse>, Error> {
            Future<PageResponse<OperationResponse>, Error> { promise in
                prevPage.getNextPage { response in
                    processResponse(response, in: promise)
                }
            }
            .eraseToAnyPublisher()
        }

        func pageRequest(accountId: String, recordsLimit: Int = 200) -> AnyPublisher<PageResponse<OperationResponse>, Error> {
            Future<PageResponse<OperationResponse>, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(BlockchainSdkError.empty))
                    return
                }

                getOperations(forAccount: accountId, limit: recordsLimit) { response in
                    processResponse(response, in: promise)
                }
            }
            .eraseToAnyPublisher()
        }

        let pageResponseSubject = CurrentValueSubject<PageResponse<OperationResponse>?, Error>(nil)

        return pageResponseSubject
            .flatMap { (page: PageResponse<OperationResponse>?) -> AnyPublisher<PageResponse<OperationResponse>, Error> in
                guard let page = page else {
                    return pageRequest(accountId: accountId, recordsLimit: recordsLimit)
                }

                return pageRequest(prevPage: page)
            }
            .handleEvents(receiveOutput: { (resp: PageResponse<OperationResponse>) in
                resp.records.count == recordsLimit ?
                    pageResponseSubject.send(resp) :
                    pageResponseSubject.send(completion: .finished)
            })
            .map { $0.records }
            .reduce([OperationResponse]()) { $0 + $1 }
            .eraseToAnyPublisher()
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
        case .requestFailed(let message, _):
            return message
        case .staleHistory(let message, _):
            return message
        case .unauthorized(let message):
            return message
        case .duplicate(let message, _):
            return message
        case .timeout(let message, _):
            return message
        case .payloadTooLarge(let message, _):
            return message
        }
    }

    func parseError() -> Error {
        do {
            guard let data = message.data(using: .utf8) else {
                return "No data to decode"
            }
            let stellarError = try JSONDecoder.withSnakeCaseStrategy.decode(StellarMessageError.self, from: data)
            let detail = stellarError.detail
            let codes = stellarError.extras.resultCodes
            if !detail.isEmpty, !codes.isEmpty {
                return "\(detail). Codes: \(codes)"
            }

            return message
        } catch {
            return error
        }
    }
}

extension HorizonRequestError {
    struct StellarMessageError: Decodable {
        let detail: String
        let extras: Extras

        struct Extras: Decodable {
            let resultCodes: String
        }
    }
}

extension ChangeTrustOperation {
    enum ChangeTrustLimit {
        /// Maximum trustline limit: 922_337_203_685.4775807 (Int64 max / 1e7).
        /// https://developers.stellar.org/docs/fundamentals-and-concepts/primitives/#amounts
        case max
        /// Sets a custom trustline limit using a decimal string.
        case custom(amount: String)
        /// Removes the trustline by setting the limit to 0.
        case remove

        var value: Decimal? {
            switch self {
            case .max:
                return Decimal(stringValue: "922337203685.4775807")
            case .custom(let amount):
                return Decimal(stringValue: amount)
            case .remove:
                return .zero
            }
        }
    }
}
