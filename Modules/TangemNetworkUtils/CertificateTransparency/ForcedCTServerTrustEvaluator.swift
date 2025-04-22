//
//  ForcedCTServerTrustEvaluator.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import TangemLogger

public enum ForcedCTServerTrustEvaluator {
    #if ALPHA || BETA || DEBUG
    public static var shouldForceCT: Bool = false
    #else
    public static var shouldForceCT: Bool = true
    #endif // ALPHA || BETA || DEBUG

    public static func evaluate(trust: SecTrust) throws {
        logCT()
        
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

    private static func logCT() {
        var flags: [String] = []

        #if ALPHA
        flags.append("ALPHA")
        #endif // ALPHA

        #if BETA
        flags.append("BETA")
        #endif // BETA

        #if DEBUG
        flags.append("DEBUG")
        #endif // DEBUG

        if shouldForceCT {
            flags.append("shouldForceCT")
        }

        let message = "🔐 Forced CT evaluation flags: \(flags.joined(separator: ", "))"
        NetworkLogger.info(message)
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
