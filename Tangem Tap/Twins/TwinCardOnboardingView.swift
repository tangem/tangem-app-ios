//
//  TwinCardOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct TwinCardOnboardingView: View {
    @EnvironmentObject var navigation: NavigationCoordinator
    @ObservedObject var viewModel: TwinCardOnboardingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    private let backHeightAspect: CGFloat = 1.3
    private let backgroundMinBottomOffset: CGFloat = 300
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    private var backgroundHeight: CGFloat {
        screenSize.width * backHeightAspect
    }
    
    var navigationLinks: AnyView {
        Group {
            if viewModel.state.isWarning { //activate link only if we need it, because of navigation issues with shared state
                NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly
                                                                        .makeTwinsWalletCreationViewModel(isRecreating: viewModel.state.isRecreating)),
                               isActive:  $navigation.twinOnboardingToTwinWalletCreation)
            } else {
                if !viewModel.state.isFromMain {
                    NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                                   isActive: $navigation.twinOnboardingToMain)
                }
            }
            
        }.toAnyView()
    }
    
    @State var appeared = false //fix ios 13 bug. (navbar not dissapeared)
    
    //prevent navbar glitches
    var isNavBarHidden: Bool {
        if #available(iOS 14.0, *) {} else {
            if !appeared { //fix ios 13 bug. We need to trigger one more view update
                return false
            }
        }
        
        //hide navbar when navigate to TwinsWalletCreationView, otherwise it will not be hidden in ios 14. on iOS 13 this shit breaks all navbar stuff
        if #available(iOS 14.0, *), viewModel.state.isWarning &&  navigation.twinOnboardingToTwinWalletCreation {
            return true
        }
        
        //show navbar when navigate to main
        if !viewModel.state.isWarning && !viewModel.state.isFromMain && navigation.twinOnboardingToMain {
            return false
        }
        
        if #available(iOS 14.0, *), !presentationMode.wrappedValue.isPresented {
            return false //show navbar when navigate back to main
        }
        
        return true //default navbar state
    }
    
    var body: some View {
        ZStack {
            navigationLinks
            
            VStack {
                ZStack(alignment: .bottom) {
                    TwinOnboardingBackground(colorSet: viewModel.state.backgroundColorSet)
                    VStack(spacing: 30) {
                        Image(uiImage: viewModel.firstTwinImage)
                            .resizable()
                            .frame(width: 316, height: 166)
                            .cornerRadius(9)
                            .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                            .offset(x: -57)
                            .rotationEffect(.init(degrees: -22))
                        Image(uiImage: viewModel.secondTwinImage)
                            .resizable()
                            .frame(width: 316, height: 166)
                            .cornerRadius(9)
                            .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                            .offset(x: -9)
                            .rotationEffect(.init(degrees: -22))
                    }
                    .offset(y: -70)
                    .frame(maxWidth: screenSize.width, alignment: .leading)
                    
                }
                .offset(y: backgroundOffset())
                .edgesIgnoringSafeArea(.top)
                Spacer()
            }
            .clipped()
            .edgesIgnoringSafeArea(.top)
            content()
                .edgesIgnoringSafeArea(.top)
                .frame(width: UIScreen.main.bounds.width)
        }
        .frame(width: UIScreen.main.bounds.width)
        .clipped()
        .edgesIgnoringSafeArea(.top)
        .background(Color(.tangemTapBgGray2).edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if #available(iOS 14.0, *) {} else {
                //fix ios 13 navbar  bug
                DispatchQueue.main.async {
                    if !viewModel.appeared && appeared {
                        appeared = false
                    }
                    
                    appeared = true
                }
            }
        }
        .onDisappear() {
            if #available(iOS 14.0, *) {} else {
                viewModel.appeared = false //fix ios 13 bug
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(isNavBarHidden)
    }
    
    private func content() -> some View {
        let buttonEdgeInsets = EdgeInsets(top: 0, leading: 30, bottom: 16, trailing: 30)
        let button = TangemLongButton(isLoading: false, title: viewModel.state.buttonTitle, image: "arrow.right", action: { self.viewModel.buttonAction() })
        
        switch viewModel.state {
        case let .onboarding(pairCid, _):
            return VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    Text("twins_onboarding_title")
                        .font(.system(size: 30, weight: .bold))
                    Text("twins_onboarding_subtitle")
                        .font(.system(size: 17, weight: .medium))
                    Text(String(format: "twins_onboarding_description_format".localized, pairCid))
                        .foregroundColor(.tangemTapGrayDark3)
                }
                .font(.system(size: 13, weight: .regular))
                .lineSpacing(8)
                .padding(.horizontal, 37)
                .padding(.bottom, 24)
                HStack {
                    Spacer()
                    button
                        .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
                        .padding(buttonEdgeInsets)
                    
                }
            }.toAnyView()
        case .warning(let isRecreating):
            return VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .frame(width: 26, height: 26)
                        Text("common_warning")
                            .font(.system(size: 30, weight: .bold))
                    }
                    Text(isRecreating ? "details_twins_recreate_warning" : "details_twins_create_warning")
                        .foregroundColor(.tangemTapGrayDark3)
                        .font(.system(size: 13, weight: .regular))
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 44)
                HStack(alignment: .center, spacing: 12) {
                    TangemButton(isLoading: false,
                                 title: "common_back",
                                 image: "", action: {
                                    if !isRecreating {
                                        navigation.mainToTwinsWalletWarning = false
                                    } else {
                                        navigation.detailsToTwinsRecreateWarning = false
                                    }
                                 })
                        .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
                    
                    button
                        .buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
                }
                .padding(buttonEdgeInsets)
            }.toAnyView()
        }
    }
    
    private func backgroundOffset() -> CGFloat {
        let bottomSpace = screenSize.height - backgroundHeight
        return bottomSpace < backgroundMinBottomOffset ?
            bottomSpace -  backgroundMinBottomOffset :
            0
    }
    
}

struct TwinCardOnboardingView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    static var previews: some View {
        TwinCardOnboardingView(viewModel: assembly.makeTwinCardWarningViewModel(isRecreating: true))
            .environmentObject(assembly.navigationCoordinator)
            .previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone12Pro, .iPhone12ProMax])
    }
}
