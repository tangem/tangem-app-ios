//
//  YieldAvailableNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import SwiftUI

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
    enum State {
        case loading
        case available(apy: String)
        case unavailable

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }

        var title: String {
            switch self {
            case .available(let apy):
                return Localization.yieldModuleTokenDetailsEarnNotificationTitle(apy)
            case .loading:
                return Localization.yieldModuleTokenDetailsEarnNotificationTitle("0.0%")
            case .unavailable:
                return "Earnings unavailable"
            }
        }

        var description: String {
            switch self {
            case .available, .loading:
                return Localization.yieldModuleTokenDetailsEarnNotificationDescription
            case .unavailable:
                return "The interest service isn’t available at the moment. Please try again later."
            }
        }

        var icon: Image {
            switch self {
            case .unavailable, .loading:
                return Assets.YieldModule.yieldModuleLogoGray.image
            case .available:
                return Assets.YieldModule.yieldModuleLogo.image
            }
        }
    }
}
