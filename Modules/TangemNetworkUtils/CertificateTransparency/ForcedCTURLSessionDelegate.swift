//
//  ForcedCTURLSessionDelegate.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

open class ForcedCTURLSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let result = ForcedCTServerTrustEvaluator.evaluate(challenge: challenge)
        completionHandler(result, nil)
    }
}
