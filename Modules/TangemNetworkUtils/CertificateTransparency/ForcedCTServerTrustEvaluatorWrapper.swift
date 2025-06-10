//
//  ForcedCTServerTrustEvaluatorWrapper.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire

struct ForcedCTServerTrustEvaluatorWrapper: ServerTrustEvaluating {
    func evaluate(_ trust: SecTrust, forHost host: String) throws {
        do {
            try ForcedCTServerTrustEvaluator.evaluate(trust: trust)
        } catch {
            throw AFError.serverTrustEvaluationFailed(reason: .trustEvaluationFailed(error: error))
        }
    }
}
