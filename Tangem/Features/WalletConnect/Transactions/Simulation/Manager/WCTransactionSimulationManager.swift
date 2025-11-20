import Foundation
import Combine
import BlockchainSdk
import TangemLocalization

protocol WCTransactionSimulationManager {
    func startSimulation(
        for transactionData: WCHandleTransactionData,
        userWalletModel: UserWalletModel
    ) async -> TransactionSimulationState

    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WCSendableTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel?
}

final class CommonWCTransactionSimulationManager: WCTransactionSimulationManager {
    private let simulationService: WCTransactionSimulationService
    private let displayService: WCTransactionSimulationDisplayService

    init(
        simulationService: WCTransactionSimulationService = CommonWCTransactionSimulationService(blockaidService: BlockaidFactory().makeBlockaidAPIService()),
        displayService: WCTransactionSimulationDisplayService = WCTransactionSimulationDisplayService()
    ) {
        self.simulationService = simulationService
        self.displayService = displayService
    }

    func startSimulation(
        for transactionData: WCHandleTransactionData,
        userWalletModel: UserWalletModel
    ) async -> TransactionSimulationState {
        // accounts_fixes_needed_wc
        guard let address = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain.networkId == transactionData.blockchain.networkId
        })?.defaultAddressString else {
            return .simulationFailed(error: Localization.wcEstimatedWalletChangesNotSimulated)
        }

        return await simulationService.simulateTransaction(
            for: transactionData.method,
            address: address,
            blockchain: transactionData.blockchain,
            requestData: transactionData.requestData,
            domain: transactionData.dAppData.domain
        )
    }

    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WCSendableTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel? {
        return displayService.createDisplayModel(
            from: simulationState,
            originalTransaction: originalTransaction,
            userWalletModel: userWalletModel,
            onApprovalEdit: onApprovalEdit
        )
    }
}
