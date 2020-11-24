//
//  TwinsWalletCreationView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct SimpleProgressBar: View {
	
	var isSelected: Bool
	
	var body: some View {
		isSelected ?
			Color.tangemTapBlue :
			Color.tangemTapBlueLight2
	}
	
}

struct TwinsWalletCreationView: View {
	
	@EnvironmentObject var navigation: NavigationCoordinator
	@ObservedObject var viewModel: TwinsWalletCreationViewModel
	
	@Binding var isFromDetails: Bool
	
	init(viewModel: TwinsWalletCreationViewModel, isFromDetails: Binding<Bool> = .constant(false)) {
		self.viewModel = viewModel
		self._isFromDetails = isFromDetails
	}
	
    var body: some View {
		return VStack(spacing: 0) {
			NavigationBar(title: viewModel.isRecreatingWallet ? "details_twins_recreate_toolbar" : "details_row_title_twins_create",
						  settings: .init(horizontalPadding: 8),
						  backAction: {
							withAnimation {
								if self.viewModel.step == .first {
									if self.navigation.showTwinsWalletCreation {
										self.navigation.showTwinsWalletCreation = false
//
									} else {
//										self.dismissToDetails()
										self.isFromDetails = false
//										self.viewModel.navigation.detailsShowTwinsRecreateWarning = false
//										self.viewModel.navigation.onboardingOpenTwinCardWalletCreation = false
									}
//
								} else {
									self.viewModel.backAction()
								}
							}
						  })
			VStack(alignment: .leading, spacing: 8) {
				Text(viewModel.step.stepTitle)
					.font(.system(size: 30, weight: .bold))
					.foregroundColor(.tangemTapBlue)
				HStack {
					SimpleProgressBar(isSelected: true)
					SimpleProgressBar(isSelected: viewModel.step >= .second)
					SimpleProgressBar(isSelected: viewModel.step >= .third)
					
				}
				.frame(height: 3)
				ZStack {
					Image("twinSmall")
						.offset(x: 22, y: -1.5)
						.opacity(viewModel.step >= .second ? 1 : 0.0)
					Image("twinSmall")
						.offset(y: 11)
				}
				.frame(height: 104, alignment: .leading)
				Text(viewModel.step.title)
					.font(.system(size: 30, weight: .bold))
				Text(viewModel.step.hint)
				Spacer()
				HStack {
					Spacer()
					TangemLongButton(isLoading: false,
									 title: viewModel.step.buttonTitle,
									 image: "scan") {
						withAnimation {
							self.viewModel.buttonAction()
						}
					}
					.buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
				}
				.padding(.bottom, 16)
			}
			.padding(.horizontal, 24)
			.background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
			.foregroundColor(.tangemTapGrayDark6)
			.navigationBarTitle("Twins")
			.navigationBarBackButtonHidden(true)
			.navigationBarHidden(true)
		}
		.alert(item: $viewModel.error) { $0.alert }
		.alert(isPresented: $viewModel.doneAlertPresented, content: {
			Alert(title: Text("common_success"),
				  message: Text("notification_twins_recreate_success"),
				  dismissButton: .default(Text("common_ok"), action: {
					
//					if self.navigation.detailsShowTwinsRecreateWarning {
//						self.navigation.detailsShowTwinsRecreateWarning = false
//
//					} else if self.navigation.showTwinsWalletCreation {
//						self.navigation.showTwinsWalletCreation = false
//					}
					
				  }))
		})
    }
}

struct TwinsWalletCreationView_Previews: PreviewProvider {
    static var previews: some View {
		TwinsWalletCreationView(viewModel: Assembly.previewAssembly.makeTwinsWalletCreationViewModel(isRecreating: false))
			.deviceForPreview(.iPhone11Pro)
    }
}
