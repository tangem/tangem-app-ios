import Foundation
import Combine
import BlockchainSdk

protocol WCTransactionSimulationManager {
    var simulationState: CurrentValueSubject<TransactionSimulationState, Never> { get }

    func startSimulation(
        for transactionData: WCHandleTransactionData,
        userWalletModel: UserWalletModel
    ) async

    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WalletConnectEthTransaction?,
        userWalletModel: UserWalletModel,
        onApprovalEdit: ((ApprovalInfo, BlockaidChainScanResult.Asset) -> Void)?
    ) -> WCTransactionSimulationDisplayModel?
}

final class CommonWCTransactionSimulationManager: WCTransactionSimulationManager {
    let simulationState = CurrentValueSubject<TransactionSimulationState, Never>(.notStarted)

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
    ) async {
        simulationState.send(.loading)

        guard let address = userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain.networkId == transactionData.blockchain.networkId
        })?.defaultAddressString else {
            return
        }

        let result = await simulationService.simulateTransaction(
            for: transactionData.method,
            address: address,
            blockchain: transactionData.blockchain,
            requestData: transactionData.requestData,
            domain: transactionData.dAppData.domain
        )

        simulationState.send(result)
    }

    func createDisplayModel(
        from simulationState: TransactionSimulationState,
        originalTransaction: WalletConnectEthTransaction?,
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
