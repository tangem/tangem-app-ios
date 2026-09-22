//
//  EarnTypeFilterBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class EarnTypeFilterBottomSheetViewModel: ObservableObject, Identifiable, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<EarnFilterType>]
    @Published var currentSelection: EarnFilterType

    var title: String {
        Localization.commonType
    }

    // MARK: - Identifiable

    let id = UUID()

    // MARK: - Private Properties

    private var subscription: AnyCancellable?
    private let filterProvider: EarnDataFilterProvider
    private let analyticsProvider: EarnAnalyticsProvider
    private let dismissAction: (() -> Void)?

    // MARK: - Init

    init(
        filterProvider: EarnDataFilterProvider,
        analyticsProvider: EarnAnalyticsProvider,
        onDismiss: (() -> Void)? = nil
    ) {
        self.filterProvider = filterProvider
        self.analyticsProvider = analyticsProvider
        dismissAction = onDismiss
        currentSelection = filterProvider.selectedFilterType
        listOptionViewModel = filterProvider.supportedFilterTypes.map {
            DefaultSelectableRowViewModel(
                id: $0,
                title: $0.optionTitle,
                subtitle: $0.optionSubtitle
            )
        }
        bind()
    }

    func onCloseTap() {
        dismiss()
    }

    /// Duplicates are deliberately kept so that picking the already selected type closes the sheet too. That is also
    /// why `selectAndDismiss` must never write `currentSelection` back — the sink would feed itself.
    private func bind() {
        subscription = $currentSelection
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newType in
                viewModel.selectAndDismiss(type: newType)
            })
    }

    private func selectAndDismiss(type: EarnFilterType) {
        analyticsProvider.logBestOpportunitiesFilterTypeApplied(type: type.analyticsTypeValue)
        filterProvider.didSelectFilterType(type)
        dismiss()
    }

    private func dismiss() {
        dismissAction?()
    }
}
