//
//  ScanCardWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanCardWarningView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            icon

            VStack(alignment: .leading, spacing: 2) {
                Text("main_scan_card_warning_view_title".localized)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text("main_scan_card_warning_view_subtitle".localized)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }

            Assets.chevron
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var icon: some View {
        ZStack(alignment: .topTrailing) {
            Assets.scanCardIcon

            Circle()
                .fill(Colors.Text.attention)
                .padding(3)
                .background(Colors.Background.primary)
                .frame(width: 12, height: 12)
                .cornerRadius(6)
        }
    }
}

struct ScanCardWarningView_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            ScanCardWarningView()
                .padding()
        }
    }
}
