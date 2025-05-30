//
//  CompositeLoggableTrustEvaluator.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire

public final class CompositeLoggableTrustEvaluator: ServerTrustEvaluating {
    private let evaluators: [ServerTrustEvaluating]

    /// Creates a `CompositeLoggableTrustEvaluator` from the provided evaluators with an additional logging.
    ///
    /// - Parameter evaluators: The `ServerTrustEvaluating` values used to evaluate the server trust.
    public init(evaluators: [ServerTrustEvaluating]) {
        self.evaluators = evaluators
    }

    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        do {
            try evaluators.evaluate(trust, forHost: host)
        } catch {
            TangemTrustEvaluatorLogger.info("🔐 TrustEvaluator cancelled: \(error)")
            TLSDetailsLogHelper.logTrustDetails(trust: trust, forHost: host)
            throw error
        }
    }
}
