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
    var alert: String
    var actionButtonPressed: (_ completion: @escaping (Result<Void, Error>) -> Void) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State var showErrorAlert = false
    @State var error: Error? = nil
    
    var body: some View {
        VStack(spacing: 24.0) {
            Spacer()
            Image("exclamationmark.circle")
                .font(.system(size: 120.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapWarning)
            Text("common_warning".localized.uppercased())
                .font(.system(size: 29.0, weight: .light, design: .default))
                .foregroundColor(.tangemTapWarning)
            Text(alert)
                .font(.system(size: 16.0, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(.tangemTapGrayDark6)
                .padding(.horizontal, 36.0)
            Spacer()
            HStack(alignment: .center, spacing: 8.0) {
                Spacer()
                Button(action: {
                    self.actionButtonPressed {result in
                        switch result {
                        case .success:
                            self.presentationMode.wrappedValue.dismiss()
                        case .failure(let error):
                            self.error = error
                            self.showErrorAlert = true
                        }
                        
                    }
                }) { HStack(alignment: .center, spacing: 16.0) {
                    Text("common_button_title_save_changes")
                    Spacer()
                    Image("save")
                }.padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .big,
                                               colorStyle: .black,
                                               isDisabled: false))
                .alert(isPresented: self.$showErrorAlert) { () -> Alert in
                    return Alert(title: Text("common_error"),
                                 message: Text(self.error!.localizedDescription),
                                 dismissButton: Alert.Button.default(Text("common_ok"),
                                                                     action: { }))
                    
                }
            }
            .padding(.horizontal, 36.0)
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(title)
    }
}
