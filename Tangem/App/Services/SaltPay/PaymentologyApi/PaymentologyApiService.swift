//
//  PaymentologyApiService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import Moya

protocol PaymentologyApiService: AnyObject {
    func checkRegistration(for cardId: String, publicKey: Data) -> AnyPublisher<RegistrationResponse.Item, Error>
    func requestAttestationChallenge(for cardId: String, publicKey: Data) -> AnyPublisher<AttestationResponse, Error>
    func registerWallet(request: ReqisterWalletRequest) -> AnyPublisher<RegisterWalletResponse, Error>
    func registerKYC(request: RegisterKYCRequest) -> AnyPublisher<RegisterWalletResponse, Error>
}

class CommonPaymentologyApiService {
    private let provider = TangemProvider<PaymentologyApiTarget>(/*stubClosure: MoyaProvider.delayedStub(1.0),*/
        plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])

    deinit {
        print("PaymentologyApiService deinit")
    }
}

extension CommonPaymentologyApiService: PaymentologyApiService {
    func checkRegistration(for cardId: String, publicKey: Data) -> AnyPublisher<RegistrationResponse.Item, Error> {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: cardId, publicKey: publicKey.hexString)
        let request = CardVerifyAndGetInfoRequest(requests: [requestItem])
        let target = PaymentologyApiTarget(type: .checkRegistration(request: request))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegistrationResponse.self, using: JSONDecoder.saltPayDecoder)
            .tryExtractError()
            .tryGetFirstResult()
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }

    func requestAttestationChallenge(for cardId: String, publicKey: Data) -> AnyPublisher<AttestationResponse, Error> {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: cardId, publicKey: publicKey.hexString)
        let target = PaymentologyApiTarget(type: .requestAttestationChallenge(request: requestItem))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(AttestationResponse.self, using: JSONDecoder.saltPayDecoder)
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }

    func registerWallet(request: ReqisterWalletRequest) -> AnyPublisher<RegisterWalletResponse, Error> {
        let target = PaymentologyApiTarget(type: .registerWallet(request: request))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegisterWalletResponse.self, using: JSONDecoder.saltPayDecoder)
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }

    func registerKYC(request: RegisterKYCRequest) -> AnyPublisher<RegisterWalletResponse, Error> {
        let target = PaymentologyApiTarget(type: .registerKYC(request: request))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegisterWalletResponse.self, using: JSONDecoder.saltPayDecoder)
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }
}


fileprivate extension AnyPublisher where Output: ErrorContainer, Failure: Error {
    func tryExtractError() -> AnyPublisher<Output, Error> {
        self.tryMap { container in
            if let error = container.error {
                throw error
            }

            return container
        }
        .eraseToAnyPublisher()
    }
}

fileprivate extension AnyPublisher where Output == RegistrationResponse, Failure == Error {
    func tryGetFirstResult() -> AnyPublisher<RegistrationResponse.Item, Error> {
        self.tryMap { response in
            if let first = response.results.first {
                return first
            }

            throw SaltPayRegistratorError.emptyResponse
        }
        .eraseToAnyPublisher()
    }
}
