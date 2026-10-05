//
//  ExpressCurrencyViewModelBalanceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemAssets
import TangemUI
@testable import Tangem

private let tokenBalanceText = "12.34 pUSD"
private let fiatBalanceText = "$12.34"

@Suite("ExpressCurrencyViewModel balance denomination")
@MainActor
struct ExpressCurrencyViewModelBalanceTests {
    @Test("An account denominated in its own token shows the token balance")
    func tokenDenominationShowsTheTokenBalance() async {
        let viewModel = makeSUT()

        viewModel.update(wallet: .success(makeToken(presentation: makePresentation(denomination: .token))))

        #expect(await settledBalance(of: viewModel) == .loaded(text: tokenBalanceText))
    }

    @Test("An account that names no denomination keeps the fiat balance, the way Tangem Pay is presented")
    func defaultDenominationShowsTheFiatBalance() async {
        let viewModel = makeSUT()

        viewModel.update(wallet: .success(makeToken(presentation: makePresentation())))

        #expect(await settledBalance(of: viewModel) == .loaded(text: fiatBalanceText))
    }

    @Test("An ordinary token, presented as itself, shows its own balance")
    func plainTokenShowsTheTokenBalance() async {
        let viewModel = makeSUT()

        viewModel.update(wallet: .success(makeToken(presentation: nil)))

        #expect(await settledBalance(of: viewModel) == .loaded(text: tokenBalanceText))
    }

    @Test("The sending side is never presented abstractly, so it keeps its own token balance")
    func sendingSideIgnoresThePresentation() async {
        let viewModel = makeSUT(viewType: .send)

        viewModel.update(wallet: .success(makeToken(presentation: makePresentation())))

        #expect(await settledBalance(of: viewModel) == .loaded(text: tokenBalanceText))
    }
}

// MARK: - Fixtures

private extension ExpressCurrencyViewModelBalanceTests {
    func makeSUT(viewType: ExpressCurrencyViewType = .receive) -> ExpressCurrencyViewModel {
        ExpressCurrencyViewModel(
            viewType: viewType,
            headerType: .action(name: "To"),
            canChangeCurrency: false
        )
    }

    func makeToken(presentation: SendReceiveTokenPresentation?) -> SwapableTokenStub {
        SwapableTokenStub(
            tokenItem: .accountToken(symbol: "USDC", contract: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"),
            balanceProviders: SwapableTokenStub.BalanceProviders(
                available: TokenBalanceProviderTestsMock(balance: Decimal(string: "12.34")!, formatted: tokenBalanceText),
                fiatAvailable: TokenBalanceProviderTestsMock(balance: Decimal(string: "12.34")!, formatted: fiatBalanceText)
            ),
            presentation: presentation
        )
    }

    func makePresentation(
        denomination: SendReceiveTokenPresentation.BalanceDenomination? = nil
    ) -> SendReceiveTokenPresentation {
        guard let denomination else {
            return SendReceiveTokenPresentation(currencySymbol: "USD", icon: Assets.Polymarket.accountAvatar)
        }

        return SendReceiveTokenPresentation(
            currencySymbol: "pUSD",
            icon: Assets.Polymarket.accountAvatar,
            balanceDenomination: denomination
        )
    }

    func settledBalance(of viewModel: ExpressCurrencyViewModel) async -> LoadableBalanceView.State? {
        let balanceStates = viewModel.$state
            .map(\.balanceState)
            .subscribe(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        let states = await awaitEmissions(
            of: { balanceStates },
            where: { $0.contains(where: isProvidedBalance) }
        )

        return states?.last
    }
}

private func isProvidedBalance(_ state: LoadableBalanceView.State) -> Bool {
    state == .loaded(text: tokenBalanceText) || state == .loaded(text: fiatBalanceText)
}
