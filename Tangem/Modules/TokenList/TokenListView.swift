//
//  TokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine
import AlertToast

struct TokenListView: View {
    @ObservedObject var viewModel: TokenListViewModel

    var body: some View {
        ZStack {
            PerfList {
                if #available(iOS 15.0, *) {} else {
                    let horizontalInset: CGFloat = UIDevice.isIOS13 ? 8 : 16
                    SearchBar(text: $viewModel.enteredSearchText.value, placeholder: "common_search".localized)
                        .padding(.horizontal, UIDevice.isIOS13 ? 0 : 8)
                        .listRowInsets(.init(top: 8, leading: horizontalInset, bottom: 8, trailing: horizontalInset))
                }

                if viewModel.shouldShowAlert {
                    Text("alert_manage_tokens_addresses_message")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#848488"))
                        .cornerRadius(10)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .perfListPadding()
                }

                PerfListDivider()

                ForEach(viewModel.coinViewModels) {
                    CoinView(model: $0)
                        .buttonStyle(PlainButtonStyle()) // fix ios13 list item selection
                        .perfListPadding()

                    PerfListDivider()
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                if !viewModel.isReadonlyMode {
                    Color.clear.frame(width: 10, height: 58, alignment: .center)
                }
            }

            overlay
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(viewModel.titleKey, displayMode: UIDevice.isIOS13 ? .inline : .automatic)
        .navigationBarItems(trailing: addCustomView)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .toast(isPresenting: $viewModel.showToast) {
            AlertToast(type: .complete(Color.tangemGreen), title: "contract_address_copied_message".localized)
        }
        .searchableCompat(text: $viewModel.enteredSearchText.value)
        .background(Color.clear.edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .keyboardAdaptive()
    }

    @ViewBuilder private var addCustomView: some View {
        if !viewModel.isReadonlyMode {
            Button(action: viewModel.openAddCustom) {
                ZStack {
                    Circle().fill(Colors.Button.primary)

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .bold, design: .default))
                }
                .frame(width: 26, height: 26)
            }
            .animation(nil)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder private var titleView: some View {
        Text(viewModel.titleKey)
            .font(Font.system(size: 30, weight: .bold, design: .default))
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder private var overlay: some View {
        if !viewModel.isReadonlyMode {
            VStack {
                Spacer()

                TangemButton(title: "common_save_changes", action: viewModel.saveChanges)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   layout: .flexibleWidth,
                                                   isDisabled: viewModel.isSaveDisabled,
                                                   isLoading: viewModel.isSaving))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(LinearGradient(colors: [.white, .white, .white.opacity(0)],
                                               startPoint: .bottom,
                                               endPoint: .top)
                            .edgesIgnoringSafeArea(.bottom))
            }
        }
    }
}

struct AddNewTokensView_Previews: PreviewProvider {
    static var previews: some View {
        TokenListView(viewModel: .init(mode: .add(cardModel: PreviewCard.ethereum.cardModel),
                                       coordinator: TokenListCoordinator()))
    }
}
