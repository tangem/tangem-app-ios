//
//  FeeSelectorTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemAccessibilityIdentifiers
import TangemUI
import TangemUIUtils

protocol FeeSelectorTokensDataProvider {
    var selectedTokenFeeProvider: TokenFeeProvider { get }
    var selectedTokenFeeProviderPublisher: AnyPublisher<TokenFeeProvider, Never> { get }

    var supportedTokenFeeProviders: [any TokenFeeProvider] { get }
    var supportedTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> { get }
}

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider)
}

final class FeeSelectorTokensViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var availableFeeCurrencyTokens = [FeeSelectorRowViewModel]()

    @Published
    private(set) var unavailableFeeCurrencyTokens = [FeeSelectorRowViewModel]()

    // MARK: - Dependencies

    private let tokensDataProvider: FeeSelectorTokensDataProvider
    private weak var router: FeeSelectorTokensRoutable?

    // MARK: - Properties

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(tokensDataProvider: FeeSelectorTokensDataProvider) {
        self.tokensDataProvider = tokensDataProvider
        bind()
    }

    // MARK: - Public Implementation

    func setup(router: FeeSelectorTokensRoutable?) {
        self.router = router
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.CombineLatest(
            tokensDataProvider.supportedTokenFeeProvidersPublisher,
            tokensDataProvider.selectedTokenFeeProviderPublisher
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { viewModel, output in
            let (providers, selectedProvider) = output

            return providers.map { provider in
                viewModel.mapTokenItemToRowViewModel(
                    tokenFeeProvider: provider,
                    isSelected: selectedProvider.feeTokenItem == provider.feeTokenItem
                )
            }
        }
        .withWeakCaptureOf(self)
        .sink { viewModel, providers in
            let available = providers.filter { $0.availability.isAvailable }
            let unavailable = providers.filter { $0.availability.isUnavailable }

            viewModel.availableFeeCurrencyTokens = available
            viewModel.unavailableFeeCurrencyTokens = unavailable
        }
        .store(in: &bag)
    }

    private func mapTokenItemToRowViewModel(tokenFeeProvider: any TokenFeeProvider, isSelected: Bool) -> FeeSelectorRowViewModel {
        let feeTokenItem = tokenFeeProvider.feeTokenItem
        let subtitleBalanceState = LoadableBalanceViewStateBuilder().build(
            type: tokenFeeProvider.formattedFeeTokenBalance,
            textBuilder: Localization.commonBalance
        )

        // In this view, we disable the row only when the token has no balance; all other states (including failures) remain interactive.
        var feeTokenAvailability: FeeSelectorRowViewModel.Availability {
            switch tokenFeeProvider.state {
            case .unavailable(let reason) where reason.isNoTokenBalance:
                .unavailable
            case .available, .idle, .loading, .unavailable, .error:
                .available(isSubtitleHighlighted: false)
            }
        }

        return FeeSelectorRowViewModel(
            rowType: .token(tokenIconInfo: TokenIconInfoBuilder().build(from: feeTokenItem, isCustom: false)),
            title: feeTokenItem.name,
            subtitle: .balance(subtitleBalanceState),
            accessibilityIdentifier: FeeAccessibilityIdentifiers.feeCurrencyOption,
            availability: feeTokenAvailability,
            isSelected: isSelected,
            selectAction: { [weak self] in
                if feeTokenAvailability.isAvailable {
                    self?.router?.userDidSelectFeeToken(tokenFeeProvider: tokenFeeProvider)
                }
            }
        )
    }
}
