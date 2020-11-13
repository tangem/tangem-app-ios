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
    
    var body: some View {
        VStack(alignment: .trailing) {
            ScrollView {
                Text("disclaimer_text")
                    .font(Font.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark2)
                    .padding()
            }
            
            if viewModel.state == .accept {
                TangemLongButton(isLoading: false,
                             title: "common_accept",
                             image: "arrow.right") {
                                self.viewModel.accept()
                }.buttonStyle(TangemButtonStyle(color: .green))
                    .padding([.bottom, .trailing])
            
                if viewModel.navigation.openMainFromDisclaimer {
                    NavigationLink(destination: MainView(viewModel: viewModel.assembly.makeMainViewModel()),
                                   isActive: $viewModel.navigation.openMainFromDisclaimer) {
                        EmptyView()
                    }
                }
            }
        }
        .foregroundColor(.tangemTapGrayDark6)
        .navigationBarTitle("disclaimer_title")
        .navigationBarBackButtonHidden(viewModel.state == .accept)
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView(viewModel: Assembly.previewAssembly.makeDisclaimerViewModel())
    }
}
