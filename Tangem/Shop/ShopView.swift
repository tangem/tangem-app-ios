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
    
    var body: some View {
        VStack {
            SheetDragHandler()
            
            Image("wallet_card")
                .padding(.top)
            
            Spacer()
            
            Text("One Wallet")
                .font(.system(size: 30, weight: .bold))
            
            Picker("Variant", selection: $viewModel.selectedVariant) {
                Text("3 cards").tag(ShopViewModel.ProductVariant.threeCards)
                Text("2 cards").tag(ShopViewModel.ProductVariant.twoCards)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .frame(minWidth: 0, maxWidth: 250)
            
            Spacer()
            
            Form {
                Section {
                    HStack {
                        Image(systemName: "square")
                        Text("Delivery (Free shipping)")
                        
//                        Spacer()
                        
//                        Button {
//
//                        } label: {
//                            Text("Estimate")
//                                .foregroundColor(Color.tangemGreen1)
//                        }
                    }
                    HStack {
                        Image(systemName: "square")
                        TextField("I have a promo code...", text: .constant(""))
                    }
                }
                
                Section {
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
                }
            }
            
            ApplePayButton {
                viewModel.showingApplePay = true
            }
            .frame(height: 46)
            .cornerRadius(23)
            .padding(.horizontal)

            Button {
                viewModel.showingWebCheckout = true
            } label: {
                Text("Other payment methods")
            }
            .buttonStyle(TangemButtonStyle(colorStyle: .transparentWhite, layout: .flexibleWidth))
        }
        .background(Color(UIColor.tangemBgGray).edgesIgnoringSafeArea(.all))
    }
}

struct ShopView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly
    
    static var previews: some View {
        ShopView(viewModel: assembly.makeShopViewModel())
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
