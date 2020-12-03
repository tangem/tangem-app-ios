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
	
	@State var alert: AlertBinder?
	
    var body: some View {
		VStack(spacing: 0) {
			NavigationBar(title: viewModel.isRecreatingWallet ? "details_twins_recreate_toolbar" : "details_row_title_twins_create",
						  settings: .init(horizontalPadding: 8),
						  backAction: {
							if self.viewModel.step == .first {
								self.dismiss()
							} else {
								self.alert = AlertBinder(alert: Alert(title: Text("twins_creation_warning_title"),
												   message: Text("twins_creation_warning_message"),
								 primaryButton: Alert.Button.destructive(Text("common_ok"), action: {
								   self.dismiss()
								 }),
								 secondaryButton: Alert.Button.default(Text("common_cancel"))))
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
				.animation(.easeOut)
				.transition(.opacity)
				.frame(height: 3)
				ZStack {
					Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.firstTwinCardImage : viewModel.secondTwinCardImage)
						.resizable()
						.frame(width: 108, height: 57)
						.offset(x: 22, y: -1.5)
						.opacity(viewModel.step >= .second ? 1 : 0.0)
						.animation(.easeOut)
						.transition(.opacity)
					Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.secondTwinCardImage : viewModel.firstTwinCardImage)
						.resizable()
						.frame(width: 108, height: 57)
						.offset(y: 11)
				}
				.frame(height: 104, alignment: .leading)
				Text(viewModel.title)
					.font(.system(size: 30, weight: .bold))
				Text(viewModel.step.hint)
				Spacer()
				HStack {
					Spacer()
					TangemLongButton(isLoading: false,
									 title: viewModel.buttonTitle,
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
			.navigationBarTitle("")
			.navigationBarBackButtonHidden(true)
			.navigationBarHidden(true)
		}
		.onDisappear(perform: {
			guard self.viewModel.isDismissing else { return }
			self.viewModel.onDismiss()
			if self.navigation.onboardingOpenTwinCardWalletCreation {
				self.navigation.onboardingOpenTwinCardWalletCreation = false
			}
		})
		.onAppear(perform: {
			self.viewModel.onAppear()
		})
		.onReceive(viewModel.$error, perform: { error in
			self.alert = error
		})
		.onReceive(viewModel.$finishedWalletCreation, perform: { isWalletsCreated in
			if isWalletsCreated {
				self.alert = AlertBinder(alert: Alert(title: Text("common_success"),
													  message: Text("notification_twins_recreate_success"),
									dismissButton: .default(Text("common_ok"), action: {
									  self.dismiss()
									})))
			}
		})
		.alert(item: $alert) { $0.alert }
    }
	
	private func dismiss() {
		viewModel.isDismissing = true
		if self.navigation.detailsShowTwinsRecreateWarning {
			self.navigation.detailsShowTwinsRecreateWarning = false

		} else if self.navigation.showTwinsWalletCreation {
			self.navigation.showTwinsWalletCreation = false
		}
	}
}

struct TwinsWalletCreationView_Previews: PreviewProvider {
    static var previews: some View {
		TwinsWalletCreationView(viewModel: Assembly.previewAssembly.makeTwinsWalletCreationViewModel(isRecreating: false))
			.deviceForPreview(.iPhone11Pro)
    }
}
