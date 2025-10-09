//
//  RowWithLeadingAndTrailingIcons.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct RowWithLeadingAndTrailingIcons<LeadingIcon: View, Content: View, TrailingIcon: View>: View {
    private let leadingIcon: LeadingIcon
    private let content: Content
    private let trailingIcon: TrailingIcon

    public init(
        @ViewBuilder leadingIcon: () -> LeadingIcon,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailingIcon: () -> TrailingIcon
    ) {
        self.leadingIcon = leadingIcon()
        self.content = content()
        self.trailingIcon = trailingIcon()
    }

    public var body: some View {
        HStack(spacing: 12) {
            leadingIcon

            content

            Spacer()

            trailingIcon
        }
    }
}
