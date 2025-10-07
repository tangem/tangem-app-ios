//
//  YieldAvailableNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class YieldAvailableNotificationViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var state: State = .loading

    // MARK: - Properties

    private var apy: Decimal?
    private let onButtonTap: (String) -> Void

    // MARK: - Dependencies

    private let yieldModuleManager: YieldModuleManager

    // MARK: - Init

    init(yieldModuleManager: YieldModuleManager, onButtonTap: @escaping (String) -> Void) {
        self.yieldModuleManager = yieldModuleManager
        self.onButtonTap = onButtonTap
    }

    // MARK: - Public Implementation

    @MainActor
    func fetchAvailability() async {
        state = .loading

        try! await Task.sleep(nanoseconds: 1_500_000_000)

        do {
            let tokenInfo = try await yieldModuleManager.getYieldTokenInfo()

            guard tokenInfo.isActive else {
                state = .unavailable
                return
            }

            apy = tokenInfo.apy
            state = .available(apy: "\(tokenInfo.apy)")
        } catch {
            state = .unavailable
        }
    }

    func onGetStartedTap() {
        if let apy {
            onButtonTap("\(apy)")
        }
    }
}

extension YieldAvailableNotificationViewModel {
    enum State: Equatable, Identifiable {
        case loading
        case available(apy: String)
        case unavailable

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }

        var id: String {
            switch self {
            case .loading:
                "loading"
            case .available:
                "available"
            case .unavailable:
                "unavailable"
            }
        }
    }
}
