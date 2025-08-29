//
//  TangemTrustEvaluatorServerTrustManager.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Alamofire

public class TangemTrustEvaluatorServerTrustManager: ServerTrustManager, @unchecked Sendable {
    public init() {
        super.init(allHostsMustBeEvaluated: true, evaluators: [Constants.wildcardMask: TangemTrustEvaluatorUtil.makeEvaluator()])
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

private extension TangemTrustEvaluatorServerTrustManager {
    enum Constants {
        static let wildcardMask = "*"
    }
}
