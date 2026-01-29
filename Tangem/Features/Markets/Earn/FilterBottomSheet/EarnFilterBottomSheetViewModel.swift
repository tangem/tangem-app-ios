//
//  EarnFilterBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemLocalization

class EarnFilterBottomSheetViewModel: ObservableObject, Identifiable {
    enum FilterKind {
        case networks
        case types
    }

    @Published var listOptionViewModel: [DefaultSelectableRowViewModel<EarnFilterOption>]
    @Published var currentSelection: EarnFilterOption

    var title: String {
        switch kind {
        case .networks: return Localization.earnFilterAllNetworks
        case .types: return Localization.earnFilterAllTypes
        }
    }

    // MARK: - Private Properties

    private var subscription: AnyCancellable?
    private var dismiss: (() -> Void)?

    private let kind: FilterKind
    private let provider: EarnFilterProvider

    // MARK: - Init

    init(kind: FilterKind, provider: EarnFilterProvider, onDismiss: (() -> Void)?) {
        self.kind = kind
        self.provider = provider
        dismiss = onDismiss

        switch kind {
        case .networks:
            currentSelection = .network(provider.currentFilterValue.network)
            listOptionViewModel = provider.supportedNetworks.map {
                DefaultSelectableRowViewModel(
                    id: .network($0),
                    title: $0.description,
                    subtitle: nil
                )
            }
        case .types:
            currentSelection = .type(provider.currentFilterValue.type)
            listOptionViewModel = provider.supportedTypes.map {
                DefaultSelectableRowViewModel(
                    id: .type($0),
                    title: $0.description,
                    subtitle: nil
                )
            }
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
        currentSelection = option
        switch option {
        case .network(let value):
            provider.didSelectNetwork(value)
        case .type(let value):
            provider.didSelectType(value)
        }
        dismiss?()
    }
}
