//
//  ForcedCTServerTrustEvaluator.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

public enum ForcedCTServerTrustEvaluator {
    
    #if ALPHA || BETA || DEBUG
    public static var shouldForceCT: Bool = false
    #else
    public static var shouldForceCT: Bool = true
    #endif // ALPHA || BETA || DEBUG

    public static func evaluate(trust: SecTrust) throws {
        guard shouldForceCT else {
            return
        }

        if let dictionary = SecTrustCopyResult(trust) {
            let qualified = (dictionary as NSDictionary)[kSecTrustCertificateTransparency] as? Bool ?? false
            if !qualified {
                throw ForcedCTServerTrustEvaluatingError.ctDisabled
            }
        }
    }

    public static func evaluate(challenge: URLAuthenticationChallenge) -> URLSession.AuthChallengeDisposition {
        let protectionSpace = challenge.protectionSpace

        if let serverTrust = protectionSpace.serverTrust, protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            do {
                try evaluate(trust: serverTrust)
            } catch {
                return .cancelAuthenticationChallenge
            }
        }

        return .performDefaultHandling
    }
}

public extension ForcedCTServerTrustEvaluator {
    enum ForcedCTServerTrustEvaluatingError: String, LocalizedError {
        case ctDisabled

        public var errorDescription: String? {
            "\(self)"
        }
    }
}
