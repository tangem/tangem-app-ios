////
////  TwinCardOnboardingView.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import SwiftUI
//
//struct TwinCardOnboardingView: View {
//    [REDACTED_USERNAME] var navigation: NavigationCoordinator
//    [REDACTED_USERNAME] var viewModel: TwinCardOnboardingViewModel
//    [REDACTED_USERNAME](\.presentationMode) var presentationMode
//    
//    var navigationLinks: some View {
//        Group {
//            //activate link only if we need it, because of navigation issues with shared state
//            if viewModel.state.isWarning {
//                NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly
//                                                                        .makeTwinsWalletCreationViewModel(isRecreating: viewModel.state.isRecreating)),
//                               isActive:  $navigation.twinOnboardingToTwinWalletCreation)
//            } else {
//                if !viewModel.state.isFromMain {
//                    NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
//                                   isActive: $navigation.twinOnboardingToMain)
//                }
//            }
//            
//        }
//    }
//    
//    //fix ios 13 bug. (navbar not dissapeared)
//    [REDACTED_USERNAME] var appeared = false
//    
//    //prevent navbar glitches
//    var isNavBarHidden: Bool {
//        if #available(iOS 14.0, *) {} else {
//            //fix ios 13 bug. We need to trigger one more view update
//            if !appeared {
//                return false
//            }
//        }
//        
//        //hide navbar when navigate to TwinsWalletCreationView, otherwise it will not be hidden in ios 14. on iOS 13 this shit breaks all navbar stuff
//        if #available(iOS 14.0, *), viewModel.state.isWarning &&  navigation.twinOnboardingToTwinWalletCreation {
//            return true
//        }
//        
//        //show navbar when navigate to main
//        if !viewModel.state.isWarning && !viewModel.state.isFromMain && navigation.twinOnboardingToMain {
//            return false
//        }
//        
//        if #available(iOS 14.0, *), !presentationMode.wrappedValue.isPresented {
//            //show navbar when navigate back to main
//            return false
//        }
//        
//        //default navbar state
//        return true
//    }
//    
//    var body: some View {
//        ZStack {
//            navigationLinks
//            
//            GeometryReader { geo in
//                
//                let cardWidth = min(0.36 * geo.size.height, 800)
//                let cardHeight = cardWidth * 0.52
//                TwinOnboardingBackground(colorSet: viewModel.state.backgroundColorSet)
//                
//                VStack {
//                    VStack(spacing: 30) {
//                        Image(uiImage: viewModel.firstTwinImage)
//                            .resizable()
//                            .frame(width: cardWidth, height: cardHeight)
//                            .cornerRadius(9)
//                            .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
//                            .offset(x: -0.38 * cardWidth)
//                            .rotationEffect(.init(degrees: -22))
//                        Image(uiImage: viewModel.secondTwinImage)
//                            .resizable()
//                            .frame(width: cardWidth, height: cardHeight)
//                            .cornerRadius(9)
//                            .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
//                            .offset(x: -0.24 * cardWidth)
//                            .rotationEffect(.init(degrees: -22))
//                    }
//                    .offset(y: 0.12 * cardHeight)
//                    
//                    Color.clear.frame(height: 0.1 * geo.size.height)
//                    
//                    content()
//                        .edgesIgnoringSafeArea(.bottom)
//                }
//            }
//        }
//        .edgesIgnoringSafeArea(.top)
//        .background(Color(.tangemBgGray2).edgesIgnoringSafeArea(.all))
//        .navigationBarBackButtonHidden(true)
//        .onAppear {
//            if #available(iOS 14.0, *) {} else {
//                //fix ios 13 navbar  bug
//                DispatchQueue.main.async {
//                    if !viewModel.appeared && appeared {
//                        appeared = false
//                    }
//                    
//                    appeared = true
//                }
//            }
//        }
//        .onDisappear() {
//            if #available(iOS 14.0, *) {} else {
//                //fix ios 13 bug
//                viewModel.appeared = false
//            }
//        }
//        .navigationBarTitle("")
//        .navigationBarHidden(isNavBarHidden)
//    }
//    
//    [REDACTED_USERNAME] private func content() -> some View {
//        let button = TangemLongButton(isLoading: false, title: viewModel.state.buttonTitle, image: "arrow.right", action: { self.viewModel.buttonAction() })
//        
//        switch viewModel.state {
//        case let .onboarding(pairCid, _):
//            VStack {
//                Spacer()
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("twins_onboarding_title")
//                        .font(.system(size: 27, weight: .bold))
//                        .fixedSize(horizontal: false, vertical: true)
//                    Text("twins_onboarding_subtitle")
//                        .font(.system(size: 15, weight: .medium))
//                        .fixedSize(horizontal: false, vertical: true)
//                    Text(String(format: "twins_onboarding_description_format".localized, pairCid))
//                        .foregroundColor(.tangemGrayDark3)
//                        .fixedSize(horizontal: false, vertical: true)
//                }
//                .font(.system(size: 13, weight: .regular))
//                .lineSpacing(4)
//                .padding(.horizontal, 37)
//
//                Spacer()
//                
//                HStack {
//                    Spacer()
//                    button
//                        .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
//                        .padding(.bottom, 30)
//                        .padding(.trailing, 30)
//                }
//            }
//            
//        case .warning(let isRecreating):
//            VStack {
//                Spacer()
//                
//                HStack {
//                    Image(systemName: "exclamationmark.circle")
//                        .resizable()
//                        .frame(width: 26, height: 26)
//                    Text("common_warning")
//                        .font(.system(size: 30, weight: .bold))
//                    
//                    Spacer()
//                }
//                
//                Text(isRecreating ? "details_twins_recreate_warning" : "details_twins_create_warning")
//                    .foregroundColor(.tangemGrayDark3)
//                    .font(.system(size: 13, weight: .regular))
//                    .lineSpacing(6)
//                    .fixedSize(horizontal: false, vertical: true)
//
//                Spacer()
//                
//                HStack(alignment: .center, spacing: 12) {
//                    TangemButton(isLoading: false,
//                                 title: "common_back",
//                                 image: "", action: {
//                                    if !isRecreating {
//                                        navigation.mainToTwinsWalletWarning = false
//                                    } else {
//                                        navigation.detailsToTwinsRecreateWarning = false
//                                    }
//                                 })
//                        .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
//                    
//                    button
//                        .buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
//                }
//                .padding(.bottom, 16)
//            }
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
//struct TwinCardOnboardingView_Previews: PreviewProvider {
//    static let assembly = Assembly.previewAssembly
//    
//    static var previews: some View {
//        TwinCardOnboardingView(viewModel: assembly.makeTwinCardOnboardingViewModel(state: .onboarding(withPairCid: "", isFromMain: false)))
//            .environmentObject(assembly.services.navigationCoordinator)
//            //.previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone12Pro, .iPhone12ProMax])
//        
//        TwinCardOnboardingView(viewModel: assembly.makeTwinCardOnboardingViewModel(state: .warning(isRecreating: false)))
//            .environmentObject(assembly.services.navigationCoordinator)
//            //.previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone12Pro, .iPhone12ProMax])
//        
//        TwinCardOnboardingView(viewModel: assembly.makeTwinCardOnboardingViewModel(state: .warning(isRecreating: true)))
//            .environmentObject(assembly.services.navigationCoordinator)
//    }
//}
