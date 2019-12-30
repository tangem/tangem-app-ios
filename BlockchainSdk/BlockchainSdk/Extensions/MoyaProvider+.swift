//
//  MoyaProvider+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

extension MoyaProvider {
    @available(iOS 13.0, *)
    func requestCombine(_ target: Target) -> AnyPublisher<Response, MoyaError> {
        let future = Future<Response, MoyaError> {[unowned self] promise in
            self.request(target) { result in
                switch result {
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
