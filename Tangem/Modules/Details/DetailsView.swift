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
        case currency, disclaimer, cardTermsOfUse, securityManagement, cardOperation, manageTokens, walletConnect, backup, resetToFactory
    }
    
    @ObservedObject var viewModel: DetailsViewModel
    
    //fix remain highlited bug on ios14
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
        .onAppear(perform: viewModel.onAppear)
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
            
            securityManagementRow
            
            if viewModel.isTwinCard {
                twinCardRecreateView
                
            } else {
                if viewModel.backupVisible {
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
        Button(action: {
            viewModel.prepareTwinOnboarding()
        }, label: {
            Text("details_row_title_twins_recreate")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(viewModel.cardModel.canRecreateTwinCard ? .tangemGrayDark6 : .tangemGrayDark)
        })
        .sheet(isPresented: $navigation.detailsToTwinsRecreateWarning, content: {
            OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                .presentation(
                    modal: viewModel.isTwinRecreationModel, onDismissalAttempt: {
                        assembly.getTwinOnboardingViewModel()?.backButtonAction()
                    },
                    onDismissed: nil
                )
                .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                    viewModel.isTwinRecreationModel = value
                })
                .environmentObject(navigation)
        })
        .disabled(!viewModel.cardModel.canRecreateTwinCard)
    }
    
    // MARK: Backup row
    
    private var createBackupRow: some View {
        Button(action: {
            viewModel.prepareBackup()
        }, label: {
            Text("details_row_title_create_backup")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(viewModel.canCreateBackup ? .tangemGrayDark6 : .tangemGrayDark)
        })
        .disabled(!viewModel.canCreateBackup)
        .sheet(isPresented: $navigation.detailsToBackup, content: {
            OnboardingBaseView(viewModel: viewModel.assembly.getCardOnboardingViewModel())
                .presentation(
                    modal: viewModel.isTwinRecreationModel, onDismissalAttempt: {
                        assembly.getWalletOnboardingViewModel()?.backButtonAction()
                    },
                    onDismissed: nil
                )
                .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                    viewModel.isTwinRecreationModel = value
                })
                .environmentObject(navigation)
                .navigationBarHidden(true)
        })
    }
    
    // MARK: Reset row
    
    @ViewBuilder
    private var resetToFactoryRow: some View {
        let destination = CardOperationView(
            title: "details_row_title_reset_factory_settings".localized,
            buttonTitle: "card_operation_button_title_reset",
            shouldPopToRoot: true,
            alert: "details_row_title_reset_factory_settings_warning".localized,
            actionButtonPressed: { self.viewModel.cardModel.resetToFactory(completion: $0) }
        )
            .environmentObject(navigation)
            .environmentObject(assembly)
        
        NavigationLink(
            destination: destination,
            tag: NavigationTag.resetToFactory,
            selection: $selection
        ) {
            DetailsRowView(title: "details_row_title_reset_factory_settings".localized, subtitle: "")
        }
        .disabled(!viewModel.cardModel.canPurgeWallet)
    }
    
    // MARK: SecurityManagement
    
    private var securityManagementRow: some View {
        Button(action: {
            viewModel.checkPin {
                selection = .securityManagement
            }
        }, label: {
            HStack {
                Text("details_row_title_manage_security")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                
                Spacer()
                
                ActivityIndicatorView(isAnimating: viewModel.isCheckingPin, color: .tangemGrayDark4)
            }
        })
        .background(securityManagementNavigationLink)
    }
    
    @ViewBuilder
    private var securityManagementNavigationLink: some View {
        if !viewModel.isCheckingPin {
            let destination = SecurityManagementView(
                viewModel: viewModel.assembly.makeSecurityManagementViewModel(with: viewModel.cardModel)
            )
                .environmentObject(navigation)
            
            NavigationLink(
                destination: destination,
                tag: NavigationTag.securityManagement,
                selection: $selection,
                label: { EmptyView() }
            )
            .disabled(true)
        }
    }
    
    // MARK: Second Section
    
    private var applicationDetailsSection: some View {
        Section(header: HeaderView(text: "details_section_title_app".localized), footer: FooterView()) {
            if !viewModel.isMultiWallet {
                let destination = CurrencySelectView(
                    viewModel: viewModel.assembly.makeCurrencySelectViewModel(),
                    dismissAfterSelection: false
                )
                
                NavigationLink(destination: destination,
                               tag: NavigationTag.currency,
                               selection: $selection) {
                    DetailsRowView(title: "details_row_title_currency".localized,
                                   subtitle: viewModel.currencyRateService.selectedCurrencyCode)
                }
            }

            NavigationLink(
                destination: DisclaimerView(viewModel: .init(style: .navbar, showAccept: false, dismissCallback: {})),
                tag: NavigationTag.disclaimer,
                selection: $selection
            ) {
                DetailsRowView(title: "disclaimer_title".localized, subtitle: "")
            }

            Button(action: {
                navigation.detailsToSendEmail = true
            }, label: {
                Text("details_row_title_send_feedback".localized)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
            })
            .sheet(isPresented: $navigation.detailsToSendEmail) {
                MailView(viewModel: .init(dataCollector: viewModel.dataCollector,
                                          support: viewModel.cardModel.emailSupport,
                                          emailType: .appFeedback(support: viewModel.cardModel.isStart2CoinCard ? .start2coin : .tangem)))
            }
            
            if let cardTouURL = viewModel.cardTouURL {
                let destination = WebViewContainer(viewModel: .init(url: cardTouURL, title: "details_row_title_card_tou".localized))
                    .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
                
                NavigationLink(
                    destination: destination,
                    tag: NavigationTag.cardTermsOfUse,
                    selection: $selection
                ) {
                    DetailsRowView(title: "details_row_title_card_tou".localized, subtitle: "")
                }
            }
            
            if viewModel.shouldShowWC {
                let destination = WalletConnectView(
                    viewModel: viewModel.assembly.makeWalletConnectViewModel(cardModel: viewModel.cardModel)
                )
                    .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
                
                NavigationLink(destination: destination,
                               tag: NavigationTag.walletConnect,
                               selection: $selection) {
                    DetailsRowView(title: "WalletConnect", subtitle: "")
                }
            }
        }
    }
}

extension DetailsView {
    struct DetailsRowView: View {
        var title: String
        var subtitle: String
        var body: some View {
            HStack (alignment: .center) {
                Text(title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark6)
                Spacer()
                Text(subtitle)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemGrayDark)
            }
            // .padding(.leading)
            //.listRowInsets(EdgeInsets())
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
    static let assembly = Assembly.previewAssembly(for: .ethereum)
    static let navigation = NavigationCoordinator()
    
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: assembly.makeDetailsViewModel())
                .environmentObject(navigation)
                .environmentObject(assembly)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

