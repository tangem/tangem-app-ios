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
        let proposalReceivedDomainVerificationValue = getAnalyticsVerificationParameterValue(
            from: connectionProposal.verificationStatus
        )

        let blockchainNames = connectionProposal.sessionProposal.requiredBlockchains
            .union(connectionProposal.sessionProposal.optionalBlockchains)
            .map(\.displayName)
            .joined(separator: ",")

        let proposalReceivedEvent = Analytics.Event.walletConnectDAppSessionProposalReceived
        let proposalReceivedParams: [Analytics.ParameterKey: String] = [
            .walletConnectDAppName: connectionProposal.dAppData.name,
            .networks: blockchainNames,
            .walletConnectDAppDomainVerification: proposalReceivedDomainVerificationValue.rawValue,
        ]

        Analytics.log(event: proposalReceivedEvent, params: proposalReceivedParams)
    }

    func logConnectButtonTapped() {
        Analytics.log(.walletConnectDAppConnectionRequestConnectButtonTapped)
    }

    func logCancelButtonTapped() {
        Analytics.log(.walletConnectCancelButtonTapped, params: [.commonType: .walletConnectCancelButtonTypeDApp])
    }

    func logDAppConnected(with dAppData: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus) {
        let proposalReceivedDomainVerificationValue = getAnalyticsVerificationParameterValue(from: verificationStatus)

        let params: [Analytics.ParameterKey: String] = [
            .walletConnectDAppName: dAppData.name,
            .walletConnectDAppUrl: dAppData.domain.absoluteString,
            .walletConnectDAppDomainVerification: proposalReceivedDomainVerificationValue.rawValue,
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

    private func getAnalyticsVerificationParameterValue(from verificationStatus: WalletConnectDAppVerificationStatus) -> Analytics.ParameterValue {
        switch verificationStatus {
        case .verified: .walletConnectVerified

        case .unknownDomain: .unknown

        case .malicious: .walletConnectRisky
        }
    }
}
