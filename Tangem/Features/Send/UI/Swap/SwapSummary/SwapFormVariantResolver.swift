//
//  SwapFormVariantResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapFormVariantResolver {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    private let appSettings: AppSettings

    init(appSettings: AppSettings = .shared) {
        self.appSettings = appSettings
    }

    func currentVariant() -> SwapFormVariant {
        if let raw = appSettings.swapFormVariantOverrideRaw, let override = SwapFormVariant(rawValue: raw) {
            return override
        }

        let variantValue = experimentService.variant(.swapFormVariant)?.value ?? ""
        return SwapFormVariant(rawValue: variantValue) ?? .detailed
    }

    func setVariant(_ variant: SwapFormVariant) {
        appSettings.swapFormVariantOverrideRaw = variant.rawValue
    }
}
