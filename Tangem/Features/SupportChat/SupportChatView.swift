//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel
    @Environment(\.dismiss) var dismissAction

    var body: some View {
        VStack {
            Text("Not implemented")

            Button(action: { dismissAction() }, label: {
                Text("Dismiss")
            })
        }
    }
}
