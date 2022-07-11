//
//  SecurityPrivacyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SecurityPrivacyView: View {
    @ObservedObject var viewModel: SecurityPrivacyViewModel
    
    var body: some View {
        List {
            securitySection
            
            privacySection
        }
        .listStyle(GroupedListStyle())
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("security_and_privacy_title", displayMode: .inline)
    }
    
    private var securitySection: some View {
        Section(content: {
            RowView(title: "security_and_privacy_change_password".localized,
                    action: viewModel.openChangePassword)
            
            RowView(title: "security_and_privacy_security_management".localized,
                    action: viewModel.openSecurityManagement)
        }, header: {
            HeaderView(title: "security_and_privacy_security".localized)
        })
    }

    private var privacySection: some View {
        Section(content: {
            RowView(title: "security_and_privacy_token_list_synchronization".localized,
                    action: viewModel.openTokenSynchronization)
            
            RowView(title: "security_and_privacy_saved_card_reset".localized,
                    action: viewModel.openResetSavedCards)
        }, header: {
            HeaderView(title: "security_and_privacy_privacy".localized)
        })
    }
}

private extension SecurityPrivacyView {
    struct HeaderView: View {
        let title: String
        
        var body: some View {
            Text(title)
                .font(.headline)
                .foregroundColor(.tangemBlue)
        }
    }
    
    struct RowView: View {
        let title: String
        let action: () -> Void
        
        var body: some View {
            HStack {
                Button(title, action: action)
                    .font(.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                
                Spacer()
                
                Image("chevron")
            }
        }
    }
}
