//
//  TangemPayOperationGate.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class TangemPayOperationGate {
    public enum Operation: Hashable {
        case issueCard
        case freeze(cardId: String)
        case unfreeze(cardId: String)
        case reissue(cardId: String)
        case rename(cardId: String)
        case setLimit(cardId: String)
    }

    private var inFlight: Set<Operation> = []
    private let lock = NSLock()

    public init() {}

    public func acquire(_ operation: Operation) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isBlocked(operation) else { return false }
        inFlight.insert(operation)
        return true
    }

    public func release(_ operation: Operation) {
        lock.lock()
        defer { lock.unlock() }
        inFlight.remove(operation)
    }

    public func isBusy(_ operation: Operation) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isBlocked(operation)
    }

    /// Caller must hold `lock`.
    private func isBlocked(_ operation: Operation) -> Bool {
        // Self-conflict: the identical operation is already in flight.
        if inFlight.contains(operation) { return true }
        // Cross-conflict: freeze/unfreeze/reissue on the same card are mutually exclusive.
        if let cardId = operation.lifecycleCardId {
            return inFlight.contains { $0.lifecycleCardId == cardId }
        }
        return false
    }
}

private extension TangemPayOperationGate.Operation {
    var lifecycleCardId: String? {
        switch self {
        case .freeze(let id), .unfreeze(let id), .reissue(let id):
            return id
        default:
            return nil
        }
    }
}
