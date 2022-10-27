//
//  CardSettingsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardSettingsView: View {
    @ObservedObject var viewModel: CardSettingsViewModel

    var firstSectionFooterTitle: String {
        if viewModel.isChangeAccessCodeVisible {
            return "card_settings_change_access_code_footer".localized
        } else {
            return "card_settings_security_mode_footer".localized
        }
    }

    var body: some View {
        List {
            cardInfoSection

            securityModeSection

            if viewModel.isResetToFactoryAvailable {
                resetToFactorySection
            }
        }
        .groupedListStyleCompatibility(background: Colors.Background.secondary)
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitle("card_settings_title", displayMode: .inline)
    }

    private var cardInfoSection: some View {
        Section(content: {
            DefaultRowView(
                title: "details_row_title_cid".localized,
                detailsType: .text(viewModel.cardId)
            )

            DefaultRowView(
                title: "details_row_title_issuer".localized,
                detailsType: .text(viewModel.cardIssuer)
            )

            DefaultRowView(
                title: "details_row_title_signed_hashes".localized,
                detailsType: .text("details_row_subtitle_signed_hashes_format".localized(viewModel.cardSignedHashes))
            )
        })
    }

    private var securityModeSection: some View {
        Section(content: {
            DefaultRowView(
                title: "card_settings_security_mode".localized,
                detailsType: .text(viewModel.securityModeTitle),
                action: viewModel.hasSingleSecurityMode ? nil : viewModel.openSecurityMode
            )

            if viewModel.isChangeAccessCodeVisible {
                DefaultRowView(
                    title: "card_settings_change_access_code".localized,
                    detailsType: viewModel.isChangeAccessCodeLoading ? .loader : .none,
                    action: viewModel.openChangeAccessCodeWarningView
                )
            }
        }, footer: {
            DefaultFooterView(title: firstSectionFooterTitle)
        })
    }

    private var resetToFactorySection: some View {
        Section(content: {
            DefaultRowView(
                title: "card_settings_reset_card_to_factory".localized,
                action: viewModel.openResetCard
            )
        }, footer: {
            DefaultFooterView(title: "card_settings_reset_card_to_factory_footer".localized)
        })
    }
}
