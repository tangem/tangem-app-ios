//
//  AddressBookContactsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddressBookContactsListView: View {
    @ObservedObject var viewModel: AddressBookContactsListViewModel

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

#Preview {
    AddressBookContactsListView(
        viewModel: AddressBookContactsListViewModel(coordinator: AddressBookCoordinator())
    )
}
