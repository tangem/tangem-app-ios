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

    func makeTitle() -> String {
        switch state {
        case .available(let apy):
            return Localization.yieldModuleTokenDetailsEarnNotificationTitle(String(format: "%.1f", apy.doubleValue))
        case .loading:
            return Localization.yieldModuleTokenDetailsEarnNotificationTitle("0.0%")
        case .unavailable:
            // [REDACTED_TODO_COMMENT]
            return "Earnings unavailable"
        }
    }

    func makeDescription() -> String {
        switch state {
        case .available, .loading:
            return Localization.yieldModuleTokenDetailsEarnNotificationDescription
        case .unavailable:
            // [REDACTED_TODO_COMMENT]
            return "The interest service isn’t available at the moment. Please try again later."
        }
    }

    func makeIcon() -> Image {
        switch state {
        case .unavailable, .loading:
            return Assets.YieldModule.yieldModuleLogoGray.image
        case .available:
            return Assets.YieldModule.yieldModuleLogo.image
        }
    }

    func makeApyString(from apy: Decimal) -> String {
        String(format: "%.1f", apy.doubleValue)
    }

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
    enum State: Equatable {
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
    }
}
