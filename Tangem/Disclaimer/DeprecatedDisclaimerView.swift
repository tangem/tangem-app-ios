////
////  DeprecatedDisclaimerView.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//
//struct DeprecatedDisclaimerView: View {
//    [REDACTED_USERNAME] var viewModel: DeprecatedDisclaimerViewModel
//    [REDACTED_USERNAME] var navigation: NavigationCoordinator
//    
//    private let disclaimerTitle: LocalizedStringKey = "disclaimer_title"
//    
//    var navigationLinks: some View {
//        Group {
//            if viewModel.state == .accept { //prevent reuse shared navigation state
//                NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardOnboardingViewModel(isFromMain: false)),
//                               isActive: $navigation.disclaimerToTwinOnboarding)
//                  
//                NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
//                               isActive: $navigation.disclaimerToMain)
//            }
//            
//            //https://forums.swift.org/t/14-5-beta3-navigationlink-unexpected-pop/45279
//            // Weird IOS 14.5/XCode 12.5 bug. Navigation link cause an immediate pop, if there are exactly 2 links presented
//            NavigationLink(destination: EmptyView()) {
//                EmptyView()
//            }
//        }
//    }
//    
//    var isNavBarHidden: Bool {
//        // prevent navbar glitches
//        if viewModel.state == .accept  && navigation.disclaimerToTwinOnboarding {
//            // hide navbar when navigate to twin onboarding
//           return true
//        }
//    
//        return false
//    }
//    
//    var body: some View {
//        VStack(alignment: .trailing) {
//            ScrollView {
//                Text("disclaimer_text")
//                    .font(Font.system(size: 16, weight: .regular, design: .default))
//                    .foregroundColor(.tangemGrayDark2)
//                    .padding()
//            }
//            
//            if viewModel.state == .accept {
//                button
//                    .padding([.bottom, .trailing])
//            }
//            
//            navigationLinks
//        }
//        .foregroundColor(.tangemGrayDark6)
//        .navigationBarTitle("disclaimer_title")
//        .navigationBarBackButtonHidden(viewModel.state == .accept)
//        .navigationBarHidden(isNavBarHidden)
//    }
//    
//    private var button: some View {
//        TangemLongButton(isLoading: false,
//                         title: "common_accept",
//                         image: "arrow.right") {
//            self.viewModel.accept()
//        }
//        .buttonStyle(TangemButtonStyle(color: .green))
//    }
//}
//
//struct DeprecatedDisclaimerView_Previews: PreviewProvider {
//    static let assembly = Assembly.previewAssembly
//    
//    static var previews: some View {
//        DeprecatedDisclaimerView(viewModel: assembly.makeDisclaimerViewModel(with: .read))
//            .environmentObject(assembly.services.navigationCoordinator)
//            .deviceForPreviewZoomed(.iPhone7)
//    }
//}
