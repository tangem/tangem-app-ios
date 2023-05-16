//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk
import Combine
import MessageUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RefreshableScrollView(onRefresh: { viewModel.onRefresh($0) }) {
                    VStack(spacing: 14) {
                        CardView(
                            image: viewModel.image,
                            width: geometry.size.width - 32,
                            cardSetLabel: viewModel.cardsCountLabel
                        )
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)

                        if viewModel.isLackDerivationWarningViewVisible {
                            ScanCardWarningView(action: viewModel.deriveEntriesWithoutDerivation)
                                .padding(.horizontal, 16)
                        }

                        WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                            viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                        })
                        .padding(.horizontal, 16)

                        if viewModel.isBackupAllowed {
                            backupWarningView
                        }

                        if let viewModel = viewModel.multiWalletContentViewModel {
                            MultiWalletContentView(viewModel: viewModel)
                        } else if let viewModel = viewModel.singleWalletContentViewModel {
                            SingleWalletContentView(viewModel: viewModel)
                        }

                        Color.clear.frame(width: 10, height: 58, alignment: .center)
                    }
                }

                if !viewModel.isMultiWalletMode {
                    bottomButtons
                        .frame(width: geometry.size.width)
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Remove default back button. Because we don't have back transition. Has no effect on iOS13.
        .navigationBarTitle(Text(Localization.walletTitle), displayMode: .inline)
        .navigationBarItems(
            leading: leadingNavigationButtons,
            trailing: settingsNavigationButton
        )
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.onAppear()
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.error) { $0.alert }
    }

    @ViewBuilder
    var leadingNavigationButtons: some View {
        if viewModel.saveUserWallets {
            userWalletListNavigationButton
        } else {
            scanNavigationButton
        }
    }

    var userWalletListNavigationButton: some View {
        Button(
            action: viewModel.didTapUserWalletListButton,
            label: {
                Assets.wallets.image
                    .foregroundColor(Color.black)
                    .frame(width: 44, height: 44)
                    .offset(x: -11, y: 0)
            }
        )
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
    }

    var scanNavigationButton: some View {
        Button(
            action: viewModel.onScan,
            label: {
                Assets.scanWithPhone.image
                    .foregroundColor(Color.black)
                    .frame(width: 44, height: 44)
                    .offset(x: -14, y: 0)
            }
        )
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
    }

    var settingsNavigationButton: some View {
        Button(action: viewModel.openSettings) {
            Assets.verticalDots.image
                .foregroundColor(Color.tangemGrayDark6)
                .frame(width: 44, height: 44)
                .offset(x: 11)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
    }

    var backupWarningView: some View {
        BackUpWarningButton(tapAction: {
            viewModel.prepareForBackup()
        })
        .padding(.horizontal, 16)
    }

    var sendButton: some View {
        MainButton(
            title: Localization.walletButtonSend,
            icon: .leading(Assets.arrowRightMini),
            isDisabled: !viewModel.canSend,
            action: viewModel.sendTapped
        )
        .actionSheet(isPresented: $viewModel.showSelectWalletSheet) {
            ActionSheet(
                title: Text(Localization.walletChoiceWalletOptionTitle),
                message: nil,
                buttons: sendChoiceButtons + [ActionSheet.Button.cancel()]
            )
        }
    }

    var sendChoiceButtons: [ActionSheet.Button] {
        let symbols = viewModel.wallet?.amounts
            .filter { $0.key != .reserve && $0.value.value > 0 }
            .values.map { $0.self } ?? []

        return symbols.map { amount in
            return ActionSheet.Button.default(Text(amount.currencySymbol)) {
                viewModel.openSend(for: Amount(with: amount, value: 0))
            }
        }
    }

    @ViewBuilder
    var exchangeCryptoButton: some View {
        switch viewModel.exchangeButtonState {
        case .single(let option):
            MainButton(
                title: option.title,
                icon: .leading(Assets.arrowUpMini),
                isDisabled: !viewModel.isAvailable(type: option)
            ) {
                viewModel.didTapExchangeButtonAction(type: option)
            }
        case .multi:
            MainButton(
                title: Localization.walletButtonActions,
                icon: .leading(Assets.exchangeMini),
                action: viewModel.openExchangeActionSheet
            )
            .actionSheet(item: $viewModel.exchangeActionSheet, content: { $0.sheet })
        }
    }

    var bottomButtons: some View {
        VStack {
            Spacer()

            VStack {
                HStack(alignment: .center) {
                    if viewModel.canBuyCrypto {
                        exchangeCryptoButton
                    }

                    if viewModel.canShowSend {
                        sendButton
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(viewModel: .init(
                cardModel: PreviewCard.stellar.cardModel,
                cardImageProvider: CardImageProvider(),
                coordinator: MainCoordinator()
            ))
        }
        .previewGroup(devices: [.iPhone12ProMax])
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.locale, .init(identifier: "en"))
    }
}
