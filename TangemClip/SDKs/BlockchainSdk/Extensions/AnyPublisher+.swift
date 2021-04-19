//
//  AnyPublisher+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine

extension AnyPublisher {
    static func anyFail(error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error)
            .eraseToAnyPublisher()
    }
    
    static var emptyFail: AnyPublisher<Output, Error> {
        Fail(error: "")
            .eraseToAnyPublisher()
    }
    
    static func multiAddressPublisher<T>(addresses: [String], requestFactory: (String) -> AnyPublisher<T, Error>) -> AnyPublisher<[T], Error> {
        Publishers.MergeMany(addresses.map {
            requestFactory($0)
        })
        .collect()
        .eraseToAnyPublisher()
    }
}
