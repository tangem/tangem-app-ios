//
//  ReceiveBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct ReceiveBottomSheetView: View {
    @ObservedObject var viewModel: ReceiveBottomSheetViewModel

    var body: some View {
        VStack {
            if viewModel.isUserUnderstandNetwork {
                addressPager
            } else {
                networkUnderstandingConfirmation
            }
        }
        .animation(.easeInOut, value: viewModel.isUserUnderstandNetwork)
    }

    @ViewBuilder
    private var networkUnderstandingConfirmation: some View {
        VStack(spacing: 56) {
            TokenIconView(
                viewModel: viewModel.tokenIconViewModel,
                sizeSettings: .receive
            )
            .padding(.top, 56)

            Text(viewModel.networkWarningMessage)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .padding(.horizontal, 60)

            MainButton(
                title: Localization.commonUnderstand,
                action: viewModel.understandNetworkRequirements
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    @State private var containerSize: CGSize = .zero

    private var qrCodeWidthMultiplier: CGFloat { 0.7 }
    private var addressWidthMultiplier: CGFloat { 0.67 }

    @ViewBuilder
    private var addressPager: some View {
        VStack {
            PagerView(
                0 ..< viewModel.addressInfos.count,
                indexUpdateNotifier: viewModel.addressIndexUpdateNotifier,
                currentIndex: $viewModel.currentIndex
            ) { index in
                VStack {
                    Text(viewModel.headerForAddress(at: index))
                        .multilineTextAlignment(.center)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                    Image(uiImage: viewModel.qrImageForAddress(at: 0))
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fill)
                        .frame(size: containerSize * qrCodeWidthMultiplier)
                        .readSize { size in
                            containerSize = size
                        }

                    Text(viewModel.addressInfos[index].address)
                        .frame(width: containerSize.width * addressWidthMultiplier)
                }
            }

            Text(viewModel.warningMessageFull)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)

            HStack(spacing: 12) {
                MainButton(
                    title: Localization.commonCopy,
                    icon: .leading(Assets.copy),
                    style: .secondary,
                    action: viewModel.copyToClipboard
                )

                MainButton(
                    title: Localization.commonShare,
                    icon: .leading(Assets.share),
                    style: .secondary,
                    action: viewModel.share
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 8)
        }
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }
}

struct ReceiveAddressInfo: Identifiable, Hashable {
    var id: String { type.rawValue }
    let address: String
    let type: AddressType
}

struct TokenInfoExtractor {
    let type: Amount.AmountType
    let blockchain: Blockchain

    var name: String {
        switch type {
        case .token(let token): return token.name
        default: return blockchain.displayName
        }
    }

    var currencySymbol: String {
        switch type {
        case .token(let token): return token.symbol
        default: return blockchain.currencySymbol
        }
    }

    var networkName: String {
        blockchain.displayName
    }

    var iconViewModel: TokenIconViewModel {
        .init(with: type, blockchain: blockchain)
    }
}

class ReceiveBottomSheetViewModel: ObservableObject, Identifiable {
    let id = UUID()

    let tokenIconViewModel: TokenIconViewModel

    let networkWarningMessage: String

    // From WalletModel
    let addressInfos: [ReceiveAddressInfo]

    @Published var isUserUnderstandNetwork: Bool = true
    @Published var currentIndex: Int = 0

    let addressIndexUpdateNotifier = PassthroughSubject<Void, Never>()

    var warningMessageFull: String {
        Localization.receiveBottomSheetWarningMessageFull(tokenInfoExtractor.currencySymbol)
    }

    private let tokenInfoExtractor: TokenInfoExtractor

    init(tokenInfoExtractor: TokenInfoExtractor, addressInfos: [ReceiveAddressInfo]) {
        self.tokenInfoExtractor = tokenInfoExtractor
        tokenIconViewModel = tokenInfoExtractor.iconViewModel
        self.addressInfos = addressInfos

        networkWarningMessage = Localization.receiveBottomSheetWarningMessage(
            tokenInfoExtractor.name,
            tokenInfoExtractor.currencySymbol,
            tokenInfoExtractor.networkName
        )
    }

    func headerForAddress(at index: Int) -> String {
        let info = addressInfos[index]
        return Localization.receiveBottomSheetTitle(
            info.type.rawValue.capitalizingFirstLetter(),
            tokenInfoExtractor.currencySymbol,
            tokenInfoExtractor.networkName
        )
    }

    func qrImageForAddress(at index: Int) -> UIImage {
        QrCodeGenerator.generateQRCode(from: addressInfos[index].address)
    }

    func understandNetworkRequirements() {
        withAnimation {
            isUserUnderstandNetwork.toggle()
        }
    }

    func copyToClipboard() {
        Analytics.log(.buttonCopyAddress)
        UIPasteboard.general.string = addressInfos[currentIndex].address
    }

    func share() {
        Analytics.log(.buttonShareAddress)
        let address = addressInfos[currentIndex].address
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
}

class FakeReceiveBottomSheetInfoProvider {}

struct ReceiveBottomSheet_Previews: PreviewProvider {
    static var sheetViewModel: ReceiveBottomSheetViewModel {
        ReceiveBottomSheetViewModel(
            tokenInfoExtractor: .init(
                type: .ethTetherMock,
                blockchain: .polygon(testnet: false)
            ),
            addressInfos: [
                .init(
                    address: "0x0b3f868e0be5597d5db7feb59e1cadbb0fdda50a",
                    type: .default
                ),
                .init(
                    address: "legacy0x0b3f868e0be5597d5db7feb59e1cadbb0fdda50a",
                    type: .legacy
                ),
            ]
        )
    }

    static var previews: some View {
        NavigationView {
            StatefulPreviewWrapper(
                Optional(
                    sheetViewModel
                )
            ) { viewModel in
                VStack {
                    Button("Show sheet") {
                        viewModel.wrappedValue = nil
                        viewModel.wrappedValue = sheetViewModel
                    }
                    .padding()

                    NavHolder()
                        .bottomSheet(item: viewModel) { model in
                            ReceiveBottomSheetView(viewModel: model)
                        }
                }
            }
            .navigationBarItems(trailing: menu)
        }
    }

    static var menu: some View {
        Menu {
            Text("Hello, World")
        } label: {
            NavbarDotsImage()
        }
    }
}
