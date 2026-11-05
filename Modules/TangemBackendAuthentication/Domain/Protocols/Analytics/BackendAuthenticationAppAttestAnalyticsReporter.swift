//
//  BackendAuthenticationAppAttestAnalyticsReporter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol BackendAuthenticationAppAttestAnalyticsReporter: Sendable {
    func reportAttestationFailed(with error: AppAttestServiceError)
    func reportAssertionFailed(with error: AppAttestServiceError)
}
