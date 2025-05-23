//
//  WalletConnectGetDAppConnectionProposalUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

final class WalletConnectGetDAppConnectionProposalUseCase {
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

    func callAsFunction() async throws -> WalletConnectDAppConnectionProposal {
        let (dAppData, sessionProposal) = try await dAppDataService.getDAppDataAndProposal(for: uri, source: analyticsSource)

        try Self.validate(dAppDomain: dAppData.domain)

        try Task.checkCancellation()

        let verificationStatus = try await verificationService.verify(dAppDomain: dAppData.domain)

        return WalletConnectDAppConnectionProposal(dApp: dAppData, verificationStatus: .malicious([.blurFarming]), sessionProposal: sessionProposal)
    }
}

// MARK: - Validation

extension WalletConnectGetDAppConnectionProposalUseCase {
    private static let unsupportedDAppDomains = [
        "dydx.exchange",
        "pro.apex.exchange",
        "sandbox.game",
        "app.paradex.trade",
    ]

    private static func validate(dAppDomain: URL) throws(WalletConnectV2Error) {
        for unsupportedDAppDomain in unsupportedDAppDomains {
            if dAppDomain.absoluteString.contains(unsupportedDAppDomain) {
                throw WalletConnectV2Error.unsupportedDApp
            }
        }
    }
}
