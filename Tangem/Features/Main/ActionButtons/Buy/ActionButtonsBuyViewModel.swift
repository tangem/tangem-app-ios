//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class ActionButtonsBuyViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var isPulseResultEmpty: Bool = false

    let tokenSelectorViewModel: TokenSelectorViewModel
    let pulseMarketWidgetViewModel: PulseMarketWidgetViewModel?

    var shouldShowSearchEmptyContent: Bool {
        pulseMarketWidgetViewModel == nil || isPulseResultEmpty
    }

    // MARK: - Private

    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        tokenSelectorViewModel: TokenSelectorViewModel,
        pulseMarketWidgetViewModel: PulseMarketWidgetViewModel?,
        coordinator: some ActionButtonsBuyRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.pulseMarketWidgetViewModel = pulseMarketWidgetViewModel
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
        bind()
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.buy)
        pulseMarketWidgetViewModel?.resumeQuotesUpdates()
    }

    func onDisappear() {
        pulseMarketWidgetViewModel?.pauseQuotesUpdates()
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
        coordinator?.dismiss()
    }
}

// MARK: - Private

private extension ActionButtonsBuyViewModel {
    func bind() {
        guard let pulseMarketWidgetViewModel else { return }

        pulseMarketWidgetViewModel.bind(searchTextPublisher: tokenSelectorViewModel.$searchText)

        pulseMarketWidgetViewModel.$tokenViewModelsState
            .map { state -> Bool in
                guard case .success(let items) = state else { return false }
                return items.isEmpty
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isPulseResultEmpty)
    }
}

// MARK: - TokenSelectorViewModelOutput

extension ActionButtonsBuyViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard let walletModel = item.kind.walletModel else {
            return
        }

        // The incomplete-backup top-up warning is shown downstream in AddFundsViewModel, so no extra check is needed here.
        coordinator?.openAddFunds(userWalletInfo: item.userWalletInfo, walletModel: walletModel)
    }
}
