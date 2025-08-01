import Foundation
import Combine
import BlockchainSdk

protocol WCTransactionSecurityManager {
    func validateTransactionSecurity(simulationState: TransactionSimulationState) -> BlockaidChainScanResult?

    func createSecurityAlert(
        for validationResult: BlockaidChainScanResult,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () async -> Void,
        backAction: @escaping () -> Void
    ) -> (state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput)?

    func getDAppVerificationStatus(
        for topic: String,
        connectedDAppRepository: any WalletConnectConnectedDAppRepository
    ) async throws -> Bool
}

final class CommonWCTransactionSecurityManager: WCTransactionSecurityManager {
    func validateTransactionSecurity(simulationState: TransactionSimulationState) -> BlockaidChainScanResult? {
        switch simulationState {
        case .simulationSucceeded(let result):
            if let validationStatus = result.validationStatus {
                switch validationStatus {
                case .malicious, .warning:
                    return result
                case .benign:
                    return nil
                }
            }
        default:
            return nil
        }

        return nil
    }

    func createSecurityAlert(
        for validationResult: BlockaidChainScanResult,
        primaryAction: @escaping () -> Void,
        secondaryAction: @escaping () async -> Void,
        backAction: @escaping () -> Void
    ) -> (state: WCTransactionSecurityAlertState, input: WCTransactionSecurityAlertInput)? {
        guard let validationStatus = validationResult.validationStatus else { return nil }

        let input = WCTransactionSecurityAlertInput(
            validationStatus: validationStatus,
            validationDescription: validationResult.validationDescription,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction,
            backAction: backAction
        )

        guard let state = WCTransactionSecurityAlertFactory.makeSecurityAlertState(input: input) else {
            return nil
        }

        return (state: state, input: input)
    }

    func getDAppVerificationStatus(
        for topic: String,
        connectedDAppRepository: any WalletConnectConnectedDAppRepository
    ) async throws -> Bool {
        let dApp = try await connectedDAppRepository.getDApp(with: topic)
        return dApp.verificationStatus.isVerified
    }
}
