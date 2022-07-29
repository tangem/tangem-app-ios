//
//  DetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct DetailsView: View {
    private enum NavigationTag: String {
        case currency
        case disclaimer
        case cardTermsOfUse
        case securityManagement
        case walletConnect
        case resetToFactory
        case supportChat
    }

    @ObservedObject var viewModel: DetailsViewModel

    /// Change to @AppStorage and move to model with IOS 14.5 minimum deployment target
    @AppStorageCompat(StorageType.selectedCurrencyCode)
    private var selectedCurrencyCode: String = "USD"

    // fix remain highlited bug on ios14
    @State private var selection: NavigationTag? = nil

    var body: some View {
        List {
            cardDetailsSection

            applicationDetailsSection

            Section(header: Color.tangemBgGray.listRowInsets(EdgeInsets())) {
                EmptyView()
            }
        }
        .listStyle(GroupedListStyle())
        .alert(item: $viewModel.error) { $0.alert }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
        .onDisappear {
            if #available(iOS 14.5, *) { } else {
                if #available(iOS 14.3, *) {
                    // remains selection fix from 14.3 to 14.5
                    self.selection = nil
                }
            }
        }
    }

    // MARK: First Section

    private var cardDetailsSection: some View {
        Section(header: HeaderView(text: "details_section_title_card".localized), footer: footerView) {
            DetailsRowView(title: "details_row_title_cid".localized,
                           subtitle: viewModel.cardCid)
            DetailsRowView(title: "details_row_title_issuer".localized,
                           subtitle: viewModel.cardModel.cardInfo.card.issuer.name)

            if viewModel.hasWallet, !viewModel.isTwinCard {
                DetailsRowView(
                    title: "details_row_title_signed_hashes".localized,
                    subtitle: String(
                        format: "details_row_subtitle_signed_hashes_format".localized,
                        "\(viewModel.cardModel.cardInfo.card.walletSignedHashes)"
                    )
                )
            }

            cardSettingsRow

            if viewModel.isTwinCard {
                twinCardRecreateView

            } else {
                if viewModel.canCreateBackup {
                    createBackupRow
                }

                resetToFactoryRow
            }
        }
    }

    var footerView: some View {
        if let purgeWalletProhibitedDescription = viewModel.cardModel.purgeWalletProhibitedDescription {
            return FooterView(text: purgeWalletProhibitedDescription)
        }

        return FooterView()
    }

    // MARK: Twin Card Recreate

    private var twinCardRecreateView: some View {
        Button(action: viewModel.prepareTwinOnboarding, label: {
            Text("details_row_title_twins_recreate")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(viewModel.cardModel.canRecreateTwinCard ? .tangemGrayDark6 : .tangemGrayDark)
        })
        .disabled(!viewModel.cardModel.canRecreateTwinCard)
    }

    // MARK: Backup row

    private var createBackupRow: some View {
        Button(action: viewModel.prepareBackup, label: {
            Text("details_row_title_create_backup")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(viewModel.canCreateBackup ? .tangemGrayDark6 : .tangemGrayDark)
        })
        .disabled(!viewModel.canCreateBackup)
    }

    // MARK: Reset row

    @ViewBuilder
    private var resetToFactoryRow: some View {
        DetailsRowView(title: "details_row_title_reset_factory_settings".localized, subtitle: "")
            .onNavigation(viewModel.openResetToFactory,
                          tag: NavigationTag.resetToFactory,
                          selection: $selection)
            .disabled(!viewModel.cardModel.canPurgeWallet)
    }

    // MARK: SecurityMode

    private var cardSettingsRow: some View {
        HStack {
            Text("details_row_title_card_settings")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.tangemGrayDark6)

            Spacer()
        }
        .onNavigation(viewModel.openCardSettings,
                      tag: NavigationTag.securityManagement,
                      selection: $selection)
    }

    // MARK: Second Section

    private var applicationDetailsSection: some View {
        Section(header: HeaderView(text: "details_section_title_app".localized), footer: FooterView()) {
            if !viewModel.isMultiWallet {
                DetailsRowView(title: "details_row_title_currency".localized,
                               subtitle: selectedCurrencyCode)
                    .onNavigation(viewModel.openCurrencySelection,
                                  tag: NavigationTag.currency,
                                  selection: $selection)
            }

            DetailsRowView(title: "disclaimer_title".localized, subtitle: "")
                .onNavigation(viewModel.openDisclaimer,
                              tag: NavigationTag.disclaimer,
                              selection: $selection)

            Button(action: viewModel.openMail, label: {
                Text("details_row_title_send_feedback".localized)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
            })

            if viewModel.cardTouURL != nil {
                DetailsRowView(title: "details_row_title_card_tou".localized, subtitle: "")
                    .onNavigation(viewModel.openCatdTOU,
                                  tag: NavigationTag.cardTermsOfUse,
                                  selection: $selection)
            }

            if viewModel.shouldShowWC {
                DetailsRowView(title: "WalletConnect", subtitle: "")
                    .onNavigation(viewModel.openWalletConnect,
                                  tag: NavigationTag.walletConnect,
                                  selection: $selection)
            }

            DetailsRowView(title: "details_ask_a_question".localized, subtitle: "")
                .onNavigation(viewModel.openSupportChat,
                              tag: NavigationTag.supportChat,
                              selection: $selection)
        }
    }
}

extension DetailsView {
    struct DetailsRowView: View {
        var title: String
        var subtitle: String
        var body: some View {
            HStack(alignment: .center) {
                Text(title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                Spacer()
                Text(subtitle)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark)
            }
            // .padding(.leading)
            // .listRowInsets(EdgeInsets())
        }
    }

    struct HeaderView: View {
        var text: String
        var additionalTopPadding: CGFloat = 0
        var body: some View {
            HStack {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.tangemBlue)
                    .padding(16)
                Spacer()
            }
            .padding(.top, additionalTopPadding)
            .background(Color.tangemBgGray)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
        }
    }

    struct FooterView: View {
        var text: String = ""
        var additionalBottomPadding: CGFloat = 0
        var body: some View {
            if text.isEmpty {
                Color.tangemBgGray
                    .listRowBackground(Color.tangemBgGray)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(height: 0)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.tangemGrayDark)
                        .padding()
                        .padding(.bottom, additionalBottomPadding)
                    Color.clear.frame(height: 0)
                }
                .background(Color.tangemBgGray)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: DetailsViewModel(cardModel: PreviewCard.cardanoNote.cardModel,
                                                    coordinator: DetailsCoordinator()))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

