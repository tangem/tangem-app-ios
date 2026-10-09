//
//  PromoCampaignEnrolledWalletViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI
import Testing
@testable import Tangem

@Suite("PromoCampaignEnrolledWalletViewModel", .tags(.campaigns))
@MainActor
struct PromoCampaignEnrolledWalletViewModelTests {
    @Test("The balance follows the wallet rows: none while empty, Unreachable on a failure without a cache", arguments: BalanceCase.allCases)
    func balanceState(_ balanceCase: BalanceCase) async {
        let sut = makeSUT(totalBalancePublisher: .just(output: balanceCase.totalBalance))

        await drainMainQueue()

        #expect(sut.balanceState == balanceCase.expectedState)
    }

    @Test("A locked wallet shows Locked instead of its balance")
    func lockedWallet() async {
        let sut = makeSUT(isUserWalletLocked: true, totalBalancePublisher: .just(output: .loaded(balance: 7)))

        await drainMainQueue()

        #expect(sut.balanceState == .loaded(text: Localization.commonLocked))
    }

    @Test("A balance still loading when the result opens shows up once it loads")
    func balanceUpdates() async {
        let totalBalanceSubject = CurrentValueSubject<TotalBalanceState, Never>(.loading(cached: nil))
        let sut = makeSUT(totalBalancePublisher: totalBalanceSubject.eraseToAnyPublisher())

        await drainMainQueue()
        totalBalanceSubject.send(BalanceCase.loaded.totalBalance)
        await drainMainQueue()

        #expect(sut.balanceState == BalanceCase.loaded.expectedState)
    }
}

// MARK: - Helpers

private extension PromoCampaignEnrolledWalletViewModelTests {
    func makeSUT(
        isUserWalletLocked: Bool = false,
        totalBalancePublisher: AnyPublisher<TotalBalanceState, Never>
    ) -> PromoCampaignEnrolledWalletViewModel {
        PromoCampaignEnrolledWalletViewModel(
            name: "Main wallet",
            subtitle: "3 cards",
            imageProvider: CardImageProviderMock(),
            isUserWalletLocked: isUserWalletLocked,
            totalBalancePublisher: totalBalancePublisher
        )
    }

    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}

// MARK: - BalanceCase

extension PromoCampaignEnrolledWalletViewModelTests {
    enum BalanceCase: CaseIterable {
        case empty
        case loaded
        case failedWithoutCache
        case failedWithCache
        case loadingWithCache

        var totalBalance: TotalBalanceState {
            switch self {
            case .empty: .empty
            case .loaded: .loaded(balance: 4496.75)
            case .failedWithoutCache: .failed(cached: nil, failedItems: [])
            case .failedWithCache: .failed(cached: 12, failedItems: [])
            case .loadingWithCache: .loading(cached: 5)
            }
        }

        @MainActor
        var expectedState: LoadableBalanceView.State {
            switch self {
            case .empty: .empty
            case .loaded: .loaded(text: formattedFiat(4496.75))
            case .failedWithoutCache: .failed(cached: .string(Localization.commonUnreachable))
            case .failedWithCache: .failed(cached: .string(formattedFiat(12)), icon: .leading)
            case .loadingWithCache: .loading(cached: .string(formattedFiat(5)))
            }
        }

        @MainActor
        private func formattedFiat(_ value: Decimal) -> String {
            BalanceFormatter().formatFiatBalance(value, currencyCode: AppSettings.shared.selectedCurrencyCode)
        }
    }
}
