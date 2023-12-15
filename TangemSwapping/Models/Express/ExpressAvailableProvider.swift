//
//  ExpressAvailableProvider.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public class ExpressAvailableProvider {
    public let provider: ExpressProvider
    public var isBest: Bool
    public var isAvailable: Bool
    public let manager: ExpressProviderManager

    init(provider: ExpressProvider, isBest: Bool, isAvailable: Bool, manager: ExpressProviderManager) {
        self.provider = provider
        self.isBest = isBest
        self.isAvailable = isAvailable
        self.manager = manager
    }

    public func getState() async -> ExpressProviderManagerState {
        await manager.getState()
    }

    public func getPriority() async -> Priority {
        if isBest {
            return .highest
        }

        switch await getState() {
        case .permissionRequired, .preview, .ready:
            return .high
        case .idle, .restriction(.tooSmallAmount, _):
            return .medium
        case .restriction:
            return .low
        case .error:
            return .lowest
        }
    }
}

public extension ExpressAvailableProvider {
    enum Priority: Int, Comparable {
        case lowest
        case low
        case medium
        case high
        case highest

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
