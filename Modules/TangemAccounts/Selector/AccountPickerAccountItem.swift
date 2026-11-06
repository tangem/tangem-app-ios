//
//  AccountPickerAccountItem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct AccountPickerAccountItem: Identifiable {
    public let id: AnyHashable
    public let name: String
    public let icon: AccountIconView.ViewData
    public let badge: String?
    public let subtitle: String?
    public let balance: SelectorBalance?
    public let availability: SelectorAvailability
    public let isSelected: Bool

    public init(
        id: AnyHashable,
        name: String,
        icon: AccountIconView.ViewData,
        badge: String?,
        subtitle: String?,
        balance: SelectorBalance?,
        availability: SelectorAvailability,
        isSelected: Bool
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.badge = badge
        self.subtitle = subtitle
        self.balance = balance
        self.availability = availability
        self.isSelected = isSelected
    }
}
