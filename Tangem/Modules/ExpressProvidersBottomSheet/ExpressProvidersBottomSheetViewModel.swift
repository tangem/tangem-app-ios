//
//  ExpressProvidersBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressProvidersBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var selectedProvider: ExpressProvider?
    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private let providers: [ExpressProvider]
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable
    private var bag: Set<AnyCancellable> = []

    init(coordinator: ExpressProvidersBottomSheetRoutable) {
        self.coordinator = coordinator

        // Should be pass from manager or something
        providers = [
            ExpressProvider(
                id: "ChangeNOW",
                name: "ChangeNOW",
                url: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/changenow_512.png")!,
                type: .cex
            ),
            ExpressProvider(
                id: "1inch",
                name: "1inch",
                url: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1inch_512.png")!,
                type: .dex
            ),
        ]

        selectedProvider = providers.first
        setupView()
    }

    func setupView() {
        providerViewModels = providers.map { provider in
            mapToProviderRowViewModel(provider: provider)
        }
    }

    func mapToProviderRowViewModel(provider: ExpressProvider) -> ProviderRowViewModel {
        let detailsType: ProviderRowViewModel.DetailsType? = selectedProvider == provider ? .selected : .none

        return ProviderRowViewModel(
            provider: .init(
                iconURL: provider.url,
                name: provider.name,
                type: provider.type.rawValue.uppercased()
            ),
            isDisabled: false,
            badge: provider.type == .dex ? .permissionNeeded : .none,
            subtitles: [.text("1 132,46 MATIC")],
            detailsType: detailsType,
            // Should be replaced on id
            tapAction: { [weak self] in
                self?.selectedProvider = provider
                self?.setupView()
            }
        )
    }
}
