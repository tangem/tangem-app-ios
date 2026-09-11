//
//  TangemPayPlasticCardMessageView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayPlasticCardMessageView: View {
    let stage: TangemPayPlasticCardStub.Stage
    let email: String?

    var body: some View {
        VStack(spacing: Constants.iconToTextSpacing) {
            DesignSystem.Icons.Clock.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .background(DesignSystem.Color.bgOpaquePrimary)
                .clipShape(Circle())

            message
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    private var message: some View {
        switch stage {
        case .delivering:
            Text(deliveryMessage)

        case .activating:
            VStack(spacing: Constants.titleToDescriptionSpacing) {
                Text(Localization.tangempayCardPageActivatingBannerTitle)
                Text(Localization.tangempayReissueCardInProgressDescription)
            }
        }
    }

    private var deliveryMessage: AttributedString {
        guard let email else {
            return AttributedString(Localization.tangempayCardDeliveryBannerTitle)
        }

        var text = AttributedString(Localization.tangempayCardDetailsDeliveryDescription(email))

        if let range = text.range(of: email) {
            text[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return text
    }
}

private extension TangemPayPlasticCardMessageView {
    enum Constants {
        static let iconSize: CGFloat = 40
        static let iconToTextSpacing: CGFloat = 12
        static let titleToDescriptionSpacing: CGFloat = 4
        /// On top of the screen's own 16pt gutter this lands the text at the 48pt inset the design asks for.
        static let horizontalPadding: CGFloat = 32
    }
}
