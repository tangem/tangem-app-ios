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
            DemoEntry("Badge", section: .ds3) { BadgeShowcase() },
            DemoEntry("Button", section: .ds3) { ButtonShowcase() },
            DemoEntry("Checkbox", section: .ds3) { CheckboxShowcase() },
            DemoEntry("Checkmark", section: .ds3) { CheckmarkShowcase() },
            DemoEntry("Fade", section: .ds3) { FadeShowcase() },
            DemoEntry("FilterGroup", section: .ds3) { FilterGroupShowcase() },
            DemoEntry("GlowRing", section: .ds3) { GlowRingShowcase() },
            DemoEntry("Loader", section: .ds3) { LoaderShowcase() },
            DemoEntry("MessageBanner", section: .ds3) { MessageBannerShowcase() },
            DemoEntry("MessageBubble", section: .ds3) { MessageBubbleShowcase() },
            DemoEntry("Row", section: .ds3) { RowShowcase() },
            DemoEntry("Search", section: .ds3) { SearchShowcase() },
            DemoEntry("SegmentedControl", section: .ds3) { SegmentedControlShowcase() },
            DemoEntry("Shimmer", section: .ds3) { ShimmerShowcase() },
            DemoEntry("Shtorka", section: .ds3) { ShtorkaShowcase() },
            DemoEntry("StatusScreen", section: .ds3) { StatusScreenShowcase() },
            DemoEntry("TabNavigation", section: .ds3) { TabNavigationShowcase() },
            DemoEntry("TokenIconV2", section: .ds3) { TokenIconV2Showcase() },
            DemoEntry("TokenRow", section: .ds3) { TokenRowShowcase() },
            DemoEntry("TokenRowMarket", section: .ds3) { TokenRowMarketShowcase() },
            DemoEntry("TopNavigation", section: .ds3) { TopNavigationShowcase() },
            DemoEntry("Typography", section: .ds3) { TypographyShowcase() },
            DemoEntry("UtilBalance", section: .ds3) { UtilBalanceShowcase() },
            DemoEntry("UtilGraph", section: .ds3) { UtilGraphShowcase() },
            DemoEntry("UtilPriceChange", section: .ds3) { UtilPriceChangeShowcase() },
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
