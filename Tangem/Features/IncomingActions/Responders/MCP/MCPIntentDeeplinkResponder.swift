//
//  MCPIntentDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import struct TangemLogger.Logger
import TangemMCP

final class MCPIntentDeeplinkResponder: IncomingActionResponder {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.incomingActionHandler) private var incomingActionHandler: any IncomingActionHandler
    @Injected(\.overlayViewPresenter) private var overlayViewPresenter: any OverlayViewPresenter

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
    private let coordinatorFactory = CommonMainCoordinatorChildFactory()
    private let sendIntentClient = MoyaMCPSendIntentClient()
    private let logger: TangemLogger.Logger = MCPLogger

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard
            FeatureProvider.isAvailable(.mcp),
            case .navigation(.mcpIntent(let intentDeeplink)) = action,
            let selectedUserWallet = userWalletRepository.selectedModel
        else {
            return false
        }

        logger.debug("Received MCP intent deeplink \(intentDeeplink.debugDescription)")

        switch (intentDeeplink.source, intentDeeplink.type) {
        case ("express", "exchange"):
            Task { @MainActor in
                await handleSwapIntent(intentID: intentDeeplink.id, selectedUserWallet: selectedUserWallet)
            }
            return true

        case ("transaction", "send"):
            Task { @MainActor in
                await handleSendIntent(intentDeeplink)
            }
            return true

        default:
            logger.warning("Unrecognized intent deeplink. Handling finished")
            return false
        }
    }
}

// MARK: - Swap Intent

extension MCPIntentDeeplinkResponder {
    @MainActor
    func handleSwapIntent(intentID: String, selectedUserWallet: some UserWalletModel) async {
        logger.debug("Swap intent deeplink handling started")

        // [REDACTED_TODO_COMMENT]
        let provider = expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: selectedUserWallet.userWalletId,
            refcode: selectedUserWallet.userWalletInfo.refcode
        )

        let intent: ExchangeMCPIntent
        do {
            intent = try await provider.exchangeIntent(mcpIntentID: intentID)
        } catch {
            logger.error("Failed to enrich swap intent", error: error)
            // [REDACTED_TODO_COMMENT]
            return
        }

        if case .from = intent.specifiedAmount, intent.rateType == .fixed {
            logger.warning("Unsupported combination: from-amount intent with a fixed rate")
            // [REDACTED_TODO_COMMENT]
            return
        }

        guard let userWalletModel = DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: intent.walletID) else {
            logger.warning("Failed to resolve the intent's wallet on this device")
            // [REDACTED_TODO_COMMENT]
            return
        }

        guard
            let fromWalletModel = Self.walletModel(for: intent.from, in: userWalletModel),
            let toWalletModel = Self.walletModel(for: intent.to, in: userWalletModel)
        else {
            logger.warning("Failed to resolve from/to token in the user's wallet")
            // [REDACTED_TODO_COMMENT]
            return
        }

        guard
            let swapDeeplinkURL = Self.makeSwapDeeplinkURL(
                intent: intent,
                userWalletModel: userWalletModel,
                fromWalletModel: fromWalletModel,
                toWalletModel: toWalletModel
            )
        else {
            logger.warning("Failed to construct a valid SwapDeeplink from ExchangeMCPIntent. Developer mistake")
            // [REDACTED_TODO_COMMENT]
            return
        }

        let agent = await MCPAssembly.fetchMCPAgent(agentID: intent.agentID)
        let fromToken = MCPModuleFactory.makeMCPToken(from: fromWalletModel)
        let toToken = MCPModuleFactory.makeMCPToken(from: toWalletModel)

        let proceedAction: () -> Void = { [incomingActionHandler] in
            _ = incomingActionHandler.handleIncomingURL(swapDeeplinkURL)
        }

        let viewModel: MCPSwapIntentViewModel
        switch intent.specifiedAmount {
        case .from(let amount):
            let formattedAmountValue = MCPModuleFactory.makeFormattedAmount(amount, symbol: fromToken.symbol)
            let fromAmount = MCPSwapAmount(token: fromToken, formattedValue: formattedAmountValue)
            viewModel = MCPModuleFactory.makeSwapIntentViewModel(
                agent: agent,
                fromAmount: fromAmount,
                toToken: toToken,
                proceedAction: proceedAction
            )

        case .to(let amount):
            let formattedAmountValue = MCPModuleFactory.makeFormattedAmount(amount, symbol: toToken.symbol)
            let toAmount = MCPSwapAmount(token: toToken, formattedValue: formattedAmountValue)
            viewModel = MCPModuleFactory.makeSwapIntentViewModel(
                agent: agent,
                fromToken: fromToken,
                toAmount: toAmount,
                proceedAction: proceedAction
            )
        }

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    private static func makeSwapDeeplinkURL(
        intent: ExchangeMCPIntent,
        userWalletModel: some UserWalletModel,
        fromWalletModel: some WalletModel,
        toWalletModel: some WalletModel
    ) -> URL? {
        let fromAmount: String?
        let toAmount: String?

        switch intent.specifiedAmount {
        case .from(let amount):
            fromAmount = amount.description
            toAmount = nil
        case .to(let amount):
            fromAmount = nil
            toAmount = amount.description
        }

        let deeplink = SwapDeeplink(
            userWalletId: userWalletModel.userWalletId.stringValue,
            fromTokenId: fromWalletModel.tokenItem.id,
            fromNetworkId: fromWalletModel.tokenItem.networkId,
            toTokenId: toWalletModel.tokenItem.id,
            toNetworkId: toWalletModel.tokenItem.networkId,
            fromAmount: fromAmount,
            toAmount: toAmount,
            providerId: intent.providerID,
            intentId: intent.intentID
        )

        return deeplink.toURL()
    }

    private static func walletModel(
        for asset: ExchangeMCPIntent.Asset,
        in userWalletModel: some UserWalletModel
    ) -> (any WalletModel)? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        return walletModels.first { walletModel in
            guard walletModel.tokenItem.networkId == asset.currency.network else {
                return false
            }

            if asset.currency.contractAddress == ExpressConstants.coinContractAddress {
                return walletModel.tokenItem.contractAddress == nil
            }

            return walletModel.tokenItem.contractAddress?.caseInsensitiveCompare(asset.currency.contractAddress) == .orderedSame
        }
    }
}

