//
//  SendView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @ObservedObject private var viewModel: SendViewModel

    init(viewModel: SendViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct SendView_Preview: PreviewProvider {
    static let viewModel = SendViewModel(coordinator: SendCoordinator())

    static var previews: some View {
        SendView(viewModel: viewModel)
    }
}
