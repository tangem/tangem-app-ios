//
//  FeedReferralWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization

struct FeedReferralWidgetView: View {
    let reward: LoadingResult<String, FeedWidget.LoadError>

    var body: some View {
        FeedLoadableWidgetView(state: reward) { amount in
            FeedProductCardView(
                caption: Localization.feedPromoReferralTitle,
                message: Localization.feedPromoReferralDescription(amount),
                appearance: .referral
            )
        }
    }
}
