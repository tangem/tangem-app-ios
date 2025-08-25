//
//  TangemTrustEvaluatorURLSessionDelegate.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public class TangemTrustEvaluatorURLSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let result = TangemTrustEvaluatorUtil.evaluate(challenge: challenge)
        completionHandler(result.0, result.1)
    }
}
