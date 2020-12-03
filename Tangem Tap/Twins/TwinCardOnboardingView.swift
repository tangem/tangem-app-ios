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
	
	var body: some View {
		ZStack {
			
			VStack {
				ZStack(alignment: .bottomLeading) {
					Image(viewModel.state.backgroundName)
						.resizable()
						.frame(width: screenSize.width, height: backgroundHeight)
						.scaledToFill()
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
					.offset(y: -84)
					.frame(maxWidth: screenSize.width, alignment: .leading)
					
				}
				.offset(y: backgroundOffset())
				.edgesIgnoringSafeArea(.top)
				Spacer()
			}
			.clipped()
			.edgesIgnoringSafeArea(.all)
			content()
		}
		.navigationBarTitle("")
		.navigationBarHidden(true)
		.background(Color(.tangemTapBgGray2).edgesIgnoringSafeArea(.all))
	}
	
	private func content() -> some View {
		let buttonEdgeInsets = EdgeInsets(top: 0, leading: 30, bottom: 16, trailing: 30)
		let button = TangemLongButton(isLoading: false, title: viewModel.state.buttonTitle, image: "arrow.right", action: { self.viewModel.buttonAction() })
		
		switch viewModel.state {
		case let .onboarding(pairCid, isFromMain):
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
					if isFromMain {
						button
							.padding(buttonEdgeInsets)
					} else {
						NavigationButton(button: button,
										 navigationLink: NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
																		isActive: $navigation.onboardingOpenMain))
							.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
							.padding(buttonEdgeInsets)
					}
				}
			}.toAnyView()
		case .warning:
			return VStack {
				Spacer()
				VStack {
					VStack(alignment: .leading, spacing: 16) {
						HStack {
							Image(systemName: "exclamationmark.circle")
								.resizable()
								.frame(width: 26, height: 26)
							Text("common_warning")
								.font(.system(size: 30, weight: .bold))
						}
						Text("details_twins_recreate_warning")
							.foregroundColor(.tangemTapGrayDark3)
					}
					.font(.system(size: 13, weight: .regular))
					.lineSpacing(8)
					.padding(.horizontal, 30)
					.padding(.bottom, 44)
					HStack(alignment: .center, spacing: 12) {
						TangemButton(isLoading: false,
									 title: "common_back",
									 image: "", action: {
										self.presentationMode.wrappedValue.dismiss()
//										self.navigation.detailsShowTwinsRecreateWarning = false
									 })
							.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
						NavigationButton(button: button,
										 navigationLink: NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly.makeTwinsWalletCreationViewModel(isRecreating: true)),
																		isActive: $navigation.onboardingOpenTwinCardWalletCreation))
							.buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
					}
					.padding(buttonEdgeInsets)
				}
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
//		TwinCardOnboardingView(viewModel: assembly.makeTwinCardOnboardingViewModel(isFromMain: false))
		TwinCardOnboardingView(viewModel: assembly.makeTwinCardWarningViewModel())
			.environmentObject(assembly.navigationCoordinator)
			.previewGroup(devices: [.iPhone11ProMax])
	}
}
