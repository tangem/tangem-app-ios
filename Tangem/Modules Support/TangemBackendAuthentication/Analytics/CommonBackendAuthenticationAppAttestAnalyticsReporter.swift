//
//  CommonBackendAuthenticationAppAttestAnalyticsReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemBackendAuthentication.AppAttestServiceError
import protocol TangemBackendAuthentication.BackendAuthenticationAppAttestAnalyticsReporter

struct CommonBackendAuthenticationAppAttestAnalyticsReporter: BackendAuthenticationAppAttestAnalyticsReporter {
    func reportAttestationFailed(with error: AppAttestServiceError) {
        report(stage: Analytics.ParameterValue.backendAuthAttestationStageAttestation, error: error)
    }

    func reportAssertionFailed(with error: AppAttestServiceError) {
        report(stage: Analytics.ParameterValue.backendAuthAttestationStageAssertion, error: error)
    }

    private func report(stage: Analytics.ParameterValue, error: AppAttestServiceError) {
        Analytics.log(
            event: Analytics.Event.backendAuthAttestationFailed,
            params: [
                .stage: stage.rawValue,
                .reason: "\(error)",
            ]
        )
    }
}
