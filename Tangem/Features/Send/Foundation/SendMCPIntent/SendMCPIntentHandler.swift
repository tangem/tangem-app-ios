//
//  SendMCPIntentHandler.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import enum TangemLocalization.Localization
import struct TangemLogger.Logger
import TangemMCP

@MainActor
final class SendMCPIntentHandler {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: any OverlayViewPresenter
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    private let coordinatorFactory = CommonMainCoordinatorChildFactory()
    private let sendIntentClient = MoyaMCPSendIntentClient()
    private let analyticsReporter = MCPIntentAnalyticsReporter(intentType: .send)
    private var processingIntents: [String: IntentProcessingPhase] = [:]

    private let logger: TangemLogger.Logger = MCPLogger

    nonisolated init() {}

    func handle(_ intentDeeplink: MCPIntentDeeplink) async {
        guard processingIntents[intentDeeplink.comparableID] == nil else {
            logger.warning("Send MCP intent with id \(intentDeeplink.id) is already being processed")
            return
        }

        processingIntents[intentDeeplink.comparableID] = .presenting

        let initialLoadingOutcome = await load(intentDeeplink: intentDeeplink)

        guard !userWalletRepository.isLocked else {
            logger.warning("Wallets got locked while Send MCP intent with id \(intentDeeplink.id) was loading")
            finishProcessing(intentDeeplink: intentDeeplink)
            return
        }

        let viewModel = MCPModuleFactory.makeSendIntentViewModel(
            initialLoadingResult: initialLoadingOutcome.result,
            sheetAppearedAction: { [analyticsReporter] in
                analyticsReporter.reportLoadEvent(initialLoadingOutcome.analyticsEvent, intentID: intentDeeplink.id)
            },
            closeAction: { [self] in
                if processingIntents[intentDeeplink.comparableID] == .presenting {
                    finishProcessing(intentDeeplink: intentDeeplink)
                }
            },
            retryAction: { [self] in
                let loadingOutcome = await load(intentDeeplink: intentDeeplink)
                analyticsReporter.reportLoadEvent(loadingOutcome.analyticsEvent, intentID: intentDeeplink.id)
                return loadingOutcome.result
            }
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

// MARK: - Intent processing

private extension SendMCPIntentHandler {
    func finishProcessing(intentDeeplink: MCPIntentDeeplink) {
        processingIntents[intentDeeplink.comparableID] = nil
    }
}

// MARK: - Intent loading

private extension SendMCPIntentHandler {
    func load(intentDeeplink: MCPIntentDeeplink) async -> MCPIntentLoadingOutcome<MCPSendIntentProposalState> {
        let intent: SendMCPIntent

        do throws(SendMCPIntentError) {
            intent = try await sendIntentClient.fetch(intentId: intentDeeplink.id)
        } catch {
            logger.error("Failed to fetch Send MCP intent", error: error)
            return .failed(
                MCPIntentIssue.sendIntentUnreachable(isRecoverable: error.isNetworkingTransportError),
                reason: error.analyticsLoadFailureReason,
                errorCode: error.analyticsErrorCode
            )
        }

        let target = findSendTarget(for: intent)

        guard !intent.isCompleted else {
            logger.warning("Send MCP intent has already been completed")
            return .failed(
                MCPIntentIssue.sendIntentProcessed(amount: intent.amount, tokenItem: target?.walletModel.tokenItem),
                reason: .alreadyProcessed
            )
        }

        guard let target else {
            logger.warning("No wallet holds the token of the send intent")
            return .failed(
                MCPIntentIssue.sendIntentUnreachable(isRecoverable: false),
                reason: holdsToken(of: intent) ? .wrongWallet : .tokenMissing
            )
        }

        guard isValid(intent, for: target) else {
            let fitsDecimals = SendMCPIntentValidator.fitsDecimals(intent.amount, decimalCount: target.walletModel.tokenItem.decimalCount)
            return .failed(
                MCPIntentIssue.sendIntentUnreachable(isRecoverable: false),
                reason: fitsDecimals ? .unknown : .invalidAmount
            )
        }

        let agent = await MCPAssembly.UseCases.fetchAgent(agentID: intent.agentID)

        let proposal = MCPModuleFactory.makeSendIntentProposal(
            agent: agent,
            amount: intent.amount,
            walletModel: target.walletModel,
            proceedAction: { [self] in
                proceedToSend(intentDeeplink: intentDeeplink, intent: intent)
            }
        )

        return .loaded(proposal, agent: agent, tokenItem: target.walletModel.tokenItem)
    }

    func isValid(_ intent: SendMCPIntent, for target: DeeplinkWalletModelLocator.Target) -> Bool {
        guard SendMCPIntentValidator.canSend(from: target) else {
            logger.warning("The wallet can't send the token of the send intent right now")
            return false
        }

        guard
            SendMCPIntentValidator.isValidDestination(
                intent.toAddress,
                ownAddresses: target.walletModel.allAddresses.map(\.value),
                blockchain: target.walletModel.tokenItem.blockchain
            )
        else {
            logger.warning("The destination of the send intent is invalid or belongs to the sender")
            return false
        }

        guard SendMCPIntentValidator.isValidMemo(intent.memo, for: target.walletModel.tokenItem.blockchain) else {
            logger.warning("The memo of the send intent is invalid for its network")
            return false
        }

        guard SendMCPIntentValidator.fitsDecimals(intent.amount, decimalCount: target.walletModel.tokenItem.decimalCount) else {
            logger.warning("The amount of the send intent has more decimals than its token")
            return false
        }

        return true
    }

    func holdsToken(of intent: SendMCPIntent) -> Bool {
        userWalletRepository.models.contains { userWalletModel in
            AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager).contains { walletModel in
                walletModel.tokenItem.id == intent.tokenID && walletModel.tokenItem.blockchain.networkId == intent.networkID
            }
        }
    }

    func findSendTarget(for intent: SendMCPIntent) -> DeeplinkWalletModelLocator.Target? {
        for userWalletModel in userWalletRepository.models {
            let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

            let walletModel = walletModels.first { walletModel in
                !walletModel.isJointAccountParticipant
                    && walletModel.tokenItem.id == intent.tokenID
                    && walletModel.tokenItem.blockchain.networkId == intent.networkID
                    && SendMCPIntentValidator.isOwnAddress(
                        intent.fromAddress,
                        ownAddresses: walletModel.allAddresses.map(\.value),
                        blockchain: walletModel.tokenItem.blockchain
                    )
            }

            if let walletModel {
                return DeeplinkWalletModelLocator.Target(walletModel: walletModel, userWalletModel: userWalletModel)
            }
        }

        return nil
    }
}

// MARK: - Send

private extension SendMCPIntentHandler {
    func proceedToSend(intentDeeplink: MCPIntentDeeplink, intent: SendMCPIntent) {
        guard
            SendFeatureProvider.shared.isAvailable,
            let target = findSendTarget(for: intent),
            isValid(intent, for: target)
        else {
            analyticsReporter.reportIntentLoadFailed(intentID: intentDeeplink.id, reason: .sendNotOpened)
            logger.warning("Send MCP intent with id \(intentDeeplink.id) can no longer be sent")
            alertPresenter.present(
                alert: AlertBuilder.makeAlertWithDefaultPrimaryButton(
                    title: Localization.commonSomethingWentWrong,
                    message: Localization.commonTryAgainLater,
                    buttonText: Localization.commonOk
                )
            )
            return
        }

        openSend(intentDeeplink: intentDeeplink, intent: intent, target: target)
    }

    func openSend(intentDeeplink: MCPIntentDeeplink, intent: SendMCPIntent, target: DeeplinkWalletModelLocator.Target) {
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

        processingIntents[intentDeeplink.comparableID] = .sending

        let overlayViewPresenter = overlayViewPresenter
        let context = DeeplinkOverlayContext(
            id: intentDeeplink.id,
            coordinatorFactory: coordinatorFactory,
            present: { overlayViewPresenter.present($0) },
            dismiss: { overlayViewPresenter.dismiss() }
        )

        let coordinator = SendCoordinator(
            dismissAction: { options in
                Task { Self.finishSend(with: options, in: context) }
            },
            popToRootAction: { _ in overlayViewPresenter.dismiss() }
        )

        coordinator.start(
            with: .init(
                type: .send(sourceToken, parameters: parameters),
                source: .main,
                onTransactionDispatched: { [self] result in
                    processingIntents[intentDeeplink.comparableID] = .reporting

                    let tokenItem = target.walletModel.tokenItem
                    let isModified = SendMCPIntentValidator.isModified(intent, sentAs: result.transfer, blockchain: tokenItem.blockchain)

                    Task {
                        await reportTransaction(result.hash, intentDeeplink: intentDeeplink, tokenItem: tokenItem, isModified: isModified)
                    }
                }
            )
        )

        overlayViewPresenter.present(
            OverlayView(
                id: intentDeeplink.id,
                view: SendCoordinatorView(coordinator: coordinator),
                style: .sheet,
                onDismiss: { [self] in
                    if processingIntents[intentDeeplink.comparableID] == .sending {
                        finishProcessing(intentDeeplink: intentDeeplink)
                    }
                }
            )
        )

        analyticsReporter.reportContinueButtonTapped(intentID: intentDeeplink.id)
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

// MARK: - Hash report

private extension SendMCPIntentHandler {
    func reportTransaction(_ transactionHash: String, intentDeeplink: MCPIntentDeeplink, tokenItem: TokenItem, isModified: Bool) async {
        do throws(SendMCPIntentError) {
            try await Self.reportTransaction(
                retryPauses: Constants.reportRetryPauses,
                report: { () async throws(SendMCPIntentError) in
                    try await sendIntentClient.reportTransaction(sendIntentID: intentDeeplink.id, transactionHash: transactionHash)
                },
                pause: { try? await Task.sleep(for: $0) }
            )
            analyticsReporter.reportIntentCompleted(intentID: intentDeeplink.id, tokenItem: tokenItem, isModified: isModified)
            finishProcessing(intentDeeplink: intentDeeplink)
        } catch {
            analyticsReporter.reportIntentReportFailed(intentID: intentDeeplink.id, errorCode: error.analyticsErrorCode)
            logger.error("Failed to report the transaction of the send intent, its link is ignored until the app restarts", error: error)
        }
    }
}

extension SendMCPIntentHandler {
    static func reportTransaction(
        retryPauses: [Duration],
        report: () async throws(SendMCPIntentError) -> Void,
        pause: (Duration) async -> Void
    ) async throws(SendMCPIntentError) {
        var remainingPauses = retryPauses[...]

        while true {
            do throws(SendMCPIntentError) {
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

    static func canRetryReport(after error: SendMCPIntentError) -> Bool {
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
}

// MARK: - Nested types

private extension SendMCPIntentHandler {
    enum IntentProcessingPhase {
        case presenting
        case sending
        case reporting
    }

    enum Constants {
        static let reportRetryPauses: [Duration] = [.seconds(2), .seconds(5), .seconds(15)]
        static let navigationAfterDismissDelay: TimeInterval = 0.6
        static let feeCurrencyIdSuffix = "/fee-currency"
        static let swapIdSuffix = "/swap"
    }
}

// MARK: - MCPIntentIssue+

private extension MCPIntentIssue {
    static func sendIntentUnreachable(isRecoverable: Bool) -> MCPIntentIssue {
        MCPIntentIssue(
            severity: .error,
            title: Localization.mcpSendIntentCantReachTitle,
            subtitle: nil,
            isRecoverable: isRecoverable
        )
    }

    static func sendIntentProcessed(amount: Decimal, tokenItem: TokenItem?) -> MCPIntentIssue {
        let formattedAmount = tokenItem.map { MCPModuleFactory.makeFormattedSendAmount(amount, tokenItem: $0) }

        return MCPIntentIssue(
            severity: .notice,
            title: Localization.mcpIntentProcessedTitle,
            subtitle: formattedAmount.map(Localization.mcpSendIntentProcessedSubtitle),
            isRecoverable: false
        )
    }
}

// MARK: - MCPIntentDeeplink+

private extension MCPIntentDeeplink {
    var comparableID: String {
        id.lowercased()
    }
}

// MARK: - SendMCPIntentError+

private extension SendMCPIntentError {
    var isNetworkingTransportError: Bool {
        switch self {
        case .timeout, .noInternetConnection:
            true

        case .invalidIntentId, .unsupportedType, .invalidAmount, .requestFailed:
            false
        }
    }

    var analyticsLoadFailureReason: MCPIntentAnalyticsReporter.LoadFailureReason {
        switch self {
        case .timeout, .noInternetConnection:
            return .unreachable

        case .invalidAmount:
            return .invalidAmount

        case .requestFailed(let underlying):
            guard case .statusCode(let response) = underlying as? MoyaError, response.statusCode == 404 else {
                return .unknown
            }

            return .notFound

        case .invalidIntentId, .unsupportedType:
            return .unknown
        }
    }

    var analyticsErrorCode: String {
        switch self {
        case .requestFailed(let underlying):
            guard case .statusCode(let response) = underlying as? MoyaError else {
                return "requestFailed"
            }

            return String(response.statusCode)

        case .timeout:
            return "timeout"

        case .noInternetConnection:
            return "noInternetConnection"

        case .invalidIntentId:
            return "invalidIntentId"

        case .unsupportedType:
            return "unsupportedType"

        case .invalidAmount:
            return "invalidAmount"
        }
    }
}
