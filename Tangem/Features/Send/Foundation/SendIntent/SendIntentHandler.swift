//
//  SendIntentHandler.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import struct TangemLogger.Logger
import TangemMCP

final class SendIntentHandler {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var floatingSheetPresentingStateProvider: any FloatingSheetPresentingStateProvider
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: any OverlayViewPresenter
    @Injected(\.overlayViewPresentingStateProvider) private var overlayViewPresentingStateProvider: any OverlayViewPresentingStateProvider

    private let coordinatorFactory = CommonMainCoordinatorChildFactory()
    private let sendIntentClient = MoyaMCPSendIntentClient()
    private var processingIntentIDs: Set<String> = []
    private let logger: TangemLogger.Logger = MCPLogger
}

// MARK: - Handling

@MainActor
extension SendIntentHandler {
    func handle(_ intentDeeplink: MCPIntentDeeplink) async {
        guard !isOnScreen(comparableId: intentDeeplink.comparableId) else {
            logger.info("The send intent is already on screen")
            return
        }

        await loadSendIntent(intentDeeplink)
    }
}

// MARK: - Retry

extension SendIntentHandler {
    static func canRetryLoading(after error: MCPSendIntentError) -> Bool {
        switch error {
        case .timeout, .noInternetConnection:
            true
        case .invalidIntentId, .unsupportedType, .invalidAmount, .requestFailed:
            false
        }
    }
}

// MARK: - Hash report

extension SendIntentHandler {
    static let reportRetryPauses: [Duration] = [.seconds(2), .seconds(5), .seconds(15)]

    static func canRetryReport(after error: MCPSendIntentError) -> Bool {
        switch error {
        case .timeout, .noInternetConnection:
            return true
        case .requestFailed(let underlying):
            switch underlying as? MoyaError {
            case .statusCode(let response):
                return (500 ..< 600).contains(response.statusCode) || [401, 408, 429].contains(response.statusCode)
            case .underlying:
                return true
            default:
                return false
            }
        case .invalidIntentId, .unsupportedType, .invalidAmount:
            return false
        }
    }

    static func reportTransaction(
        retryPauses: [Duration] = reportRetryPauses,
        report: () async throws(MCPSendIntentError) -> Void,
        pause: (Duration) async -> Void
    ) async throws(MCPSendIntentError) {
        var remainingPauses = retryPauses[...]

        while true {
            do throws(MCPSendIntentError) {
                try await report()
                return
            } catch {
                guard canRetryReport(after: error), let nextPause = remainingPauses.popFirst() else {
                    throw error
                }

                await pause(nextPause)
            }
        }
    }
}

// MARK: - Screen tracking

extension SendIntentHandler {
    static func isOnScreen(intentID: String, presentedOverlayId: String?, containsSheet: (_ id: String) -> Bool) -> Bool {
        presentedOverlayId == intentID || containsSheet(intentID)
    }
}

// MARK: - Intent sheets

@MainActor
private extension SendIntentHandler {
    func isOnScreen(comparableId: String) -> Bool {
        Self.isOnScreen(intentID: comparableId, presentedOverlayId: overlayViewPresentingStateProvider.presentedOverlayId) { [floatingSheetPresentingStateProvider] id in
            floatingSheetPresentingStateProvider.containsSheet(withId: id)
        }
    }

