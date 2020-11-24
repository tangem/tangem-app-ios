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
	
	@Binding var isFromDetails: Bool
	@State var isDisplayingTwinCreation: Bool = false
	
	init(viewModel: TwinCardOnboardingViewModel, isFromDetails: Binding<Bool> = .constant(false)) {
		self.viewModel = viewModel
		self._isFromDetails = isFromDetails
	}
	
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
						Image("twin")
							.resizable()
							.frame(width: 316, height: 166)
							.cornerRadius(9)
							.shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
							.offset(x: -57)
							.rotationEffect(.init(degrees: -22))
						Image("twin")
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
			content()
			if navigation.onboardingOpenMain, viewModel.state != .warning {
				NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
							   isActive: $navigation.onboardingOpenMain)
			}
//			if isDisplayingTwinCreation {
//			if viewModel.navigation.onboardingOpenTwinCardWalletCreation {
//				NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly.makeTwinsWalletCreationViewModel(isRecreating: true), isFromDetails: self.$isFromDetails, dismissToDetails: dismissToDetails),
//				NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly.makeTwinsWalletCreationViewModel(isRecreating: true)),
//							   isActive: $isDisplayingTwinCreation)
//					.isDetailLink(false)
//			}
		}
		.navigationBarTitle("Onboarding")
		.navigationBarHidden(true)
		.navigationBarBackButtonHidden(true)
		.background(Color(.tangemTapBgGray2).edgesIgnoringSafeArea(.all))
	}
	
	private func content() -> some View {
		let bottomButton = HStack {
			Spacer()
			TangemLongButton(isLoading: false, title: viewModel.state.buttonTitle, image: "arrow.right", action: {
					  self.viewModel.buttonAction()
				  })
				  .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
				  .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 34))
			  }
		
		switch viewModel.state {
		case .onboarding(let pairCid):
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
				.font(.system(size: 14, weight: .regular))
				.lineSpacing(8)
				.padding(.horizontal, 37)
				.padding(.bottom, 28)
				bottomButton
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
					.font(.system(size: 14, weight: .regular))
					.lineSpacing(8)
					.padding(.horizontal, 37)
					.padding(.bottom, 44)
					NavigationLink(
						destination: TwinsWalletCreationView(viewModel: viewModel.assembly.makeTwinsWalletCreationViewModel(isRecreating: true), isFromDetails: $isFromDetails),
						label: {
							Text("common_start")
//							TangemLongButton(isLoading: false, title: viewModel.state.buttonTitle, image: "arrow.right", action: {} )
//								.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
//								.padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 34))
						}
					)
//					NavigationLink(destination: TwinsWalletCreationView(viewModel: viewModel.assembly.makeTwinsWalletCreationViewModel(isRecreating: true)),
//								   isActive: $isDisplayingTwinCreation)
//					bottomButton
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
	static var previews: some View {
		TwinCardOnboardingView(viewModel: Assembly.previewAssembly.makeTwinCardOnboardingViewModel())
			.previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone11Pro, .iPhone11ProMax])
	}
}

typealias DismissToParent = () -> Void

struct ParentDismissingModeKey: EnvironmentKey {
	static let defaultValue: DismissToParent = {}
}

extension EnvironmentValues {
	var parentDismissMode: DismissToParent {
		get { return self[ParentDismissingModeKey.self] }
		set { self[ParentDismissingModeKey.self] = newValue }
	}
}