// MARK: - Send Intent

@MainActor
private extension MCPIntentDeeplinkResponder {
    func handleSendIntent(_ intentDeeplink: MCPIntentDeeplink) async {
        guard SendFeatureProvider.shared.isAvailable else {
            logger.info("Send is unavailable, the send intent is dropped")
            return
        }

        let intent: MCPSendIntent

        do {
            intent = try await sendIntentClient.fetch(intentId: intentDeeplink.id)
        } catch {
            logger.error("Failed to fetch the send intent", error: error)
            return
        }

        guard !userWalletRepository.isLocked else {
            logger.info("Wallets got locked while the send intent was loading")
            return
        }

        guard !intent.isCompleted else {
            logger.info("The send intent is already completed")
            return
        }

        guard let target = findSendTarget(for: intent) else {
            logger.info("No wallet holds the token of the send intent")
            return
        }

        guard canSend(from: target) else {
            logger.info("The wallet can't send the token of the send intent right now")
            return
        }

        guard isValidDestination(intent.toAddress, for: target.walletModel) else {
            logger.info("The destination of the send intent is invalid or belongs to the sender")
            return
        }

        guard SendIntentValidator.isValidMemo(intent.memo, for: target.walletModel.tokenItem.blockchain) else {
            logger.info("The memo of the send intent is invalid for its network")
            return
        }

        guard SendIntentValidator.fitsDecimals(intent.amount, decimalCount: target.walletModel.tokenItem.decimalCount) else {
            logger.info("The amount of the send intent has more decimals than its token")
            return
        }

        // [REDACTED_TODO_COMMENT]
        openSend(intent: intent, intentDeeplink: intentDeeplink, target: target)
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

    func reportTransaction(_ transactionHash: String, ofSendIntent intentID: String) async {
        do {
            try await sendIntentClient.reportTransaction(intentId: intentID, transactionHash: transactionHash)
        } catch {
            logger.error("Failed to report the transaction of the send intent", error: error)
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
                        await self?.reportTransaction(transactionHash, ofSendIntent: intentDeeplink.id)
                    }
                }
            )
        )

        overlayViewPresenter.present(OverlayView(id: intentDeeplink.comparableId, view: SendCoordinatorView(coordinator: coordinator), style: .sheet))
        DeeplinkFloatingSheet.dismissActive()
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

private extension MCPIntentDeeplinkResponder {
    enum Constants {
        static let navigationAfterDismissDelay: TimeInterval = 0.6
        static let feeCurrencyIdSuffix = "/fee-currency"
        static let swapIdSuffix = "/swap"
    }
}
