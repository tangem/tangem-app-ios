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
    func fetchAvailability() async {}

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
