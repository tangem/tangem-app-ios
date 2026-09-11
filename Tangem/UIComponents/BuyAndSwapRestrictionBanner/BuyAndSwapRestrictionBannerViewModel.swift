//
//  BuyAndSwapRestrictionBannerViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class BuyAndSwapRestrictionBannerViewModel: ObservableObject {
    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService

    @Published private(set) var description = Localization.buySwapRegionRestrictionDescription

    /// The same code the app sends as `country` when asking for the token list, so the named region can never
    /// contradict the `restricted_for_country` flag the backend answered with.
    func resolveRegion() async {
        guard
            let code = await geoEligibilityService.fetchGeoIpRegionCode(),
            let name = Self.localizedRegionName(for: code)
        else {
            return
        }

        await runOnMain {
            self.description = Localization.buySwapRegionRestrictionDescriptionRegion(name)
        }
    }

    private static func localizedRegionName(for code: String) -> String? {
        Locale(identifier: Locale.appLanguageCode).localizedString(forRegionCode: code)
    }
}
