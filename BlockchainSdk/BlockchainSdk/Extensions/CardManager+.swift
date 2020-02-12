//
//  CardManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

@available(iOS 13.0, *)
extension CardManager: TransactionSigner {
    public func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error> {
        let future = Future<SignResponse, Error> {[unowned self] promise in
            self.sign(hashes: hashes, cardId: cardId) { signResponse in
                switch signResponse {
                case .event(let response):
                    promise(.success(response))
                case .completion(let error):
                    if let error = error {
                        promise(.failure(error))
                    }
                }
            }
        }
        return AnyPublisher(future)
    }
}
