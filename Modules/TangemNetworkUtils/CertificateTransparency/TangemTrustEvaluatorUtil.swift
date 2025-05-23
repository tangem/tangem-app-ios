//
//  TangemTrustEvaluatorUtil.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire
import TangemFoundation

public class TangemTrustEvaluatorUtil {
    /// Don't use for requests with sensitive info, create a new session using makeSession(configuration: .ephemeralConfiguration) instead
    public static var sharedSession: URLSession {
        return _sharedSession
    }

    fileprivate static let _sharedSession: URLSession = makeSession(configuration: URLSessionConfiguration.defaultConfiguration)

    private init() {}

    public static func makeEvaluator() -> ServerTrustEvaluating {
        var evaluators: [ServerTrustEvaluating] = []

        evaluators.append(DefaultTrustEvaluator())

        if AppEnvironment.current.isProduction {
            evaluators.append(ForcedCTServerTrustEvaluator())
        }

        let compositeEvaluator = CompositeLoggableTrustEvaluator(evaluators: evaluators)
        return compositeEvaluator
    }

    public static func evaluate(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            TangemTrustEvaluatorLogger.info("🔐 TrustEvaluator unsupported method: \(challenge.protectionSpace.authenticationMethod)")
            return (.cancelAuthenticationChallenge, nil)
        }

        do {
            let evaluator = makeEvaluator()
            try evaluator.evaluate(trust, forHost: challenge.protectionSpace.host)

            return (.useCredential, URLCredential(trust: trust))
        } catch {
            return (.cancelAuthenticationChallenge, nil)
        }
    }

    public static func makeSession(configuration: URLSessionConfiguration = .defaultConfiguration) -> URLSession {
        let session = URLSession(configuration: configuration, delegate: TangemTrustEvaluatorURLSessionDelegate(), delegateQueue: nil)
        return session
    }
}
