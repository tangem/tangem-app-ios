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

final class EarnTypeFilterBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<EarnFilterType>]
    @Published var currentSelection: EarnFilterType

    var title: String {
        Localization.earnFilterAllTypes
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
                title: $0.description,
                subtitle: nil
            )
        }
        bind()
    }

    private func bind() {
        subscription = $currentSelection
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newType in
                viewModel.selectAndDismiss(type: newType)
            })
    }

    private func selectAndDismiss(type: EarnFilterType) {
        currentSelection = type
        analyticsProvider.logBestOpportunitiesFilterTypeApplied(type: type.analyticsTypeValue)
        filterProvider.didSelectFilterType(type)
        dismissAction?()
    }
}
