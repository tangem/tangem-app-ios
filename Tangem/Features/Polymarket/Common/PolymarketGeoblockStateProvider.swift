//
//  PolymarketGeoblockStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

protocol PolymarketGeoblockStateProvider: AnyObject {
    var state: PolymarketGeoblockState { get }
    var statePublisher: AnyPublisher<PolymarketGeoblockState, Never> { get }
}

final class CommonPolymarketGeoblockStateProvider {
    private let geoblockService: PolymarketGeoblockService
    private let subject = CurrentValueSubject<PolymarketGeoblockState, Never>(.unknown)

    private var loadingTask: Task<Void, Never>?

    init(geoblockService: PolymarketGeoblockService) {
        self.geoblockService = geoblockService

        load()
    }

    deinit {
        loadingTask?.cancel()
    }

    private func load() {
        loadingTask = runTask(in: self) { provider in
            do {
                let geoblock = try await provider.geoblockService.geoblock()
                provider.subject.send(geoblock.isBlocked ? .blocked : .allowed)
            } catch {
                PolymarketLogger.error("Failed to read the region, treating it as blocked", error: error)
                provider.subject.send(.blocked)
            }
        }
    }
}

// MARK: - PolymarketGeoblockStateProvider protocol conformance

extension CommonPolymarketGeoblockStateProvider: PolymarketGeoblockStateProvider {
    var state: PolymarketGeoblockState {
        subject.value
    }

    var statePublisher: AnyPublisher<PolymarketGeoblockState, Never> {
        subject.eraseToAnyPublisher()
    }
}
