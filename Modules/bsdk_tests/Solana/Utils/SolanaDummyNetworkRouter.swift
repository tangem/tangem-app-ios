//
//  SolanaTestNetworkRouter.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

final class SolanaDummyNetworkRouter: NetworkingRouter {
    // MARK: - Override Implementation

    override func request<T>(method: HTTPMethod = .post, bcMethod: String = #function, parameters: [(any Encodable)?] = [], enableСontinuedRetry: Bool = true, onComplete: @escaping (Result<T, any Error>) -> Void) where T: Decodable {
        onComplete(.failure(SolanaError.nullValue))
    }
}
