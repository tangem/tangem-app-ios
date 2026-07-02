//
//  AddressBooksEmptyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AddressBooksEmptyView: View {
    let onAddContactTap: () -> Void

    @ScaledMetric private var iconContainerSize: CGFloat = 80
    @ScaledMetric private var iconSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 32) {
                icon

                VStack(spacing: 8) {
                    Text(Localization.addressBookNoContacts)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(Localization.addressBookNoContactsDescription)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            addContactButton
        }
        .frame(maxWidth: .infinity)
    }

    private var icon: some View {
        DesignSystem.Color.bgStatusInfoSubtle
            .frame(width: iconContainerSize, height: iconContainerSize)
            .overlay {
                // [REDACTED_TODO_COMMENT]
                DesignSystem.Icons.AddressPolygon.regular20.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(DesignSystem.Color.iconStatusInfo)
            }
            .clipShape(Circle())
    }

    private var addContactButton: some View {
        TangemButton(
            content: .combined(
                text: AttributedString(Localization.addressBookAddContact),
                icon: DesignSystem.Icons.SignPlus.regular20,
                iconPosition: .right
            ),
            action: onAddContactTap
        )
        .setStyleType(.primary)
        .setCornerStyle(.rounded)
        .setSize(.x10)
        .setHorizontalLayout(.intrinsic)
    }
}

// MARK: - Previews

#if DEBUG
struct AddressBooksEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        AddressBooksEmptyView(onAddContactTap: {})
            .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
    }
}
#endif // DEBUG
