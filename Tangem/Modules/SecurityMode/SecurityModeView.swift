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
                .font(.footnote)
                .foregroundColor(Colors.Text.tertiary)
        }
    }

    private var actionButton: some View {
        TangemButton(title: viewModel.currentSecurityOption.actionButtonTitle) { [weak viewModel] in
            viewModel?.actionButtonDidTap()
        }
        .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                       layout: .flexibleWidth,
                                       isDisabled: !viewModel.isActionButtonEnabled,
                                       isLoading: viewModel.isLoading))
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
                        .font(.body)
                        .foregroundColor(Colors.Text.primary1)

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
