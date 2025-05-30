//
//  ForcedCTServerTrustEvaluator.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import Alamofire

struct ForcedCTServerTrustEvaluator: ServerTrustEvaluating {
    func evaluate(_ trust: SecTrust, forHost host: String) throws {
        if let dictionary = SecTrustCopyResult(trust) {
            let qualified = (dictionary as NSDictionary)[kSecTrustCertificateTransparency] as? Bool ?? false
            if !qualified {
                TangemTrustEvaluatorLogger.info("🔐 TrustEvaluator CT disabled")
                throw AFError.serverTrustEvaluationFailed(reason: .trustEvaluationFailed(error: ForcedCTServerTrustEvaluatingError.ctDisabled))
            }
        }
    }
}

extension ForcedCTServerTrustEvaluator {
    enum ForcedCTServerTrustEvaluatingError: String, LocalizedError {
        case ctDisabled

        public var errorDescription: String? {
            "\(self)"
        }
    }
}
