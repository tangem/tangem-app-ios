//
//  RegionSelectionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

@MainActor
final class RegionSelectionViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var state: LoadingResult<GeoSelectionSections, any Error> = .loading
    @Published private(set) var regions: [TangemPayGeoRegion] = []

    let configuration: GeoSelectionConfiguration

    private let store: TangemPayGeoStore
    private let countryCode: String
    private let output: (Output) -> Void

    init(
        store: TangemPayGeoStore,
        countryCode: String,
        configuration: GeoSelectionConfiguration,
        output: @escaping (Output) -> Void
    ) {
        self.store = store
        self.countryCode = countryCode
        self.configuration = configuration
        self.output = output

        bind()
        store.loadRegions(countryCode: countryCode)
    }

    func onItemTap(id: String) {
        guard let region = regions.first(where: {
            $0.code == id
        }) else {
            return
        }

        output(.selected(region))
    }

    func onRetryTap() {
        store.reloadRegions(countryCode: countryCode)
    }

    func onClose() {
        output(.closed)
    }
}

// MARK: - Output

extension RegionSelectionViewModel {
    enum Output {
        case selected(TangemPayGeoRegion)
        case closed
    }
}

// MARK: - Binding

private extension RegionSelectionViewModel {
    func bind() {
        let regionsPublisher = store.regionsPublisher(countryCode: countryCode)

        regionsPublisher
            .map { $0.value ?? [] }
            .receiveOnMain()
            .assign(to: &$regions)

        Publishers.CombineLatest(regionsPublisher, $searchText)
            .map { [configuration] state, searchText in
                state.mapValue { regions in
                    Self.makeSections(from: regions, searchText: searchText, configuration: configuration)
                }
            }
            .receiveOnMain()
            .assign(to: &$state)
    }

    static func makeSections(
        from regions: [TangemPayGeoRegion],
        searchText: String,
        configuration: GeoSelectionConfiguration
    ) -> GeoSelectionSections {
        let query = searchText.trimmed()

        let filtered = regions
            .filter { query.isEmpty || matches($0, query: query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let highlighted: TangemPayGeoRegion? = switch configuration.highlight {
        case .none: nil
        case .suggested: filtered.first(where: \.suggested)
        case .selected(let code, _, _): filtered.first { $0.code == code }
        }

        return GeoSelectionSections(
            highlighted: highlighted.map(makeItem(from:)),
            all: filtered.map(makeItem(from:))
        )
    }

    static func matches(_ region: TangemPayGeoRegion, query: String) -> Bool {
        region.name.caseInsensitiveContains(query) || subdivisionCode(of: region).caseInsensitiveHasPrefix(query)
    }

    static func subdivisionCode(of region: TangemPayGeoRegion) -> Substring {
        region.code.split(separator: "-").last ?? region.code[...]
    }

    static func makeItem(from region: TangemPayGeoRegion) -> GeoSelectionItem {
        GeoSelectionItem(id: region.code, title: region.name, flagURL: nil)
    }
}
