//
//  CommonBackendAuthenticationAnalyticsReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol TangemBackendAuthentication.BackendAuthenticationAnalyticsReporter

struct CommonBackendAuthenticationAnalyticsReporter: BackendAuthenticationAnalyticsReporter {
    func reportDeviceNonceTimeout() {
        reportNonceTimeout(type: Analytics.ParameterValue.backendAuthNonceTypeDevice)
    }

    func reportAuthenticationNonceTimeout() {
        reportNonceTimeout(type: Analytics.ParameterValue.backendAuthNonceTypeAuthentication)
    }

    func reportMobileUserWalletNonceTimeout() {
        reportNonceTimeout(type: Analytics.ParameterValue.backendAuthNonceTypeMobileWallet)
    }

    func reportColdUserWalletNonceTimeout() {
        reportNonceTimeout(type: Analytics.ParameterValue.backendAuthNonceTypeColdWallet)
    }

    private func reportNonceTimeout(type: Analytics.ParameterValue) {
        let event = Analytics.Event.backendAuthNonceRequestTimeout
        Analytics.log(event, params: [Analytics.ParameterKey.type: type])
    }
}
