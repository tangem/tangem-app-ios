//
//  DefaultSigner.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine

public class DefaultSigner: TransactionSigner {
    public var initialMessage: Message? = nil
    
    private let tangemSdk: TangemSdk
    
    public init(tangemSdk: TangemSdk, initialMessage: Message? = nil) {
        self.initialMessage = initialMessage
        self.tangemSdk = tangemSdk
    }
    
    public func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error> {
        let future = Future<SignResponse, Error> {[unowned self] promise in
            self.tangemSdk.sign(hashes: hashes, cardId: cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}
