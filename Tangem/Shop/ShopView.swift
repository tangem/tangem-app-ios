//
//  ShopView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var viewModel: ShopViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigation: NavigationCoordinator
    
    private let sectionRowVerticalPadding = 12.0
    private let sectionCornerRadius = 18.0
    private let applePayCornerRadius = 18.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    SheetDragHandler()
                    
                    cardStack
                        .padding(.top)
                        .layoutPriority(1)
                    
                    Spacer()
                        .frame(maxHeight: .infinity)
                    
                    Text("shop_one_wallet")
                        .font(.system(size: 30, weight: .bold))
                    
                    Picker("", selection: $viewModel.selectedBundle) {
                        Text("shop_3_cards").tag(ShopViewModel.Bundle.threeCards)
                        Text("shop_2_cards").tag(ShopViewModel.Bundle.twoCards)
                    }
                    .pickerStyle(.segmented)
                    .frame(minWidth: 0, maxWidth: 250)
                    
                    Spacer()
                        .frame(maxHeight: .infinity)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image("box")
                            Text("shop_shipping")
                            Spacer()
                            Text("shop_free")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, sectionRowVerticalPadding)
                        
                        Separator(height: 0.5, padding: 0)
                        
                        HStack {
                            Image("ticket")
                            
                            TextField("shop_i_have_a_promo_code", text: $viewModel.discountCode)
                                .disableAutocorrection(true)
                                .keyboardType(.alphabet)
                            
                            ActivityIndicatorView(isAnimating: viewModel.checkingDiscountCode, color: .tangemGrayDark)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, sectionRowVerticalPadding)
                    }
                    .background(Color.white.cornerRadius(sectionCornerRadius))
                    .padding(.bottom, 8)
                    
                    
                    VStack {
                        HStack {
                            Text("shop_total")
                            
                            Spacer()
                            
                            if let totalAmountWithoutDiscount = viewModel.totalAmountWithoutDiscount {
                                Text(totalAmountWithoutDiscount)
                                    .strikethrough()
                            }
                            
                            ZStack {
                                Text(viewModel.totalAmount)
                                Text("0")
                                    .foregroundColor(.clear)
                            }
                            .font(.system(size: 22, weight: .bold))
                            
                            if viewModel.loadingProducts {
                                ActivityIndicatorView(isAnimating: viewModel.loadingProducts, color: .tangemGrayDark)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, sectionRowVerticalPadding)
                    }
                    .background(Color.white.cornerRadius(sectionCornerRadius))
                    .padding(.bottom, 8)
                    
                    
                    if viewModel.canUseApplePay {
                        ApplePayButton {
                            viewModel.openApplePayCheckout()
                        }
                        .frame(height: 46)
                        .cornerRadius(applePayCornerRadius)
                        
                        Button {
                            viewModel.openWebCheckout()
                        } label: {
                            Text("shop_other_payment_methods")
                        }
                        .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite, layout: .flexibleWidth))
                    } else {
                        Button {
                            viewModel.openWebCheckout()
                        } label: {
                            Text("shop_buy_now")
                        }
                        .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
                    }
                    
                    NavigationLink(isActive: $viewModel.showingWebCheckout) {
                        if let webCheckoutUrl = viewModel.webCheckoutUrl {
                            WebViewContainer(url: webCheckoutUrl, title: "")
                                .edgesIgnoringSafeArea(.all)
                        } else {
                            EmptyView()
                        }
                    } label: {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding(.horizontal)
                .frame(minWidth: geometry.size.width,
                       maxWidth: geometry.size.width,
                       minHeight: geometry.size.height,
                       maxHeight: .infinity, alignment: .top)
            }
        }
        .overlay(orderActivityOverlay)
        .background(Color(UIColor.tangemBgGray).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.didAppear()

            UISegmentedControl.appearance().selectedSegmentTintColor = .black
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        }
        .navigationBarHidden(true)
        .keyboardAdaptive(animated: .constant(true))
    }
    
    private var cardStack: some View {
        let secondCardOffset = 12.0
        let thirdCardOffset = 22.0
        
        return Image("wallet_card")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .background(
                Color.underlyingCardBackground1
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .offset(x: 0, y: secondCardOffset)
            )
            .background(
                Color.underlyingCardBackground2
                    .cornerRadius(12)
                    .padding(.horizontal, 36)
                    .offset(x: 0, y: viewModel.showingThirdCard ? thirdCardOffset : secondCardOffset)
            )
            .padding(.bottom, thirdCardOffset)
            .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var orderActivityOverlay: some View {
        if viewModel.pollingForOrder {
            Color.white.opacity(0.3)
                .overlay(ActivityIndicatorView(isAnimating: true, style: .medium, color: .tangemGrayDark))
        } else {
            EmptyView()
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        ShopView(viewModel: assembly.makeShopViewModel())
            .environmentObject(assembly.services.navigationCoordinator)
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}
