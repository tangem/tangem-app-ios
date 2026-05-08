//
//  SwapDisplayModeResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapDisplayModeResolver {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    private let appSettings: AppSettings

    init(appSettings: AppSettings = .shared) {
        self.appSettings = appSettings
    }

    var isAvailable: Bool {
        FeatureProvider.isAvailable(.swapSimpleMode)
    }

    func currentMode() -> SwapDisplayMode {
        guard isAvailable else { return .detailed }

        if let raw = appSettings.swapDisplayModeOverrideRaw, let override = SwapDisplayMode(rawValue: raw) {
            return override
        }

        let variantValue = experimentService.variant(.swapDisplayMode)?.value ?? ""
        return SwapDisplayMode(rawValue: variantValue) ?? .detailed
    }

    func setMode(_ mode: SwapDisplayMode) {
        guard isAvailable else { return }
        appSettings.swapDisplayModeOverrideRaw = mode.rawValue
    }
}
