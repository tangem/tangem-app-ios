//
//  TangemPayResidencyCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayResidencyCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayResidencyCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            root
                .navigationDestination(
                    for: TangemPayResidencyCoordinator.Route.self,
                    destination: destination
                )
        }
        .alert(item: $coordinator.alert) { $0.alert }
        .sheet(isPresented: $coordinator.isWaitlistPresented) {
            waitlist
        }
    }
}

// MARK: - Content

private extension TangemPayResidencyCoordinatorView {
    @ViewBuilder
    var root: some View {
        if let geoStore = coordinator.geoStore {
            CountrySelectionFactory.makeView(
                store: geoStore,
                configuration: GeoSelectionConfiguration(
                    title: Localization.tangempayResidencyTitleCountry,
                    highlight: .suggested(
                        sectionTitle: Localization.tangempayResidencySuggestedCountry,
                        allSectionTitle: Localization.tangempayResidencyAllCountry
                    ),
                    showsBackButton: false
                ),
                loadingItemIdPublisher: coordinator.loadingItemIdPublisher,
                output: { [weak coordinator] in coordinator?.handle($0) }
            )
        }
    }

    @ViewBuilder
    func destination(_ route: TangemPayResidencyCoordinator.Route) -> some View {
        switch route {
        case .region(let countryCode):
            if let geoStore = coordinator.geoStore {
                RegionSelectionFactory.makeView(
                    store: geoStore,
                    countryCode: countryCode,
                    configuration: GeoSelectionConfiguration(
                        title: Localization.tangempayResidencyTitleState,
                        highlight: .suggested(
                            sectionTitle: Localization.tangempayResidencySuggestedState,
                            allSectionTitle: Localization.tangempayResidencyAllState
                        ),
                        showsBackButton: true
                    ),
                    loadingItemIdPublisher: coordinator.loadingItemIdPublisher,
                    output: { [weak coordinator] in coordinator?.handle($0) }
                )
            }

        case .unavailableRegion:
            TangemPayUnavailableRegionView(output: { [weak coordinator] in coordinator?.handle($0) })
                .topNavigation(
                    leading: .none,
                    onClose: { [weak coordinator] in coordinator?.close() }
                )
        }
    }

    @ViewBuilder
    var waitlist: some View {
        if let unavailableRegion = coordinator.unavailableRegion, let interactor = coordinator.interactor {
            NavigationStack {
                TangemPayWaitlistFactory.makeView(
                    product: coordinator.product,
                    country: unavailableRegion.country,
                    region: unavailableRegion.region,
                    service: interactor.waitlistService,
                    output: { [weak coordinator] in coordinator?.handle($0) }
                )
                .topNavigation(
                    leading: .none,
                    onClose: { [weak coordinator] in coordinator?.closeWaitlist() }
                )
            }
            .sheet(item: $coordinator.privacyPolicyViewModel) {
                WebViewContainer(viewModel: $0)
            }
        }
    }
}
