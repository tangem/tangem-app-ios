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

    func refresh()
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

    func load() {
        loadingTask = runTask(in: self) { provider in
            do {
                let geoblock = try await provider.geoblockService.geoblock()
                provider.subject.send(geoblock.isBlocked ? .blocked : .allowed)
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketLogger.error("Failed to read the region, trading is left allowed", error: error)
                provider.subject.send(.allowed)
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

    func refresh() {
        loadingTask?.cancel()
        load()
    }
}
