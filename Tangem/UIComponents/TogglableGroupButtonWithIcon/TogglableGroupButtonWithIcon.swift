//
//  TogglableGroupButtonWithIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
public struct TogglableGroupButtonWithIcon: View {
    public var body: some View {
        HStack {
            byBalanceButton

            groupButton
        }
    }

    private var byBalanceButton: some View {
        FlexyButtonWithLeadingIcon(
            title: Localization.buttonTitleByBalance,
            icon: Assets.byBalance.image
        ) {}
    }

    private var groupButton: some View {
        FlexyButtonWithLeadingIcon(
            title: Localization.buttonTitleGroup,
            icon: Assets.group.image
        ) {}
    }
}

public struct TogglableGroupButtonWithIcon_Previews: PreviewProvider {
    public static var previews: some View {
        TogglableGroupButtonWithIcon()
    }
}
