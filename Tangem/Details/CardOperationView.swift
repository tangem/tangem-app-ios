//
//  CardOperationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct CardOperationView: View {
    var title: String
    var buttonTitle: LocalizedStringKey = "common_save_changes"
    var shouldPopToRoot: Bool = false
    var alert: String
    var actionButtonPressed: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var assembly: Assembly
    @EnvironmentObject var navigation: NavigationCoordinator
    @State var error: AlertBinder?
    @State var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 24.0) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 120.0, weight: .regular, design: .default))
                .foregroundColor(.tangemWarning)
            Text("common_warning".localized.uppercased())
                .font(.system(size: 40.0, weight: .medium, design: .default))
                .foregroundColor(.tangemWarning)
            Text(alert)
                .font(.system(size: 29.0, weight: .regular, design: .default))
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemGrayDark6)
                .padding(.horizontal, 36.0)
            Spacer()
            TangemButton(title: buttonTitle) {
                            self.isLoading = true
                            self.actionButtonPressed {result in
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    switch result {
                                    case .success:
                                        if self.shouldPopToRoot {
                                            DispatchQueue.main.async {
                                                self.assembly.getLetsStartOnboardingViewModel()?.reset()
                                                self.assembly.getLaunchOnboardingViewModel().reset()
                                                self.navigation.popToRoot()
                                            }
                                        } else {
                                            self.presentationMode.wrappedValue.dismiss()
                                        }
                                    case .failure(let error):
                                        if case .userCancelled = error.toTangemSdkError() {
                                            return
                                        }
                                        
                                        self.error = error.alertBinder
                                    }
                                }
                            }
            }.buttonStyle(TangemButtonStyle(colorStyle: .black,
                                            layout: .flexibleWidth,
                                            isLoading: self.isLoading))
                .alert(item: self.$error) { $0.alert }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(title)
    }
}


struct CardOperationVIew_Previews: PreviewProvider {
    static var previews: some View {
        CardOperationView(title: "Manage",
                          alert: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Et quis vitae dictumst consequat.",
                          actionButtonPressed: { _ in })
    }
}
