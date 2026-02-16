//
//  EarnWidgetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemFoundation

final class EarnWidgetViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published private(set) var isFirstLoading: Bool = true
    @Published private(set) var resultState: LoadingResult<[EarnTokenItemViewModel], Error> = .loading

    let widgetType: MarketsWidgetType

    // MARK: - Properties

    private let widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler
    private let earnDataProvider: MarketsWidgetEarnProvider
    private let analyticsService: EarnWidgetAnalyticsProvider

    private weak var coordinator: EarnWidgetRoutable?

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        widgetType: MarketsWidgetType,
        widgetsUpdateHandler: MarketsMainWidgetsUpdateHandler,
        earnDataProvider: MarketsWidgetEarnProvider,
        analyticsService: EarnWidgetAnalyticsProvider,
        coordinator: EarnWidgetRoutable?
    ) {
        self.widgetType = widgetType
        self.widgetsUpdateHandler = widgetsUpdateHandler
        self.earnDataProvider = earnDataProvider
        self.analyticsService = analyticsService
        self.coordinator = coordinator

        bind()
        update()
    }

    deinit {
        AppLogger.debug("EarnWidgetViewModel deinit")
    }

    // MARK: - Public Implementation

    func tryLoadAgain() {
        update()
    }

    @MainActor
    func onSeeAllTapAction() {
        analyticsService.logEarnListOpened()
        let tokens = earnDataProvider.earnResult.value ?? []
        coordinator?.openSeeAllEarnWidget(mostlyUsedTokens: tokens)
    }
}

// MARK: - Private Implementation

private extension EarnWidgetViewModel {
    func update() {
        earnDataProvider.fetch()
    }

    func bind() {
        widgetsUpdateHandler
            .widgetsUpdateStateEventPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                switch state {
                case .loaded:
                    viewModel.updateViewState()
                    viewModel.clearIsFirstLoadingFlag()
                case .initialLoading:
                    viewModel.resultState = .loading
                case .reloading(let widgetTypes):
                    if widgetTypes.contains(viewModel.widgetType) {
                        viewModel.resultState = .loading
                    }
                case .allFailed:
                    // Global error UI is handled at a higher level
                    return
                }
            }
            .store(in: &bag)

        earnDataProvider
            .earnResultPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                let widgetLoadingState: WidgetLoadingState

                switch result {
                case .loading:
                    widgetLoadingState = .loading
                case .success:
                    widgetLoadingState = .loaded
                case .failure:
                    widgetLoadingState = .error
                }

                viewModel.widgetsUpdateHandler.performUpdateLoading(state: widgetLoadingState, for: viewModel.widgetType)
            }
            .store(in: &bag)
    }

    func updateViewState() {
        switch earnDataProvider.earnResult {
        case .success(let tokens):
            let viewModels = tokens.prefix(Constants.itemsOnListWidget).map { token in
                EarnTokenItemViewModel(
                    token: token,
                    onTapAction: { [weak self] in
                        self?.onTokenTapAction(with: token)
                    }
                )
            }
            resultState = .success(Array(viewModels))
        case .failure(let error):
            resultState = .failure(error)
            analyticsService.logEarnLoadError(error)
        case .loading:
            resultState = .loading
        }
    }

    private func onTokenTapAction(with token: EarnTokenModel) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            analyticsService.logEarnOpportunitySelected(token: token.symbol, blockchain: token.networkName)
            let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }
            let resolution = EarnTokenInWalletResolver().resolve(earnToken: token, userWalletModels: userWalletModels)
            coordinator?.routeOnTokenResolved(resolution, source: .markets)
        }
    }

    func clearIsFirstLoadingFlag() {
        if isFirstLoading {
            isFirstLoading = false
        }
    }
}

private extension EarnWidgetViewModel {
    enum Constants {
        static let itemsOnListWidget = 5
    }
}
