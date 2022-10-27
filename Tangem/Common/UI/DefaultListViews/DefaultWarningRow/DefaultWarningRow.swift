//
//  DefaultWarningRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRow: View {
    private let viewModel: DefaultWarningRowViewModel

    init(viewModel: DefaultWarningRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.action) {
            HStack(alignment: .center, spacing: 12) {
                viewModel.icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Colors.Background.secondary)
                    .cornerRadius(40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .background(Colors.Background.primary)
            .contentShape(Rectangle())
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DefaultWarningRow_Preview: PreviewProvider {
    static let viewModel = DefaultWarningRowViewModel(
        icon: Assets.attention,
        title: "Enable biometric authentication",
        subtitle: "Go to settings to enable biometric authentication in the Tandem App",
        action: {}
    )

    static var previews: some View {
        DefaultWarningRow(viewModel: viewModel)
    }
}
