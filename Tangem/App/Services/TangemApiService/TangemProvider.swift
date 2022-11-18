//
//  TangemProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class TangemProvider<Target: TargetType>: MoyaProvider<Target> {
    init(stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
         plugins: [PluginType] = [],
         configuration: URLSessionConfiguration = .defaultConfiguration) {
        let session = Session(configuration: configuration)

        super.init(stubClosure: stubClosure, session: session, plugins: plugins)
    }
}

extension URLSessionConfiguration {
    static let defaultConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return configuration
    }()
}

extension TangemProvider {
    func asyncRequest<T: Decodable>(for target: Target, failsOnEmptyData: Bool = true) async throws -> T {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }

            self.request(target) { result in
                switch result {
                case .success(let responseValue):
                    do {
                        continuation.resume(returning: try responseValue.map(T.self, failsOnEmptyData: failsOnEmptyData))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
