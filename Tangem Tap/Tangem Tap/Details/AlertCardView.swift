//
//  AlertCardView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AlertCardView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(self.title)
                .font(Font.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(.white)
            Text(self.message)
                .font(Font.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(.tangemTapGrayDark)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
                .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 0, idealHeight: 0, maxHeight: 0, alignment: .center)
        }
            .padding(.horizontal, 24.0)
            .padding(.vertical, 16.0)
            .background(Color.tangemTapGrayDark6)
            .cornerRadius(6.0)
    }
}

struct AlertCardView_Previews: PreviewProvider {
    static var previews: some View {
        AlertCardView(title: "Warning", message: "Tangem cards manufactured before September 2019 cannot currently be extracted with an iPhone. We’re working hard with Apple to make it possible in future versions of iOS.")
    }
}
