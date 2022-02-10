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
    
    #warning("[REDACTED_TODO_COMMENT]")
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    SheetDragHandler()
                    
                    cardStack
                        .padding(.top)
                    
                    Spacer()
                        .frame(maxHeight: .infinity)
                    
                    Text("One Wallet")
                        .font(.system(size: 30, weight: .bold))
                    
                    Picker("Variant", selection: $viewModel.selectedBundle) {
                        Text("3 cards").tag(ShopViewModel.Bundle.threeCards)
                        Text("2 cards").tag(ShopViewModel.Bundle.twoCards)
                    }
                    .pickerStyle(.segmented)
                    .frame(minWidth: 0, maxWidth: 250)
                    
                    Spacer()
                        .frame(maxHeight: .infinity)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image("box")
                            Text("Delivery (Free shipping)")
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, sectionRowVerticalPadding)
                        
                        Separator(height: 0.5)
                        
                        HStack {
                            Image("ticket")
                            TextField("I have a promo code...", text: $viewModel.discountCode)
                            ActivityIndicatorView(isAnimating: viewModel.checkingDiscountCode, color: .tangemGrayDark)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, sectionRowVerticalPadding)
                    }
                    .background(Color.white.cornerRadius(sectionCornerRadius))
                    .padding(.bottom, 8)
                    
                    
                    VStack {
                        HStack {
                            Text("Total")
                            
                            Spacer()
                            
                            if let totalAmountWithoutDiscount = viewModel.totalAmountWithoutDiscount {
                                Text(totalAmountWithoutDiscount)
                                    .strikethrough()
                            }
                            
                            Text(viewModel.totalAmount)
                                .font(.system(size: 22, weight: .bold))
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
                            Text("Other payment methods")
                        }
                        .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite, layout: .flexibleWidth))
                    } else {
                        Button {
                            viewModel.openWebCheckout()
                        } label: {
                            Text("Buy now")
                        }
                        .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))
                    }
                    
                    NavigationLink(isActive: $viewModel.showingWebCheckout) {
                        if let webCheckoutUrl = viewModel.webCheckoutUrl {
                            WebViewContainer(url: webCheckoutUrl, title: "SHOP")
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
        .background(Color(UIColor.tangemBgGray).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.didAppear()

            UISegmentedControl.appearance().selectedSegmentTintColor = .black
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        }
        .navigationBarHidden(true)
    }
    
    private var cardStack: some View {
        let secondCardOffset = 12.0
        let thirdCardOffset = 22.0
        
        #warning("[REDACTED_TODO_COMMENT]")
        return Image("wallet_card")
            .background(
                Color(hex: "#2E343BFF")
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .offset(x: 0, y: secondCardOffset)
            )
            .background(
                Color(hex: "#595D61FF")
                    .cornerRadius(12)
                    .padding(.horizontal, 36)
                    .offset(x: 0, y: viewModel.showingThirdCard ? thirdCardOffset : secondCardOffset)
            )
            .padding(.bottom, thirdCardOffset)
    }
}

struct ShopView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        ShopView(viewModel: assembly.makeShopViewModel())
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
