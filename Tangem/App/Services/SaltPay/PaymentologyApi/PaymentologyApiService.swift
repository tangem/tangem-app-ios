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
    func checkRegistration(for cardId: String, publicKey: Data) -> AnyPublisher<SaltPayRegistrator.State, Error>
    func requestAttestationChallenge(for cardId: String, publicKey: Data) -> AnyPublisher<AttestationResponse, Error>
    func registerWallet(request: ReqisterWalletRequest) -> AnyPublisher<RegisterWalletResponse, Error>
    func registerKYC(for walletPublicKey: Data) -> AnyPublisher<RegisterWalletResponse, Error>
}

class CommonPaymentologyApiService {
    private let provider = TangemProvider<PaymentologyApiTarget>()

    deinit {
        print("PaymentologyApiService deinit")
    }
}

extension CommonPaymentologyApiService: PaymentologyApiService {
    func checkRegistration(for cardId: String, publicKey: Data) -> AnyPublisher<SaltPayRegistrator.State, Error> {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: cardId, publicKey: publicKey.hexString)
        let request = CardVerifyAndGetInfoRequest(requests: [requestItem])
        let target = PaymentologyApiTarget(type: .checkRegistration(request: request))
        
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegistrationResponse.self, using: JSONDecoder.tangemSdkDecoder)
            .tryExtractError()
            .tryGetFirstResult()
            .tryExtractError()
            .tryMap { try SaltPayRegistrator.State(from: $0) }
            .retry(3)
            .eraseToAnyPublisher()
    }
    
    func requestAttestationChallenge(for cardId: String, publicKey: Data) -> AnyPublisher<AttestationResponse, Error> {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: cardId, publicKey: publicKey.hexString)
        let target = PaymentologyApiTarget(type: .requestAttestationChallenge(request: requestItem))
        
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(AttestationResponse.self, using: JSONDecoder.tangemSdkDecoder)
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }
    
    func registerWallet(request: ReqisterWalletRequest) -> AnyPublisher<RegisterWalletResponse, Error> {
        let target = PaymentologyApiTarget(type: .registerWallet(request: request))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegisterWalletResponse.self, using: JSONDecoder.tangemSdkDecoder)
            .tryExtractError()
            .retry(3)
            .eraseToAnyPublisher()
    }
    
    func registerKYC(for walletPublicKey: Data) -> AnyPublisher<RegisterWalletResponse, Error> {
        let target = PaymentologyApiTarget(type: .registerKYC(walletPublicKey: walletPublicKey))

        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map(RegisterWalletResponse.self, using: JSONDecoder.tangemSdkDecoder)
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
