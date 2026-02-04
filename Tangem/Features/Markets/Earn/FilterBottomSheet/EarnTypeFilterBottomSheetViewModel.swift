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

    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<EarnFilterOption>]
    @Published var currentSelection: EarnFilterOption

    var title: String {
        Localization.earnFilterAllTypes
    }

    // MARK: - Identifiable

    let id = UUID()

    // MARK: - Private Properties

    private var subscription: AnyCancellable?
    private let provider: EarnFilterProvider
    private let dismiss: (() -> Void)?

    // MARK: - Init

    init(provider: EarnFilterProvider, onDismiss: (() -> Void)? = nil) {
        self.provider = provider
        dismiss = onDismiss
        currentSelection = .type(provider.currentFilterValue.type)
        listOptionViewModel = provider.supportedTypes.map {
            DefaultSelectableRowViewModel(
                id: .type($0),
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
            .sink(receiveValue: { viewModel, newOption in
                viewModel.update(option: newOption)
            })
    }

    private func update(option: EarnFilterOption) {
        guard case .type(let value) = option else { return }
        currentSelection = option
        provider.didSelectType(value)
        dismiss?()
    }
}