    func showIntentStatus(
        _ status: MCPIntentStatus,
        comparableId: String,
        primaryActionClosesSheet: Bool = true,
        primaryAction: @escaping () -> Void = {}
    ) {
        guard !userWalletRepository.isLocked else {
            logger.info("Wallets got locked while the intent was loading")
            return
        }

        let viewModel = MCPModuleFactory.makeIntentStatusViewModel(
            id: comparableId,
            status: status,
            primaryActionClosesSheet: primaryActionClosesSheet,
            primaryAction: primaryAction
        )
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func showUnreachableStatus(comparableId: String, retry: (@MainActor () async -> Void)?) {
        guard let retry else {
            showIntentStatus(.unreachable(canRetry: false), comparableId: comparableId)
            return
        }

        showIntentStatus(.unreachable(canRetry: true), comparableId: comparableId) {
            Task { @MainActor in
                await retry()
            }
        }
    }
}

// MARK: - Send Intent

@MainActor
private extension SendIntentHandler {
    func loadSendIntent(_ intentDeeplink: MCPIntentDeeplink) async {
        guard processingIntentIDs.insert(intentDeeplink.comparableId).inserted else {
            logger.info("The send intent is already being processed")
            return
        }

        defer { processingIntentIDs.remove(intentDeeplink.comparableId) }

        guard SendFeatureProvider.shared.isAvailable else {
            logger.info("Send is unavailable, the send intent is dropped")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        let intent: MCPSendIntent

        do throws(MCPSendIntentError) {
            intent = try await sendIntentClient.fetch(intentId: intentDeeplink.id)
        } catch {
            logger.error("Failed to fetch the send intent", error: error)
            showUnreachableSendStatus(intentDeeplink, canRetry: Self.canRetryLoading(after: error))
            return
        }

        guard !userWalletRepository.isLocked else {
            logger.info("Wallets got locked while the send intent was loading")
            return
        }

        let target = findSendTarget(for: intent)

        guard !intent.isCompleted else {
            logger.info("The send intent is already completed")
            showCompletedStatus(of: intent, comparableId: intentDeeplink.comparableId, target: target)
            return
        }

        guard let target else {
            logger.info("No wallet holds the token of the send intent")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        guard canSend(from: target) else {
            logger.info("The wallet can't send the token of the send intent right now")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        guard isValidDestination(intent.toAddress, for: target.walletModel) else {
            logger.info("The destination of the send intent is invalid or belongs to the sender")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        guard SendIntentValidator.isValidMemo(intent.memo, for: target.walletModel.tokenItem.blockchain) else {
            logger.info("The memo of the send intent is invalid for its network")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        guard SendIntentValidator.fitsDecimals(intent.amount, decimalCount: target.walletModel.tokenItem.decimalCount) else {
            logger.info("The amount of the send intent has more decimals than its token")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        let agent = await MCPAssembly.UseCases.fetchAgent(agentID: intent.agentId)

        guard !userWalletRepository.isLocked else {
            logger.info("Wallets got locked while the agent of the send intent was loading")
            return
        }

        let viewModel = MCPModuleFactory.makeSendIntentViewModel(
            id: intentDeeplink.comparableId,
            agent: agent,
            amount: intent.amount,
            walletModel: target.walletModel,
            proceedAction: { [weak self] in
                self?.proceedToSend(intent: intent, intentDeeplink: intentDeeplink)
            }
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func proceedToSend(intent: MCPSendIntent, intentDeeplink: MCPIntentDeeplink) {
        guard SendFeatureProvider.shared.isAvailable, let target = findSendTarget(for: intent), canSend(from: target) else {
            logger.info("The wallet can't send the token of the send intent anymore")
            showUnreachableSendStatus(intentDeeplink)
            return
        }

        openSend(intent: intent, intentDeeplink: intentDeeplink, target: target)
    }

    func showUnreachableSendStatus(_ intentDeeplink: MCPIntentDeeplink, canRetry: Bool = false) {
        guard canRetry else {
            showUnreachableStatus(comparableId: intentDeeplink.comparableId, retry: nil)
            return
        }

        showUnreachableStatus(comparableId: intentDeeplink.comparableId) { [weak self] in
            await self?.loadSendIntent(intentDeeplink)
        }
    }

    func showCompletedStatus(of intent: MCPSendIntent, comparableId: String, target: DeeplinkWalletModelLocator.Target?) {
        guard let target else {
            showIntentStatus(.sendFinished(amount: nil), comparableId: comparableId)
            return
        }

        let amount = MCPModuleFactory.makeFormattedSendAmount(intent.amount, tokenItem: target.walletModel.tokenItem)

        showIntentStatus(.sendFinished(amount: amount), comparableId: comparableId, primaryActionClosesSheet: false) { [weak self] in
            self?.openTransactions(of: intent, in: target)
        }
    }

    func openTransactions(of intent: MCPSendIntent, in target: DeeplinkWalletModelLocator.Target) {
        let deeplink = TokenDeeplink(
            tokenId: intent.tokenId,
            networkId: intent.networkId,
            userWalletId: target.userWalletModel.userWalletId.stringValue,
            derivationPath: target.walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath
        )

        incomingActionManager.deliver(.navigation(deeplink.action))
    }

    func findSendTarget(for intent: MCPSendIntent) -> DeeplinkWalletModelLocator.Target? {
        for userWalletModel in userWalletRepository.models {
            let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

            let walletModel = walletModels.first { walletModel in
                !walletModel.isJointAccountParticipant
                    && walletModel.tokenItem.id == intent.tokenId
                    && walletModel.tokenItem.blockchain.networkId == intent.networkId
                    && isOwnAddress(intent.fromAddress, of: walletModel)
            }

            if let walletModel {
                return DeeplinkWalletModelLocator.Target(walletModel: walletModel, userWalletModel: userWalletModel)
            }
        }

        return nil
    }

    func canSend(from target: DeeplinkWalletModelLocator.Target) -> Bool {
        let availability = TokenActionAvailabilityProvider(
            userWalletInfo: target.userWalletModel.userWalletInfo,
            walletModel: target.walletModel
        ).sendAvailability

        let hasBlockingPendingTransaction = target.walletModel.hasAnyPendingTransactions
            && !target.walletModel.tokenItem.blockchain.isParallelTransactionAllowed

        return SendIntentValidator.canSend(availability, hasBlockingPendingTransaction: hasBlockingPendingTransaction)
    }

    func reportTransaction(_ transactionHash: String, of intentDeeplink: MCPIntentDeeplink) async {
        processingIntentIDs.insert(intentDeeplink.comparableId)

        do {
            try await Self.reportTransaction(
                report: { () async throws(MCPSendIntentError) in
                    try await sendIntentClient.reportTransaction(intentId: intentDeeplink.id, transactionHash: transactionHash)
                },
                pause: { try? await Task.sleep(for: $0) }
            )
            processingIntentIDs.remove(intentDeeplink.comparableId)
        } catch {
            logger.error("Failed to report the transaction of the send intent, its link is ignored until the app restarts", error: error)
        }
    }

    func isOwnAddress(_ address: String, of walletModel: any WalletModel) -> Bool {
        SendIntentValidator.isOwnAddress(
            address,
            ownAddresses: walletModel.allAddresses.map(\.value),
            blockchain: walletModel.tokenItem.blockchain
        )
    }

    func isValidDestination(_ address: String, for walletModel: any WalletModel) -> Bool {
        SendIntentValidator.isValidDestination(
            address,
            ownAddresses: walletModel.allAddresses.map(\.value),
            blockchain: walletModel.tokenItem.blockchain
        )
    }

    func openSend(intent: MCPSendIntent, intentDeeplink: MCPIntentDeeplink, target: DeeplinkWalletModelLocator.Target) {
        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: target.userWalletModel.userWalletInfo,
            walletModel: target.walletModel,
            operationType: .swapAndSend
        ).makeSwapableToken()

        let parametersFactory = MainQRSendParametersFactory()
        let parameters = parametersFactory.resolveSendParameters(
            parametersFactory.makeSendParameters(destination: intent.toAddress, amount: intent.amount, tag: intent.memo),
            sourceToken: sourceToken
        )

        let overlayViewPresenter = overlayViewPresenter
        let context = DeeplinkOverlayContext(
            id: intentDeeplink.comparableId,
            coordinatorFactory: coordinatorFactory,
            present: { overlayViewPresenter.present($0) },
            dismiss: { overlayViewPresenter.dismiss() }
        )
        let coordinator = SendCoordinator(
            dismissAction: { options in
                Task { @MainActor in Self.finishSend(with: options, in: context) }
            },
            popToRootAction: { _ in overlayViewPresenter.dismiss() }
        )
        coordinator.start(
            with: .init(
                type: .send(sourceToken, parameters: parameters),
                source: .main,
                onTransactionDispatched: { [weak self] transactionHash in
                    Task { @MainActor in
                        await self?.reportTransaction(transactionHash, of: intentDeeplink)
                    }
                }
            )
        )

        overlayViewPresenter.present(OverlayView(id: intentDeeplink.comparableId, view: SendCoordinatorView(coordinator: coordinator), style: .sheet))
    }

    static func finishSend(with option: SendCoordinator.DismissOptions?, in context: DeeplinkOverlayContext) {
        context.dismiss()

        switch option {
        case .openFeeCurrency(let feeCurrency):
            openFeeCurrency(feeCurrency, in: context)
        case .openSwap(let swap):
            openSwap(swap, in: context)
        case .closeButtonTap, .none:
            break
        }
    }

    static func openFeeCurrency(_ option: FeeCurrencyNavigatingDismissOption, in context: DeeplinkOverlayContext) {
        guard let result = try? WalletModelFinder.findWalletModel(userWalletId: option.userWalletId, tokenItem: option.tokenItem) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.navigationAfterDismissDelay) {
            context.makeTokenDetailsOverlay(
                walletModel: result.walletModel,
                userWalletModel: result.userWalletModel,
                pendingTransactionDetails: nil,
                id: context.id + Constants.feeCurrencyIdSuffix
            )
            .map { context.present($0) }
        }
    }

    static func openSwap(_ option: SwapNavigatingDismissOption, in context: DeeplinkOverlayContext) {
        guard let options = option.makeSwapFlowOptions(source: .main) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.navigationAfterDismissDelay) {
            let coordinator = SendCoordinator(
                dismissAction: { options in
                    Task { @MainActor in finishSend(with: options, in: context) }
                },
                popToRootAction: { _ in context.dismiss() }
            )
            coordinator.start(with: options)

            context.present(context.sheet(SendCoordinatorView(coordinator: coordinator), id: context.id + Constants.swapIdSuffix))
        }
    }
}

// MARK: - Constants

private extension SendIntentHandler {
    enum Constants {
        static let navigationAfterDismissDelay: TimeInterval = 0.6
        static let feeCurrencyIdSuffix = "/fee-currency"
        static let swapIdSuffix = "/swap"
    }
}
