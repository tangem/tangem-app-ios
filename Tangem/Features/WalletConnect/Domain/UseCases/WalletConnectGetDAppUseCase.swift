//
//  WalletConnectGetDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

final class WalletConnectGetDAppUseCase {
    private let dAppDataService: any WalletConnectDAppDataService
    private let verificationService: any WalletConnectDAppVerificationService

    private let uri: WalletConnectRequestURI
    private let analyticsSource: Analytics.WalletConnectSessionSource

    init(
        dAppDataService: some WalletConnectDAppDataService,
        verificationService: some WalletConnectDAppVerificationService,
        uri: WalletConnectRequestURI,
        analyticsSource: Analytics.WalletConnectSessionSource
    ) {
        self.dAppDataService = dAppDataService
        self.verificationService = verificationService
        self.uri = uri
        self.analyticsSource = analyticsSource
    }

    func callAsFunction() async throws -> WalletConnectDApp {
        let dAppData = try await dAppDataService.getDAppData(for: uri, source: analyticsSource)
        let verificationStatus = try await verificationService.verify(dAppDomain: dAppData.domain)

        return WalletConnectDApp(data: dAppData, verificationStatus: verificationStatus)
    }
}
