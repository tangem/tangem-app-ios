//
//  CardOperationView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


struct CardOperationView: View {
    var title: String
    var buttonTitle: LocalizedStringKey = "common_save_changes"
    var alert: String
    var actionButtonPressed: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State var error: AlertBinder?
    @State var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 24.0) {
            Spacer()
            Image("exclamationmark.circle")
                .font(.system(size: 120.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapWarning)
            Text("common_warning".localized.uppercased())
                .font(.system(size: 40.0, weight: .medium, design: .default))
                .foregroundColor(.tangemTapWarning)
            Text(alert)
                .font(.system(size: 29.0, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemTapGrayDark6)
                .padding(.horizontal, 36.0)
            Spacer()
            HStack(alignment: .center, spacing: 8.0) {
                Spacer()
                TangemLongButton(isLoading: self.isLoading,
                             title: buttonTitle,
                             image: "save") {
                                self.isLoading = true
                                self.actionButtonPressed {result in
                                    DispatchQueue.main.async {
                                        self.isLoading = false
                                        switch result {
                                        case .success:
                                            self.presentationMode.wrappedValue.dismiss()
                                        case .failure(let error):
                                            if case .userCancelled = error.toTangemSdkError() {
                                                return
                                            }
                                            
                                            self.error = error.alertBinder
                                        }
                                    }
                                }
                }.buttonStyle(TangemButtonStyle(color: .black,
                                                isDisabled: false))
                    .alert(item: self.$error) { $0.alert }
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
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
