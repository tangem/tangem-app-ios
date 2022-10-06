//
//  KYCWaitingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct KYCWaitingView: View {
    var body: some View {
        VStack {
            Spacer()

            Image(name: "success_waiting")
                .padding(.bottom, 36)
            
            Spacer()
        }
      
    }
}

struct KYCWaitingView_Previews: PreviewProvider {
    static var previews: some View {
        KYCWaitingView()
    }
}
