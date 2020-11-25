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
        }
        .foregroundColor(.tangemTapGrayDark6)
        .navigationBarTitle("disclaimer_title")
        .navigationBarBackButtonHidden(viewModel.state == .accept)
    }
	
	private var button: some View {
		let button = TangemLongButton(isLoading: false,
					 title: "common_accept",
					 image: "arrow.right") {
			self.viewModel.accept()
		}
		.buttonStyle(TangemButtonStyle(color: .green))
		
		if viewModel.isTwinCard && !navigation.openMainFromDisclaimer {
			return NavigationButton(button: button,
									navigationLink: NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardOnboardingViewModel(isFromMain: false)),
														   isActive: $navigation.openTwinCardOnboarding))
				.toAnyView()
		} else {
			return NavigationButton(button: button,
							 navigationLink: NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
															isActive: $navigation.openMainFromDisclaimer))
				.toAnyView()
		}
	}
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
		DisclaimerView(viewModel: Assembly.previewAssembly.makeDisclaimerViewModel())
    }
}
