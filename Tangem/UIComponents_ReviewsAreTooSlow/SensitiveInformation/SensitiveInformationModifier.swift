//
//  SensitiveInformationModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SensitiveInformationModifier: ViewModifier {
    let showSensitiveInformation: Bool

    func body(content: Content) -> some View {
        if showSensitiveInformation {
            content
        } else {
            Text("•••")
        }
    }
}

extension Text {
    @ViewBuilder
    func showSensitiveInformation(_ showSensitiveInformation: Bool) -> some View {
        modifier(
            SensitiveInformationModifier(showSensitiveInformation: showSensitiveInformation)
        )
    }
}

fileprivate struct SensitiveInformationTestView: View {
    @State var showBalance = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showBalance.toggle()
            } label: {
                Image(systemName: showBalance ? "eye" : "eye.slash")
            }

            HStack {
                Text("$1 000 000,00")
                    .showSensitiveInformation(showBalance)
                    .font(.system(.largeTitle))
                    .border(Color.red)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SensitiveInformation_Previews: PreviewProvider {
    static var previews: some View {
        SensitiveInformationTestView()
            .padding()
            .previewLayout(.fixed(width: 300, height: 200))
    }
}
