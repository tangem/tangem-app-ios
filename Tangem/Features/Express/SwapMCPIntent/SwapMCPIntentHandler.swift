//
//  SwapMCPIntentHandler.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import enum Moya.MoyaError
import TangemExpress
import enum TangemLocalization.Localization
import struct TangemLogger.Logger
import TangemMCP
import TangemNetworkUtils

@MainActor
final class SwapMCPIntentHandler {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.incomingActionHandler) private var incomingActionHandler: any IncomingActionHandler

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
    private let logger: TangemLogger.Logger = MCPLogger

    nonisolated init() {}

    func handle(_ intentDeeplink: MCPIntentDeeplink) async {
        let intentID = intentDeeplink.id
        let initialLoadingResult = await load(intentID: intentID)

        guard !userWalletRepository.isLocked else {
            logger.warning("Wallets got locked while Swap MCP intent with id \(intentID) was loading")
            return
        }

        let viewModel = MCPModuleFactory.makeSwapIntentViewModel(
            initialLoadingResult: initialLoadingResult,
            retryAction: { [self] in
                // [REDACTED_TODO_COMMENT]
                await load(intentID: intentID)
            }
        )

        // [REDACTED_TODO_COMMENT]
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

// MARK: - Intent loading

private extension SwapMCPIntentHandler {
    func load(intentID: String) async -> MCPIntentLoadingResult<MCPSwapIntentProposalState> {
        guard let selectedUserWallet = userWalletRepository.selectedModel else {
            // [REDACTED_TODO_COMMENT]
            logger.warning("No selected wallet to load Swap MCP intent with")
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentUnreachable(isRecoverable: false))
        }

        // [REDACTED_TODO_COMMENT]
        let provider = expressAPIProviderFactory.makeExpressAPIProvider(
            userWalletId: selectedUserWallet.userWalletId,
            refcode: selectedUserWallet.userWalletInfo.refcode
        )

        let intent: ExchangeMCPIntent

        do {
            intent = try await provider.exchangeIntent(mcpIntentID: intentID)
        } catch {
            // [REDACTED_TODO_COMMENT]
            logger.error("Failed to fetch Swap MCP intent", error: error)
            return MCPIntentLoadingResult.issue(
                MCPIntentIssue.swapIntentUnreachable(isRecoverable: error.isNetworkingTransportError)
            )
        }

        guard !intent.isHandled else {
            // [REDACTED_TODO_COMMENT]
            logger.warning("Swap MCP intent has already been processed")
            let swapTexts = makeProcessedSwapTexts(for: intent)
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentProcessed(from: swapTexts?.from, to: swapTexts?.to))
        }

        if case .from = intent.specifiedAmount, intent.rateType == .fixed {
            // [REDACTED_TODO_COMMENT]
            logger.warning("Unsupported combination: from-amount intent with a fixed rate")
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentUnreachable(isRecoverable: false))
        }

        guard let userWalletModel = DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: intent.walletID) else {
            // [REDACTED_TODO_COMMENT]
            logger.warning("Failed to resolve the wallet of the swap intent on this device")
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentUnreachable(isRecoverable: false))
        }

        guard
            let fromWalletModel = walletModel(for: intent.from, in: userWalletModel),
            let toWalletModel = walletModel(for: intent.to, in: userWalletModel)
        else {
            // [REDACTED_TODO_COMMENT]
            logger.warning("Failed to resolve the from/to token of the swap intent in the wallet")
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentUnreachable(isRecoverable: false))
        }

        guard
            let swapDeeplinkURL = makeSwapDeeplinkURL(
                intent: intent,
                userWalletModel: userWalletModel,
                fromWalletModel: fromWalletModel,
                toWalletModel: toWalletModel
            )
        else {
            // [REDACTED_TODO_COMMENT]
            logger.warning("Failed to construct a valid SwapDeeplink from ExchangeMCPIntent. Developer mistake")
            return MCPIntentLoadingResult.issue(MCPIntentIssue.swapIntentUnreachable(isRecoverable: false))
        }

        let agent = await MCPAssembly.UseCases.fetchAgent(agentID: intent.agentID)
        let fromToken = MCPModuleFactory.makeMCPToken(from: fromWalletModel)
        let toToken = MCPModuleFactory.makeMCPToken(from: toWalletModel)

        let state: MCPSwapIntentProposalState

        switch intent.specifiedAmount {
        case .from(let amount):
            let formattedAmount = MCPModuleFactory.makeFormattedAmount(amount, symbol: fromToken.symbol)
            state = MCPSwapIntentProposalState(
                agent: agent,
                fromAmount: MCPSwapAmount(token: fromToken, formattedValue: formattedAmount),
                toToken: toToken
            )

        case .to(let amount):
            let formattedAmount = MCPModuleFactory.makeFormattedAmount(amount, symbol: toToken.symbol)
            state = MCPSwapIntentProposalState(
                agent: agent,
                fromToken: fromToken,
                toAmount: MCPSwapAmount(token: toToken, formattedValue: formattedAmount)
            )
        }

        return MCPModuleFactory.makeSwapIntentProposal(
            state: state,
            proceedAction: { [incomingActionHandler] in
                // [REDACTED_TODO_COMMENT]
                _ = incomingActionHandler.handleIncomingURL(swapDeeplinkURL)
            }
        )
    }

    func makeProcessedSwapTexts(for intent: ExchangeMCPIntent) -> (from: String, to: String)? {
        guard
            let userWalletModel = DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: intent.walletID),
            let fromWalletModel = walletModel(for: intent.from, in: userWalletModel),
            let toWalletModel = walletModel(for: intent.to, in: userWalletModel)
        else {
            return nil
        }

        let fromSymbol = fromWalletModel.tokenItem.currencySymbol
        let toSymbol = toWalletModel.tokenItem.currencySymbol

        switch intent.specifiedAmount {
        case .from(let amount):
            return (from: MCPModuleFactory.makeFormattedAmount(amount, symbol: fromSymbol), to: toSymbol)

        case .to(let amount):
            return (from: fromSymbol, to: MCPModuleFactory.makeFormattedAmount(amount, symbol: toSymbol))
        }
    }

    func makeSwapDeeplinkURL(
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
            intentId: intent.id
        )

        return deeplink.toURL()
    }

    func walletModel(for asset: ExchangeMCPIntent.Asset, in userWalletModel: some UserWalletModel) -> (any WalletModel)? {
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

// MARK: - MCPIntentIssue+

private extension MCPIntentIssue {
    static func swapIntentUnreachable(isRecoverable: Bool) -> MCPIntentIssue {
        MCPIntentIssue(
            severity: .error,
            title: Localization.mcpIntentCantReachTitle,
            subtitle: nil,
            isRecoverable: isRecoverable
        )
    }

    static func swapIntentProcessed(from: String?, to: String?) -> MCPIntentIssue {
        let subtitle: String? = if let from, let to {
            Localization.mcpSwapIntentProcessedSubtitle(from, to)
        } else {
            nil
        }

        return MCPIntentIssue(
            severity: .notice,
            title: Localization.mcpIntentProcessedTitle,
            subtitle: subtitle,
            isRecoverable: false
        )
    }
}

// MARK: - Error+

private extension Error {
    var isNetworkingTransportError: Bool {
        guard let moyaError = self as? MoyaError else {
            return false
        }

        return moyaError.isTimeout || moyaError.isNotConnectedToInternet
    }
}
