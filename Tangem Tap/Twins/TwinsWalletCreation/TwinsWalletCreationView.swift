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
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
		VStack(spacing: 0) {
			NavigationBar(title: viewModel.isRecreatingWallet ? "details_twins_recreate_toolbar" : "details_row_title_twins_create",
						  settings: .init(horizontalPadding: 8),
						  backAction: {
							if self.viewModel.step == .first {
								self.dismiss(isWalletCreated: false)
							} else {
                                self.viewModel.error = AlertBinder(alert: Alert(title: Text("twins_creation_warning_title"),
												   message: Text("twins_creation_warning_message"),
								 primaryButton: Alert.Button.destructive(Text("common_ok"), action: {
								   self.dismiss(isWalletCreated: false)
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
				//.animation(.easeOut)
				.transition(.opacity)
				.frame(height: 3)
				ZStack {
					Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.secondTwinCardImage : viewModel.firstTwinCardImage)
						.resizable()
						.frame(width: 108, height: 57)
						.offset(x: 22, y: -1.5)
						.opacity(viewModel.step >= .second ? 1 : 0.0)
						.animation(.easeOut)
						.transition(.opacity)
					Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.firstTwinCardImage : viewModel.secondTwinCardImage)
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
					TangemLongButton(isLoading: self.viewModel.isCreationServiceBusy,
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
		}
		.onDisappear(perform: {
			guard self.viewModel.isDismissing else { return }
			self.viewModel.onDismiss()
            
            //important to reset dropped link to false
            navigation.twinOnboardingToTwinWalletCreation = false
            if viewModel.finishedWalletCreation {
                navigation.detailsToTwinsRecreateWarning = false
            }
		})
		.onAppear(perform: {
			self.viewModel.onAppear()
		})
		.onReceive(viewModel.$finishedWalletCreation, perform: { isWalletsCreated in
			if isWalletsCreated {
                self.viewModel.error = AlertBinder(alert: Alert(title: Text("common_success"),
													  message: Text("notification_twins_recreate_success"),
									dismissButton: .default(Text("common_ok"), action: {
									  self.dismiss(isWalletCreated: true)
									})))
			}
		})
        .alert(item: $viewModel.error) { $0.alert }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
	
    private func dismiss(isWalletCreated: Bool) {
        viewModel.isDismissing = true
        
        if navigation.mainToTwinsWalletWarning { //if create wallet from main
            navigation.mainToTwinsWalletWarning = false //skip warning screen
        } else { //if recreate wallet from details
            if isWalletCreated {
                navigation.mainToSettings = false //back directly to main screen
            } else {
                navigation.detailsToTwinsRecreateWarning = false //skip warning screen
            }
        }
    
    }
}

struct TwinsWalletCreationView_Previews: PreviewProvider {
    static var previews: some View {
		TwinsWalletCreationView(viewModel: Assembly.previewAssembly.makeTwinsWalletCreationViewModel(isRecreating: false))
			.deviceForPreview(.iPhone11Pro)
    }
}
