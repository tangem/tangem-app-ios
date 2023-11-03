//
//  SendAmountSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class SendAmountSummaryViewModel: Identifiable {
    let z = "A"
}

struct SendAmountSummaryView: View {
    let models = [SendAmountSummaryViewModel(), SendAmountSummaryViewModel()]
    var body: some View {
        VStack {
            GroupedScrollView {
                GroupedSection(models) { model in
                    HStack {
                        Text(model.z)
                            .padding(.vertical)
//                            .frame(maxWidth: .infinity)

                        Spacer()
                    }
                } footer: {
                    DefaultFooterView("ADS")
                }
                .separatorStyle(.single)
            }
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }
}

#Preview {
    SendAmountSummaryView()
}
