//
//  SecurityManagementView.swift
//  Tangem Tap
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
    
    @EnvironmentObject var cardViewModel: CardViewModel
    
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
        VStack (alignment: .leading, spacing: 0) {
            HStack (alignment: .lastTextBaseline) {
                Text(option.title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark6)
                    .padding(.top, 16.0)
                    .padding([.bottom, .leading, .trailing], 8.0)
                    .opacity(isEnabled ? 1.0 : 0.5)
                Spacer()
                Image(isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Font.system(size: 21.0, weight: .light, design: .default))
                    .foregroundColor(isSelected ? Color.tangemTapBlueLight : Color.tangemTapGrayLight4)
            }
            Text(option.subtitle)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(.tangemTapGrayDark)
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
	@EnvironmentObject var navigation: NavigationCoordinator
    
    var body: some View {
        VStack {
            List(viewModel.secOptions) { option in
                SecurityManagementRowView(selectedOption: self.$viewModel.selectedOption,
                                          option: option)
                    .environmentObject(self.viewModel.cardViewModel)
            }
            .listStyle(PlainListStyle())
            
            HStack(alignment: .center, spacing: 8.0) {
                Spacer()
                TangemLongButton(isLoading: viewModel.isLoading,
                             title: viewModel.selectedOption == .longTap ? "common_save_changes" : "common_continue",
                             image: "save") {
                                self.viewModel.onTap()
                }.buttonStyle(TangemButtonStyle(color: .black,
                                                isDisabled: viewModel.selectedOption == viewModel.cardViewModel.currentSecOption))
                .alert(item: $viewModel.error) { $0.alert }
                .disabled(viewModel.selectedOption == viewModel.cardViewModel.currentSecOption)
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
			
			NavigationLink(destination: CardOperationView(title: viewModel.selectedOption.title,
														  alert: "details_security_management_warning".localized,
														  actionButtonPressed: viewModel.actionButtonPressedHandler),
						   isActive: $navigation.securityToWarning)
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_manage_security_title", displayMode: .inline)
    }
}


struct SecurityManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityManagementView(viewModel: Assembly.previewAssembly.makeSecurityManagementViewModel(with: CardViewModel.previewCardViewModel))
    }
}
