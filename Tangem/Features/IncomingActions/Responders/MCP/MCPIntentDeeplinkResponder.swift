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

    private let expressAPIProviderFactory = ExpressAPIProviderFactory()
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
