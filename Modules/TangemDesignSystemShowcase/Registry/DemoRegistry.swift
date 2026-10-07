//
//  DemoRegistry.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

@MainActor
public enum DemoRegistry {
    public static var entries: [DemoEntry] {
        #if INTERNAL || DEBUG
        ds3 + legacy
        #else
        []
        #endif
    }
}

#if INTERNAL || DEBUG
private extension DemoRegistry {
    static var ds3: [DemoEntry] {
        [
            DemoEntry("Badge", version: DSVersion(1, 0, 0), section: .ds3) { BadgeShowcase() },
            DemoEntry("Button", version: DSVersion(1, 2, 0), section: .ds3) { ButtonShowcase() },
            DemoEntry("Checkbox", version: DSVersion(1, 0, 0), section: .ds3) { CheckboxShowcase() },
            DemoEntry("Checkmark", version: DSVersion(1, 0, 0), section: .ds3) { CheckmarkShowcase() },
            DemoEntry("Fade", version: DSVersion(1, 1, 0), section: .ds3) { FadeShowcase() },
            DemoEntry("FilterGroup", version: DSVersion(1, 0, 0), section: .ds3) { FilterGroupShowcase() },
            DemoEntry("GlowRing", version: DSVersion(1, 1, 0), section: .ds3) { GlowRingShowcase() },
            DemoEntry("Loader", version: DSVersion(1, 0, 0), section: .ds3) { LoaderShowcase() },
            DemoEntry("MessageBanner", version: DSVersion(1, 2, 0), section: .ds3) { MessageBannerShowcase() },
            DemoEntry("MessageBubble", version: DSVersion(1, 1, 0), section: .ds3) { MessageBubbleShowcase() },
            DemoEntry("Row", version: DSVersion(1, 0, 0), section: .ds3) { RowShowcase() },
            DemoEntry("Search", version: DSVersion(1, 0, 0), section: .ds3) { SearchShowcase() },
            DemoEntry("SegmentedControl", version: DSVersion(1, 0, 0), section: .ds3) { SegmentedControlShowcase() },
            DemoEntry("Shimmer", version: DSVersion(1, 0, 0), section: .ds3) { ShimmerShowcase() },
            DemoEntry("Shtorka", version: DSVersion(1, 0, 0), section: .ds3) { ShtorkaShowcase() },
            DemoEntry("StatusScreen", version: DSVersion(1, 0, 0), section: .ds3) { StatusScreenShowcase() },
            DemoEntry("TabNavigation", version: DSVersion(1, 0, 0), section: .ds3) { TabNavigationShowcase() },
            DemoEntry("TokenIconV2", version: DSVersion(1, 1, 0), section: .ds3) { TokenIconV2Showcase() },
            DemoEntry("TokenRow", version: DSVersion(1, 1, 0), section: .ds3) { TokenRowShowcase() },
            DemoEntry("TokenRowMarket", version: DSVersion(1, 1, 0), section: .ds3) { TokenRowMarketShowcase() },
            DemoEntry("TopNavigation", version: DSVersion(1, 2, 0), section: .ds3) { TopNavigationShowcase() },
            DemoEntry("Typography", section: .ds3) { TypographyShowcase() },
            DemoEntry("UtilBalance", version: DSVersion(1, 0, 0), section: .ds3) { UtilBalanceShowcase() },
            DemoEntry("UtilGraph", version: DSVersion(1, 0, 0), section: .ds3) { UtilGraphShowcase() },
            DemoEntry("UtilPriceChange", version: DSVersion(1, 0, 0), section: .ds3) { UtilPriceChangeShowcase() },
        ]
    }

    static var legacy: [DemoEntry] {
        [
            DemoEntry("MainActionButton", section: .legacy) { TangemMainActionButtonShowcase() },
            DemoEntry("NotificationBanner", section: .legacy) { NotificationBannerShowcase() },
            DemoEntry("TangemBadge", section: .legacy) { TangemBadgeShowcase() },
            DemoEntry("TangemButton", section: .legacy) { TangemButtonShowcase() },
            DemoEntry("TangemCallout", section: .legacy) { TangemCalloutShowcase() },
            DemoEntry("TangemDropDown", section: .legacy) { TangemDropDownShowcase() },
            DemoEntry("TangemSearchField", section: .legacy) { TangemSearchFieldShowcase() },
            DemoEntry("TangemSegmentedPicker", section: .legacy) { TangemSegmentedPickerShowcase() },
            DemoEntry("TangemSnackbar", section: .legacy) { TangemSnackbarShowcase() },
            DemoEntry("TangemTabs", section: .legacy) { TangemTabsShowcase() },
            DemoEntry("TangemTokenRow", section: .legacy) { TangemTokenRowShowcase() },
            DemoEntry("Typography", section: .legacy) { LegacyTypographyShowcase() },
        ]
    }
}
#endif
