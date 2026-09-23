//
//  TangemPayOfframpGeoSelectionCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemPay

struct TangemPayOfframpGeoSelectionCoordinatorView: View {
    let store: TangemPayGeoStore
    let start: Start
    let output: (Output) -> Void

    @State private var path: [Route] = []
    @State private var pendingCountry: TangemPayGeoCountry?

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: Route.self, destination: destination)
        }
    }
}

// MARK: - Start

extension TangemPayOfframpGeoSelectionCoordinatorView {
    enum Start {
        case country(selectedCountryCode: String?, selectedRegionCode: String?)
        case region(countryCode: String, selectedCode: String?)
    }
}

// MARK: - Output

extension TangemPayOfframpGeoSelectionCoordinatorView {
    enum Output {
        case country(TangemPayGeoCountry)
        case countryWithRegion(country: TangemPayGeoCountry, region: TangemPayGeoRegion)
        case region(TangemPayGeoRegion)
        case closed
    }
}

// MARK: - Route

extension TangemPayOfframpGeoSelectionCoordinatorView {
    enum Route: Hashable {
        case region(countryCode: String, selectedCode: String?)
    }
}

// MARK: - Content

private extension TangemPayOfframpGeoSelectionCoordinatorView {
    @ViewBuilder
    var root: some View {
        switch start {
        case .country(let selectedCountryCode, _):
            CountrySelectionFactory.makeView(
                store: store,
                configuration: countryConfiguration(selectedCode: selectedCountryCode),
                output: handle(_:)
            )

        case .region(let countryCode, let selectedCode):
            regionView(countryCode: countryCode, selectedCode: selectedCode, showsBackButton: false)
        }
    }

    func destination(_ route: Route) -> some View {
        switch route {
        case .region(let countryCode, let selectedCode):
            regionView(countryCode: countryCode, selectedCode: selectedCode, showsBackButton: true)
        }
    }

    func regionView(countryCode: String, selectedCode: String?, showsBackButton: Bool) -> some View {
        RegionSelectionFactory.makeView(
            store: store,
            countryCode: countryCode,
            configuration: regionConfiguration(selectedCode: selectedCode, showsBackButton: showsBackButton),
            output: handle(_:)
        )
    }
}

// MARK: - Routing

private extension TangemPayOfframpGeoSelectionCoordinatorView {
    func handle(_ output: CountrySelectionViewModel.Output) {
        switch output {
        case .selected(let country):
            guard country.code == Constants.regionSelectionCountryCode else {
                self.output(.country(country))
                return
            }

            pendingCountry = country
            path.append(.region(countryCode: country.code, selectedCode: regionCode(for: country)))

        case .closed:
            self.output(.closed)
        }
    }

    func handle(_ output: RegionSelectionViewModel.Output) {
        switch output {
        case .selected(let region):
            if let pendingCountry {
                self.output(.countryWithRegion(country: pendingCountry, region: region))
            } else {
                self.output(.region(region))
            }

        case .closed:
            self.output(.closed)
        }
    }

    func regionCode(for country: TangemPayGeoCountry) -> String? {
        guard case .country(let selectedCountryCode, let selectedRegionCode) = start else {
            return nil
        }

        return country.code == selectedCountryCode ? selectedRegionCode : nil
    }
}

// MARK: - Configurations

private extension TangemPayOfframpGeoSelectionCoordinatorView {
    func countryConfiguration(selectedCode: String?) -> GeoSelectionConfiguration {
        GeoSelectionConfiguration(
            title: Localization.tangempayOrderDataCountry,
            highlight: selectedCode.map {
                .selected(
                    code: $0,
                    sectionTitle: Localization.tangempayWithdrawBankGeoCountrySelected,
                    allSectionTitle: Localization.tangempayResidencyAllCountry
                )
            },
            showsBackButton: false
        )
    }

    func regionConfiguration(selectedCode: String?, showsBackButton: Bool) -> GeoSelectionConfiguration {
        GeoSelectionConfiguration(
            title: Localization.tangempayWithdrawBankGeoStateTitle,
            highlight: selectedCode.map {
                .selected(
                    code: $0,
                    sectionTitle: Localization.tangempayWithdrawBankGeoStateSelected,
                    allSectionTitle: Localization.tangempayResidencyAllState
                )
            },
            showsBackButton: showsBackButton
        )
    }
}

// MARK: - Constants

private extension TangemPayOfframpGeoSelectionCoordinatorView {
    enum Constants {
        static let regionSelectionCountryCode = "US"
    }
}
