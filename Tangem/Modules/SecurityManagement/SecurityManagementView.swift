//
//  SecurityManagementView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct SecurityManagementRowView: View {
    @Binding var selectedOption: SecurityManagementOption
    let option: SecurityManagementOption

    @EnvironmentObject var cardViewModel: CardViewModel // [REDACTED_TODO_COMMENT]

    var isEnabled: Bool {
        switch option {
        case .accessCode:
            return cardViewModel.canSetAccessCode
        case .longTap:
            return cardViewModel.canSetLongTap
        case .passCode:
            return cardViewModel.canSetPasscode
        }
    }

    var isSelected: Bool { selectedOption == option }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(option.title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                    .padding(.top, 16.0)
                    .padding([.bottom, .leading, .trailing], 8.0)
                    .opacity(isEnabled ? 1.0 : 0.5)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Font.system(size: 21.0, weight: .light, design: .default))
                    .foregroundColor(isSelected ? Color.tangemBlueLight : Color.tangemGrayLight4)
            }
            Text(option.subtitle)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(.tangemGrayDark)
                .padding([.top, .leading, .trailing], 8.0)
                .padding(.bottom, 26.0)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if self.isEnabled {
                self.selectedOption = self.option
            }
        }
        .overlay(isEnabled ? Color.clear : Color.white.opacity(0.4))
    }
}

struct SecurityManagementView: View {
    @ObservedObject var viewModel: SecurityManagementViewModel

    var body: some View {
        VStack {

            List {
                Section(content: {
                    ForEach(viewModel.cardViewModel.availableSecOptions) { option in
                        SecurityManagementRowView(selectedOption: self.$viewModel.selectedOption, option: option)
                            .environmentObject(self.viewModel.cardViewModel)
                    }
                }, footer: {
                    if viewModel.accessCodeDisclaimer != nil {
                        HStack(spacing: 0) {
                            Spacer()
                            Text(viewModel.accessCodeDisclaimer!)
                                .font(.body)
                                .foregroundColor(.tangemGrayDark)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                            Spacer()
                        }
                    } else {
                        EmptyView()
                    }
                })
            }
            .listRowInsets(EdgeInsets())
            .listStyle(GroupedListStyle())


            TangemButton(title: viewModel.selectedOption == .longTap ? "common_save_changes" : "common_continue") {
                self.viewModel.onTap()
            }.buttonStyle(TangemButtonStyle(colorStyle: .black,
                                            layout: .flexibleWidth,
                                            isDisabled: viewModel.isOptionDisabled,
                                            isLoading: viewModel.isLoading))
                .alert(item: $viewModel.error) { $0.alert }
                .padding(.horizontal, 16.0)
                .padding(.bottom, 16.0)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_manage_security_title", displayMode: .inline)
    }
}


struct SecurityManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityManagementView(viewModel: .init(cardModel: PreviewCard.tangemWalletEmpty.cardModel,
                                                coordinator: SecurityManagementCoordinator()))
    }
}
