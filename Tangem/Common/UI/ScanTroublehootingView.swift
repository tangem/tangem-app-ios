//
//  ScanTroublehootingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanTroubleshootingView: View {

    @Binding var isPresented: Bool

    var tryAgainAction: () -> Void
    var requestSupportAction: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 0.5, height: 0.5)
            .actionSheet(isPresented: $isPresented, content: {
                ActionSheet(title: Text(L10n.alertTroubleshootingScanCardTitle),
                            message: Text(L10n.alertTroubleshootingScanCardMessage),
                            buttons: [
                                .default(Text(L10n.alertButtonTryAgain), action: tryAgainAction),
                                .default(Text(L10n.alertButtonRequestSupport), action: requestSupportAction),
                                .cancel(),
                            ])
            })
    }
}
