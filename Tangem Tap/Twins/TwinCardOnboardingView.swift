//
//  TwinCardOnboardingView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct TwinCardOnboardingView: View {
	
	@ObservedObject var viewModel: TwinCardOnboardingViewModel
	
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
			
			if viewModel.navigation.openMainFromTwinOnboarding {
				NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
							   isActive: $viewModel.navigation.openMainFromTwinOnboarding)
			}
			if viewModel.navigation.openTwinCardWalletCreation {
				NavigationLink(destination: EmptyView(),
							   isActive: $viewModel.navigation.openTwinCardWalletCreation)
			}
		}
		.onDidAppear {
			self.viewModel.didAppear()
		}
		.navigationBarTitle("")
		.navigationBarHidden(true)
		.navigationBarBackButtonHidden(true)
		.background(Color(.tangemTapBgGray2).edgesIgnoringSafeArea(.all))
	}
	
	private func content() -> some View {
		switch viewModel.state {
		case .onboarding:
			return VStack {
				Spacer()
				VStack(alignment: .leading, spacing: 16) {
					Text("twins_onboarding_title")
						.font(.system(size: 30, weight: .bold))
					Text("twins_onboarding_subtitle")
						.font(.system(size: 17, weight: .medium))
					Text("twins_onboarding_description_format")
						.foregroundColor(.tangemTapGrayDark3)
				}
				.font(.system(size: 14, weight: .regular))
				.lineSpacing(8)
				.padding(.horizontal, 37)
				.padding(.bottom, 28)
				HStack {
					Spacer()
					TangemLongButton(isLoading: false, title: "common_continue", image: "arrow.right", action: {
						self.viewModel.buttonAction()
					})
					.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
					.padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 34))
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
					.font(.system(size: 14, weight: .regular))
					.lineSpacing(8)
					.padding(.horizontal, 37)
					.padding(.bottom, 44)
					HStack {
						Spacer()
						TangemLongButton(isLoading: false, title: "common_start", image: "arrow.right", action: {
							self.viewModel.buttonAction()
						})
						.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
						.padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 34))
					}
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
		TwinCardOnboardingView(viewModel: Assembly.previewAssembly.makeTwinCardOnboardingViewModel(state: .onboarding))
			.previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone11Pro, .iPhone11ProMax])
	}
}
