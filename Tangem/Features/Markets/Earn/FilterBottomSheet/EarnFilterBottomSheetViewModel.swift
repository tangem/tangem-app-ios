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
import TangemFoundation
import TangemLocalization
import BlockchainSdk

// MARK: - EarnFilterOption

enum EarnFilterOption: Hashable {
    case filterType(EarnFilterType)
    case networkFilter(EarnNetworkFilterType)

    var title: String {
        switch self {
        case .filterType(let value): return value.description
        case .networkFilter(let value): return value.displayTitle
        }
    }
}

// MARK: - EarnFilterBottomSheetViewModel

@MainActor
class EarnFilterBottomSheetViewModel: ObservableObject, Identifiable {
    enum FilterKind {
        case networks
        case types
    }

    struct Section: Identifiable {
        let id = UUID()
        let items: [DefaultSelectableRowViewModel<EarnFilterOption>]
    }

    @Published var sections: [Section]
    @Published var currentSelection: EarnFilterOption

    var title: String {
        switch kind {
        case .networks: return Localization.earnFilterAllNetworks
        case .types: return Localization.earnFilterAllTypes
        }
    }

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()
    private var dismiss: (() -> Void)?

    private let kind: FilterKind
    private let provider: EarnDataFilterProvider

    // MARK: - Init

    init(kind: FilterKind, provider: EarnDataFilterProvider, onDismiss: (() -> Void)?) {
        self.kind = kind
        self.provider = provider
        dismiss = onDismiss

        switch kind {
        case .networks:
            currentSelection = .networkFilter(provider.selectedNetworkFilter)
            sections = Self.buildNetworkSections(availableNetworks: provider.availableNetworks)

            provider.availableNetworksPublisher
                .dropFirst()
                .receiveOnMain()
                .sink { [weak self] networks in
                    self?.sections = Self.buildNetworkSections(availableNetworks: networks)
                }
                .store(in: &bag)
        case .types:
            currentSelection = .filterType(provider.selectedFilterType)
            sections = [
                Section(items: provider.supportedFilterTypes.map {
                    DefaultSelectableRowViewModel(
                        id: .filterType($0),
                        title: $0.description,
                        subtitle: nil
                    )
                }),
            ]
        }

        bind()
    }

    // MARK: - Private Methods

    private static func buildNetworkSections(
        availableNetworks: [EarnNetworkInfo]
    ) -> [Section] {
        let iconBuilder = IconURLBuilder()
        let supportedBlockchains = SupportedBlockchains.all

        // Section 1: General filter options
        let generalOptions: [DefaultSelectableRowViewModel<EarnFilterOption>] = [
            DefaultSelectableRowViewModel(
                id: .networkFilter(.all),
                title: EarnNetworkFilterType.all.displayTitle,
                subtitle: nil
            ),
            DefaultSelectableRowViewModel(
                id: .networkFilter(.userNetworks),
                title: EarnNetworkFilterType.userNetworks.displayTitle,
                subtitle: nil
            ),
        ]

        // Section 2: Specific networks
        let networkOptions: [DefaultSelectableRowViewModel<EarnFilterOption>] = availableNetworks.map { network in
            let filter = EarnNetworkFilterType.specific(networkIds: [network.networkId])

            let blockchain = supportedBlockchains.first { $0.networkId == network.networkId }
            let displayName = blockchain?.displayName ?? network.networkId.capitalized
            let iconURL = iconBuilder.tokenIconURL(id: network.networkId)

            return DefaultSelectableRowViewModel(
                id: .networkFilter(filter),
                title: displayName,
                subtitle: nil,
                iconURL: iconURL
            )
        }

        var sections = [Section(items: generalOptions)]

        if !networkOptions.isEmpty {
            sections.append(Section(items: networkOptions))
        }

        return sections
    }

    private func bind() {
        $currentSelection
            .removeDuplicates()
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, newOption in
                viewModel.update(option: newOption)
            })
            .store(in: &bag)
    }

    private func update(option: EarnFilterOption) {
        switch option {
        case .filterType(let value):
            provider.didSelectFilterType(value)
        case .networkFilter(let value):
            provider.didSelectNetworkFilter(value)
        }
        dismiss?()
    }
}
