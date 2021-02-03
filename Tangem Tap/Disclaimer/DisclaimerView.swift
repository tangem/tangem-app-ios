//
//  DisclaimerView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DisclaimerView: View {
    @ObservedObject var viewModel: DisclaimerViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @Environment(\.presentationMode) var presentationMode
    
    private let disclaimerTitle: LocalizedStringKey = "disclaimer_title"
    
    var navigationLinks: AnyView {
        Group {
            if viewModel.state == .accept { //prevent reuse shared navigation state
                NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardOnboardingViewModel(isFromMain: false)),
                               isActive: $navigation.disclaimerToTwinOnboarding)
                  
                NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                               isActive: $navigation.disclaimerToMain)
            }
        }.toAnyView()
    }
    
    var isNavBarHidden: Bool { //prevent navbar glitches
        if viewModel.state == .accept  && navigation.disclaimerToTwinOnboarding {
           return true //hide navbar when navigate to twin onboarding
        }
    
        return false
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            ScrollView {
                Text("disclaimer_text")
                    .font(Font.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark2)
                    .padding()
            }
            
            if viewModel.state == .accept {
                button
                    .padding([.bottom, .trailing])
            }
            
            navigationLinks
        }
        .foregroundColor(.tangemTapGrayDark6)
        .navigationBarTitle("disclaimer_title")
        .navigationBarBackButtonHidden(viewModel.state == .accept)
        .navigationBarHidden(isNavBarHidden)
    }
    
    private var button: some View {
        TangemLongButton(isLoading: false,
                         title: "common_accept",
                         image: "arrow.right") {
            self.viewModel.accept()
        }
        .buttonStyle(TangemButtonStyle(color: .green))
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static let navigation = NavigationCoordinator()
    static var previews: some View {
        DisclaimerView(viewModel: Assembly.previewAssembly.makeDisclaimerViewModel(with: .read))
            .environmentObject(navigation)
    }
}
