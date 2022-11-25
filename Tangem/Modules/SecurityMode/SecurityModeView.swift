//
//  SecurityModeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityModeView: View {
    @ObservedObject var viewModel: SecurityModeViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            list

            actionButton
        }
        .alert(item: $viewModel.error) { $0.alert }
        .navigationBarTitle("details_manage_security_title", displayMode: .inline)
    }

    private var list: some View {
        List(viewModel.availableSecurityOptions) { option in
            section(for: option)
        }
        .listStyle(DefaultListStyle())
    }

    private func section(for option: SecurityModeOption) -> some View {
        Section {
            RowView(
                title: option.title,
                isSelected: viewModel.isSelected(option: option)
            )
        } footer: {
            Text(option.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var actionButton: some View {
        MainButton(
            text: "common_save_changes".localized,
            icon: .trailing(Assets.tangemIconWhite),
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.isActionButtonEnabled,
            action: viewModel.actionButtonDidTap
        )
        .padding(16)
    }
}

extension SecurityModeView {
    struct RowView: View {
        let title: String

        @Binding var isSelected: Bool

        var body: some View {
            Button(action: { isSelected.toggle() }) {
                HStack {
                    Text(title)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(isSelected ? Colors.Text.accent : Colors.Background.secondary)
                }
                .lineLimit(1)
            }
        }
    }
}

struct SecurityModeView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityModeView(viewModel: .init(cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                                          coordinator: SecurityModeCoordinator()))
    }
}
