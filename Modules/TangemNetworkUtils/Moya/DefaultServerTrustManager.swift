//
//  DefaultServerTrustManager.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Alamofire

public class DefaultServerTrustManager: ServerTrustManager {
    public init() {
        var evaluators: [ServerTrustEvaluating] = []
        evaluators.append(DefaultTrustEvaluator())
        evaluators.append(ForcedCTServerTrustEvaluatorWrapper())
        let compositeEvaluator = CompositeTrustEvaluator(evaluators: evaluators)
        super.init(allHostsMustBeEvaluated: true, evaluators: [Constants.wildcardMask: compositeEvaluator])
    }

    override public func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        guard let evaluator = evaluators[Constants.wildcardMask] else {
            if allHostsMustBeEvaluated {
                throw AFError.serverTrustEvaluationFailed(reason: .noRequiredEvaluator(host: host))
            }

            return nil
        }

        return evaluator
    }
}

private extension DefaultServerTrustManager {
    enum Constants {
        static let wildcardMask = "*"
    }
}
