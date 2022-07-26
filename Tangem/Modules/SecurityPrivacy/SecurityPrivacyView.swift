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

    var firstSectionFooterTitle: String {
        if viewModel.isChangeAccessCodeVisible {
            return "security_and_privacy_change_access_code_footer".localized
        } else {
            return "security_and_privacy_security_mode_footer".localized
        }
    }

    var body: some View {
        List {
            securityModeSection
        }
        .listStyle(DefaultListStyle())
        .alert(item: $viewModel.alert) { $0.alert }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("security_and_privacy_title", displayMode: .inline)
    }

    private var securityModeSection: some View {
        Section(content: {
            DefaultRowView(
                title: "security_and_privacy_security_mode".localized,
                details: viewModel.securityModeTitle,
                isTappable: !viewModel.hasSingleSecurityMode,
                action: viewModel.openChangeAccessMethod
            )
            if viewModel.isChangeAccessCodeVisible {
                DefaultRowView(
                    title: "security_and_privacy_change_access_code".localized,
                    action: viewModel.openChangeAccessCode
                )
            }
        }, footer: {
            DefaultFooterView(title: firstSectionFooterTitle)
        })
    }
}
