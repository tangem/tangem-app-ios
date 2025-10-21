//
//  YieldAvailableNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import SwiftUI
import TangemAssets

final class YieldAvailableNotificationViewModel: ObservableObject {
    // MARK: - Published

    @Published
    private(set) var state: State = .loading

    // MARK: - Properties

    private var apy: Decimal?
    private let onButtonTap: (Decimal) -> Void

    // MARK: - Dependencies

    private let yieldModuleManager: YieldModuleManager

    // MARK: - Init

    init(state: State, yieldModuleManager: YieldModuleManager, onButtonTap: @escaping (Decimal) -> Void) {
        self.state = state
        self.yieldModuleManager = yieldModuleManager
        self.onButtonTap = onButtonTap

        start()
    }

    // MARK: - Public Implementation

    func onGetStartedTap() {
        if let apy {
            onButtonTap(apy)
        }
    }

    // MARK: - Private Implementation

    private func start() {
        switch state {
        case .available(let apy):
            self.apy = apy

        case .loading:
            fetchApy()

        case .unavailable:
            break
        }
    }

    private func fetchApy() {
        guard case .loading = state else { return }

        Task { @MainActor [weak self, yieldModuleManager] in
            do {
                let tokenInfo = try await yieldModuleManager.fetchYieldTokenInfo()
                self?.apy = tokenInfo.apy
                self?.state = .available(apy: tokenInfo.apy)
            } catch {
                self?.state = .unavailable
            }
        }
    }
}

extension YieldAvailableNotificationViewModel {
    enum State {
        case loading
        case available(apy: Decimal)
        case unavailable

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }

        var title: String {
            switch self {
            case .available(let apy):
                return Localization.yieldModuleTokenDetailsEarnNotificationTitle(apy)
            case .loading:
                return Localization.yieldModuleTokenDetailsEarnNotificationTitle("0.0%")
            case .unavailable:
                return Localization.yieldModuleUnavailableTitle
            }
        }

        var description: String {
            switch self {
            case .available, .loading:
                return Localization.yieldModuleTokenDetailsEarnNotificationDescription
            case .unavailable:
                return Localization.yieldModuleUnavailableSubtitle
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
