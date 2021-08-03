//
//  OnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var cardScanned: Bool = false
    
    var navigationLinks: some View {
        VStack {
            NavigationLink(destination: WebViewContainer(url: viewModel.shopURL, title: "home_button_shop"),
                           isActive: $navigation.readToShop)
        }
    }
    
    var body: some View {
        VStack {
            navigationLinks
            RotatingCardView(baseCardName: "card_twin",
                             backCardImage: UIImage(named: "card_btc")!,
                             cardScanned: cardScanned)
            Button(action: {
                withAnimation {
                    self.cardScanned.toggle()
                }
            }, label: {
                Text("Animate cards")
                    .padding()
            })
            Button(action: {
                viewModel
            }, label: {
                Text("Yes! Scan card")
                    .padding()
            })
            Button(action: {
                
            }, label: {
                Text("Buy new card")
                    .padding()
            })
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        OnboardingView(viewModel: assembly.)
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
