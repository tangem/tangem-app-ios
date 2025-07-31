//
//  CommonWalletConnectDAppConnectionRequestAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

final class CommonWalletConnectDAppConnectionRequestAnalyticsLogger: WalletConnectDAppConnectionRequestAnalyticsLogger {
    private let source: Analytics.WalletConnectSessionSource

    init(source: Analytics.WalletConnectSessionSource) {
        self.source = source
    }

    func logSessionInitiated() {
        Analytics.log(event: .walletConnectSessionInitiated, params: [.source: source.rawValue])
    }

    func logSessionFailed(with error: WalletConnectDAppProposalLoadingError) {
        Analytics.log(event: .walletConnectSessionFailed, params: [.errorCode: "\(error.errorCode)"])
    }

    func logConnectionProposalReceived(_ connectionProposal: WalletConnectDAppConnectionProposal) {
        let securityAlertEvent: Analytics.Event?
        let securityAlertParamKey: Analytics.ParameterKey?
        let securityAlertParamValue: Analytics.ParameterValue?
        let proposalReceivedDomainVerificationValue: Analytics.ParameterValue

        switch connectionProposal.verificationStatus {
        case .verified:
            securityAlertEvent = nil
            securityAlertParamKey = nil
            securityAlertParamValue = nil
            proposalReceivedDomainVerificationValue = .walletConnectSecurityAlertVerified

        case .unknownDomain:
            securityAlertEvent = .walletConnectSecurityAlertShown
            securityAlertParamKey = .commonType
            securityAlertParamValue = .unknown
            proposalReceivedDomainVerificationValue = .unknown

        case .malicious:
            securityAlertEvent = .walletConnectSecurityAlertShown
            securityAlertParamKey = .commonType
            securityAlertParamValue = .walletConnectSecurityAlertRisky
            proposalReceivedDomainVerificationValue = .walletConnectSecurityAlertRisky
        }

        let blockchainNames = connectionProposal.sessionProposal.requiredBlockchains
            .union(connectionProposal.sessionProposal.optionalBlockchains)
            .map(\.displayName)
            .joined(separator: ",")

        let proposalReceivedEvent = Analytics.Event.walletConnectDAppSessionProposalReceived
        let proposalReceivedParams: [Analytics.ParameterKey: String] = [
            .networks: blockchainNames,
            .walletConnectDAppDomainVerification: proposalReceivedDomainVerificationValue.rawValue,
        ]

        Analytics.log(event: proposalReceivedEvent, params: proposalReceivedParams)

        guard let securityAlertEvent, let securityAlertParamKey, let securityAlertParamValue else { return }

        let securityAlertParams: [Analytics.ParameterKey: String] = [
            securityAlertParamKey: securityAlertParamValue.rawValue,
            .source: Analytics.ParameterValue.walletConnectSecurityAlertSourceDomain.rawValue,
            .walletConnectDAppName: connectionProposal.dAppData.name,
            .walletConnectDAppUrl: connectionProposal.dAppData.domain.absoluteString,
        ]

        Analytics.log(event: securityAlertEvent, params: securityAlertParams)
    }

    func logConnectButtonTapped() {
        Analytics.log(.walletConnectDAppConnectionRequestConnectButtonTapped)
    }

    func logCancelButtonTapped() {
        Analytics.log(.walletConnectCancelButtonTapped, params: [.commonType: .walletConnectCancelButtonTypeDApp])
    }

    func logDAppConnected(with dAppData: WalletConnectDAppData) {
        let params: [Analytics.ParameterKey: String] = [
            .walletConnectDAppName: dAppData.name,
            .walletConnectDAppUrl: dAppData.domain.absoluteString,
        ]

        Analytics.log(event: .walletConnectDAppConnected, params: params)
    }

    func logDAppConnectionFailed(with error: WalletConnectDAppProposalApprovalError) {
        Analytics.log(event: .walletConnectDAppConnectionFailed, params: [.errorCode: "\(error.errorCode)"])
    }

    func logDAppDisconnected(with dAppData: WalletConnectDAppData) {
        let params: [Analytics.ParameterKey: String] = [
            .walletConnectDAppName: dAppData.name,
            .walletConnectDAppUrl: dAppData.domain.absoluteString,
        ]

        Analytics.log(event: .walletConnectDAppDisconnected, params: params)
    }
}
