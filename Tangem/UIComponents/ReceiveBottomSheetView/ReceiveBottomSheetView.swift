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

    @State private var containerWidth: CGFloat = 0

    private var qrCodeWidthMultiplier: CGFloat { 0.7 }
    private var addressWidthMultiplier: CGFloat { 0.67 }

    @ViewBuilder
    private var addressPager: some View {
        VStack(spacing: 0) {
            BottomSheetPagerView(
                0 ..< viewModel.addressInfos.count,
                indexUpdateNotifier: viewModel.addressIndexUpdateNotifier,
                currentIndex: $viewModel.currentIndex,
                width: containerWidth
            ) { index in
                VStack(spacing: 28) {
                    Text(viewModel.headerForAddress(at: index))
                        .multilineTextAlignment(.center)
                        .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                        .padding(.horizontal, 60)

                    Image(uiImage: viewModel.qrImageForAddress(at: index))
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: containerWidth * qrCodeWidthMultiplier)

                    Text(viewModel.addressInfos[index].address)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                        .frame(width: containerWidth * addressWidthMultiplier)
                        .truncationMode(/*@START_MENU_TOKEN@*/.middle/*@END_MENU_TOKEN@*/)
                }
            }
            .padding(.top, 28)
            .frame(width: containerWidth)

            Text(viewModel.warningMessageFull)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
                .padding(.top, 12)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

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
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .readGeometry(to: $containerWidth, transform: \.size.width)
    }
}

struct BottomSheetPagerView<Data, Content>: View
where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
    let indexUpdateNotifier: PassthroughSubject<Void, Never>
    // the source data to render, can be a range, an array, or any other collection of Hashable
    private let data: Data
    // the index currently displayed page
    @Binding var currentIndex: Int
    // maps data to page views
    private let content: (Data.Element) -> Content

    // keeps track of how much did user swipe left or right
    @GestureState private var translation: CGFloat = 0

//    [REDACTED_USERNAME] private var containerSize: CGSize = .zero
    private let width: CGFloat

    // the custom init is here to allow for @ViewBuilder for
    // defining content mapping
    init(
        _ data: Data,
        indexUpdateNotifier: PassthroughSubject<Void, Never>,
        currentIndex: Binding<Int>,
        width: CGFloat,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.indexUpdateNotifier = indexUpdateNotifier
        _currentIndex = currentIndex
        self.width = width
        self.content = content
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .top, spacing: 0) {
                // render all the content, making sure that each page fills
                // the entire PagerView
                ForEach(data, id: \.self) { elem in
                    content(elem)
                        .frame(width: width)
                }
            }
            .frame(width: width, alignment: .leading)
            // the first offset determines which page is shown
            .offset(x: -CGFloat(currentIndex) * width)
            // the second offset translates the page based on swipe
            .offset(x: translation)
            .animation(.easeOut(duration: 0.3), value: currentIndex)
            .animation(.easeOut(duration: 0.2), value: translation)
            .gesture(
                data.count <= 1 ? nil :
                DragGesture().updating($translation) { value, state, _ in
                    state = value.translation.width
                }.onEnded { value in
                    // determine how much was the page swiped to decide if the current page
                    // should change (and if it's going to be to the left or right)
                    // 1.25 is the parameter that defines how much does the user need to swipe
                    // for the page to change. 1.0 would require swiping all the way to the edge
                    // of the screen to change the page.
                    let offset = value.translation.width / width * 2
                    let newIndex = (CGFloat(currentIndex) - offset).rounded()
                    currentIndex = min(max(Int(newIndex), 0), data.count - 1)
                    indexUpdateNotifier.send()
                }
            )

            if data.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0 ..< data.count, id: \.id) { index in
                        Circle()
                            .foregroundColor((index == currentIndex) ? Colors.Icon.primary1 : Colors.Icon.informative)
                            .animation(.easeOut(duration: 0.5), value: currentIndex)
                            .frame(width: 7, height: 7)
                    }
                }
                .frame(width: width, height: 20, alignment: .center)
            }
        }
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

struct ReceiveBottomSheet_Previews: PreviewProvider {
    static var btcAddressBottomSheet: ReceiveBottomSheetViewModel {
        ReceiveBottomSheetViewModel(
            tokenInfoExtractor: .init(
                type: .coin,
                blockchain: .bitcoin(testnet: false)
            ),
            addressInfos: [
                .init(
                    address: "bc1qeguhvlnxu4lwg48p5sfhxqxz679v3l5fma9u0c",
                    type: .default
                ),
                .init(
                    address: "18VEbRSEASi1npnXnoJ6pVVBrhT5zE6qRz",
                    type: .legacy
                ),
            ]
        )
    }

    static var singleAddressBottomSheet: ReceiveBottomSheetViewModel {
        ReceiveBottomSheetViewModel(
            tokenInfoExtractor: .init(
                type: .ethTetherMock,
                blockchain: .polygon(testnet: false)
            ),
            addressInfos: [
                .init(
                    address: "0xEF08EA3531D219EDE813FB521e6D89220198bcB1",
                    type: .default
                )
            ]
        )
    }

    static var previews: some View {
        NavigationView {
            VStack {
                StatefulPreviewWrapper(
                    Optional(
                        btcAddressBottomSheet
                    )
                ) { viewModel in
                    VStack {
                        Button("BTC address bottom sheet") {
                            viewModel.wrappedValue = nil
                            viewModel.wrappedValue = btcAddressBottomSheet
                        }
                        .padding()

                        NavHolder()
                            .bottomSheet(
                                item: viewModel,
                                settings: .init(backgroundColor: Colors.Background.primary)
                            ) { model in
                                ReceiveBottomSheetView(viewModel: model)
                            }
                    }
                }

                StatefulPreviewWrapper(
                    Optional(
                        singleAddressBottomSheet
                    )
                ) { viewModel in
                    VStack {
                        Button("Single address bottom sheet") {
                            viewModel.wrappedValue = nil
                            viewModel.wrappedValue = singleAddressBottomSheet
                        }
                        .padding()

                        NavHolder()
                            .bottomSheet(
                                item: viewModel,
                                settings: .init(backgroundColor: Colors.Background.primary)
                            ) { model in
                                ReceiveBottomSheetView(viewModel: model)
                            }
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
