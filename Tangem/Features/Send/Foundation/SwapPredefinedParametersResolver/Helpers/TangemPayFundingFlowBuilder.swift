//
//  TangemPayFundingFlowBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

/// Builds the swap parameters behind Add funds and Withdraw. Returns `nil` while the account has no
/// address to fund or withdraw from.
struct TangemPayFundingFlowBuilder {
    private let userWalletInfo: UserWalletInfo
    private let userWalletModel: any UserWalletModel
    private let tangemPayAccount: TangemPayAccount
    private let recentOperationsRecorder: TangemPayRecentOperationsRecorder

    init(
        userWalletInfo: UserWalletInfo,
        userWalletModel: any UserWalletModel,
        tangemPayAccount: TangemPayAccount
    ) {
        self.userWalletInfo = userWalletInfo
        self.userWalletModel = userWalletModel
        self.tangemPayAccount = tangemPayAccount

        recentOperationsRecorder = TangemPayRecentOperationsRecorder(
            store: InjectedValues[\.tangemPayRecentOperationsStore],
            customerWalletId: tangemPayAccount.userWalletId.stringValue
        )
    }

    @MainActor
    func addFunds() async -> PredefinedSwapParameters? {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return nil
        }

        let builder = TangemPayAddFundsSwapPredefinedParametersBuilder(
            userWalletInfo: userWalletInfo,
            userWalletModel: userWalletModel,
            tangemPayAccount: tangemPayAccount,
            depositAddress: depositAddress,
            accountTokens: await accountTokens(),
            recentOperationsRecorder: recentOperationsRecorder
        )

        return builder.make()
    }

    enum WithdrawResolution {
        case parameters(PredefinedSwapParameters)
        case unavailable
    }

    @MainActor
    func withdraw() async -> WithdrawResolution {
        let accountTokens = await accountTokens()

        guard let mostFunded = accountTokens.withdrawStartingPoint else {
            return .unavailable
        }

        return .parameters(makeWithdrawParameters(accountTokens: accountTokens, sourceAccountToken: mostFunded, repeatedTarget: nil))
    }

    @MainActor
    func withdraw(repeating target: TangemPayRecentOperationTarget) async -> WithdrawResolution {
        let accountTokens = await accountTokens()

        guard let accountToken = accountTokens.first(where: {
            $0.isWithdrawEligible && $0.tokenItem == target.paymentAccountTokenItem
        }) else {
            return .unavailable
        }

        return .parameters(makeWithdrawParameters(accountTokens: accountTokens, sourceAccountToken: accountToken, repeatedTarget: target))
    }
}

// MARK: - Private

private extension TangemPayFundingFlowBuilder {
    func makeWithdrawParameters(
        accountTokens: [TangemPayAccountToken],
        sourceAccountToken: TangemPayAccountToken,
        repeatedTarget: TangemPayRecentOperationTarget?
    ) -> PredefinedSwapParameters {
        let builder = TangemPayWithdrawSwapPredefinedParametersBuilder(
            userWalletInfo: userWalletInfo,
            tangemPayAccount: tangemPayAccount,
            accountTokens: accountTokens,
            sourceAccountToken: sourceAccountToken,
            repeatedTarget: repeatedTarget,
            recentOperationsRecorder: recentOperationsRecorder
        )

        return builder.make()
    }

    @MainActor
    func accountTokens() async -> [TangemPayAccountToken] {
        // An empty list also means "not loaded yet" — reload so only an account that truly
        // has no enabled networks ends up with nothing.
        if tangemPayAccount.networks.isEmpty {
            await tangemPayAccount.loadBalance()
        }

        return TangemPayAccountTokensResolver().resolve(networks: tangemPayAccount.networks)
    }
}
