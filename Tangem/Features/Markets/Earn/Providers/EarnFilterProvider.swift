//
//  EarnFilterProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct EarnFilter {
    let network: EarnNetworkFilterType
    let type: EarnTypeFilterType
}

class EarnFilterProvider {
    // MARK: - Private Properties

    private let _networkFilter: CurrentValueSubject<EarnNetworkFilterType, Never>
    private let _typeFilter: CurrentValueSubject<EarnTypeFilterType, Never>

    // MARK: - Initialization

    init() {
        _networkFilter = .init(.all)
        _typeFilter = .init(.all)
    }

    // MARK: - Public Properties

    var filterPublisher: some Publisher<EarnFilter, Never> {
        Publishers.CombineLatest(_networkFilter, _typeFilter)
            .map { network, type in
                EarnFilter(network: network, type: type)
            }
    }

    var currentFilterValue: EarnFilter {
        EarnFilter(network: _networkFilter.value, type: _typeFilter.value)
    }

    var supportedNetworks: [EarnNetworkFilterType] {
        EarnNetworkFilterType.presetCases
    }

    var supportedTypes: [EarnTypeFilterType] {
        EarnTypeFilterType.allCases
    }

    // MARK: - Public Methods

    func didSelectNetwork(_ network: EarnNetworkFilterType) {
        _networkFilter.send(network)
    }

    func didSelectType(_ type: EarnTypeFilterType) {
        _typeFilter.send(type)
    }
}
