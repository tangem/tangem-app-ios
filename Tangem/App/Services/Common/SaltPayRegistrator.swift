//
//  SaltPayRegistrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import web3swift
import Combine

enum SaltPayRegistratorError: Error {
    case failedToMakeTxData
}

class SaltPayRegistrator {
    
}

class GnosisRegistrator {
    private let settings: GnosisRegistrator.Settings
    private let walletManager: WalletManager
    private var transactionProcessor: EthereumTransactionProcessor { walletManager as! EthereumTransactionProcessor }
    private let cardAddress: String
    
    init(settings: GnosisRegistrator.Settings, walletPublicKey: Data, cardPublicKey: Data, factory: WalletManagerFactory) throws {
        self.settings = settings
        self.walletManager = try factory.makeWalletManager(blockchain: settings.blockchain, walletPublicKey: walletPublicKey)
        self.cardAddress = try Blockchain.ethereum(testnet: false).makeAddresses(from: cardPublicKey, with: nil)[0].value
    }
    
    func checkHasGas() -> AnyPublisher<Bool, Error> {
        walletManager.updatePublisher()
            .map { wallet -> Bool in
                if let coinAmount = wallet.amounts[.coin] {
                    return !coinAmount.isZero
                } else {
                    return false
                }
            }
            .eraseToAnyPublisher()
    }
    
    func sendTransactions(_ transactions: [SignedEthereumTransaction]) -> AnyPublisher<Void, Error> {
        let publishers = transactions.map { walletManager.send($0) }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { responses -> Void in
                print(responses)
            }
            .eraseToAnyPublisher()
    }
    
    func makeSetSpendLimitTx(value: Decimal) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        do {
            let limitAmount = Amount(with: settings.token, value: value)
            let setSpedLimitData = try makeTxData(sig: Signatures.setSpendLimit, address: cardAddress, amount: limitAmount)
            
            return walletManager.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setSpedLimitData.hexString)", amount: nil)
                .tryMap {[settings, walletManager, cardAddress] fees -> Transaction in
                    let params = EthereumTransactionParams(data: setSpedLimitData)
                    var transaction = try walletManager.createTransaction(amount: limitAmount,
                                                                          fee: fees[1],
                                                                          destinationAddress: settings.otpProcessorContractAddress,
                                                                          sourceAddress: cardAddress)
                    transaction.params = params
                    
                    return transaction
                }
                .flatMap {[transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    func makeInitOtpTx(rootOTP: Data, rootOTPCounter: Int) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        let initOTPData = Signatures.initOTP + rootOTP.prefix(16) + Data(count: 46) + rootOTPCounter.bytes2
        
        return walletManager.getFee(to: settings.otpProcessorContractAddress, data: "0x\(initOTPData.hexString)", amount: nil)
            .tryMap {[settings, walletManager, cardAddress] fees -> Transaction in
                let params = EthereumTransactionParams(data: initOTPData)
                var transaction = try walletManager.createTransaction(amount: Amount(with: settings.blockchain, value: 0),
                                                                      fee: fees[1],
                                                                      destinationAddress: settings.otpProcessorContractAddress,
                                                                      sourceAddress: cardAddress)
                transaction.params = params
                
                return transaction
            }
            .flatMap {[transactionProcessor] tx in
                transactionProcessor.buildForSign(tx)
            }
            .eraseToAnyPublisher()
    }

    func makeSetWalletTx() -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        do {
            let setWalletData = try makeTxData(sig: Signatures.setWallet, address: cardAddress, amount: nil)
            
            return walletManager.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setWalletData.hexString)", amount: nil)
                .tryMap {[settings, walletManager, cardAddress] fees -> Transaction in
                    let params = EthereumTransactionParams(data: setWalletData)
                    var transaction = try walletManager.createTransaction(amount: Amount(with: settings.blockchain, value: 0),
                                                                          fee: fees[1],
                                                                          destinationAddress: settings.otpProcessorContractAddress,
                                                                          sourceAddress: cardAddress)
                    transaction.params = params
                    
                    return transaction
                }
                .flatMap {[transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    func makeApprovalTx(value: Decimal) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        let approveAmount = Amount(with: settings.token, value: value)
        
        do {
            let approveData = try makeTxData(sig: Signatures.approve, address: settings.otpProcessorContractAddress, amount: approveAmount)
            
            return walletManager.getFee(to: settings.token.contractAddress, data: "0x\(approveData.hexString)", amount: nil)
                .tryMap {[settings, walletManager] fees -> Transaction in
                    let params = EthereumTransactionParams(data: approveData)
                    var transaction = try walletManager.createTransaction(amount: approveAmount,
                                                                          fee: fees[1],
                                                                          destinationAddress: settings.otpProcessorContractAddress)
                    transaction.params = params
                    
                    return transaction
                }
                .flatMap {[transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    private func makeTxData(sig: Data, address: String, amount: Amount?) throws -> Data {
        let addressData = Data(hexString: address)
        
        guard let amount = amount else {
            return sig + addressData
        }
        
        guard let amountValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: amount.decimals) else {
            throw SaltPayRegistratorError.failedToMakeTxData
        }
        
        var amountString = String(amountValue, radix: 16).remove("0X")
        
        while amountString.count < 64 {
            amountString = "0" + amountString
        }
        
        let amountData = Data(hex: amountString)
        
        return sig + addressData + amountData
    }
}

extension GnosisRegistrator {
    enum Signatures {
        static let approve: Data = "approve(address,uint256)".signedPrefix
        static let setSpendLimit: Data = "setSpendLimit(address,uint256)".signedPrefix
        static let initOTP: Data = "setSpendLimit(address,uint256)".signedPrefix // 0x0ac81ec3
        static let setWallet: Data = "setSpendLimit(address,uint256)".signedPrefix // 0xdeaa59df
    }
}

extension GnosisRegistrator {
    enum Settings {
        case main
        case testnet
        
        var token: BlockchainSdk.Token {
            switch self {
            case .main:
                return .init(name: "WXDAI",
                             symbol: "WXDAI",
                             contractAddress: "0x4346186e7461cB4DF06bCFCB4cD591423022e417",
                             decimalCount: 18)
            case .testnet:
                return .init(name: "WXDAI Test",
                             symbol: "MyERC20",
                             contractAddress: "0x69cca8D8295de046C7c14019D9029Ccc77987A48",
                             decimalCount: 0)
            }
        }
        
        var otpProcessorContractAddress: String {
            switch self {
            case .main:
                return "0x3B4397C817A26521Df8bD01a949AFDE2251d91C2"
            case .testnet:
                return "0x710BF23486b549836509a08c184cE0188830f197"
            }
        }
        
        var blockchain: Blockchain {
            switch self {
            case .main:
                return Blockchain.saltPay(testnet: false)
            case .testnet:
                return Blockchain.saltPay(testnet: true)
            }
        }
    }
}

fileprivate extension String {
    var signedPrefix: Data {
        self.data(using: .utf8)!.sha3(.keccak256).prefix(4)
    }
}

//public class otpSetup {
//    private static final Logger logger = LoggerFactory.getLogger(otpSetup.class);
//
//    String addressTokenContract = "0x69cca8D8295de046C7c14019D9029Ccc77987A48";
//    int decimalsToken = 0;
//    String symbolToken = "MyERC20";
//
//    String sAddressProcessorContract = "0x710BF23486b549836509a08c184cE0188830f197";
//
//    String rpcUrl = "https://rpc-chiado.gnosistestnet.com";
//
//    Blockchain testBlockchain = Blockchain.GnosisChiado;
//
////    String addressTokenContract = "0x4346186e7461cB4DF06bCFCB4cD591423022e417";
////    int decimalsToken = 18;
////    String symbolToken = "WXDAI";
////
////    String sAddressProcessorContract = "0x3B4397C817A26521Df8bD01a949AFDE2251d91C2";
////
////    String rpcUrl = "https://optimism.gnosischain.com";
////
////    Blockchain testBlockchain = Blockchain.GnosisOptimism;
//
//    byte[] pubkeyCard = Util.hexToBytes("04DA2410EC47D6573974B92FE8A549A9590A9D4A75FB8E64DF038E6BF618FFF03C520B43C520700646EE6E65198AFF3F97EA60D08EDF75E1C25539F1D7BDFE5179");
//    String sAddressCard = "0x5c9b5c6313a3746a1246d07bbedc0292da99f8e2";
//
//    Token testToken = new Token(symbolToken, addressTokenContract, decimalsToken);
//    HashSet<Token> testTokens = new HashSet<>();
//    Wallet walletCard;
//
//    EthereumTransactionBuilder transactionBuilderCard;
//    List<EthereumJsonRpcProvider> rpcProviders = new ArrayList<EthereumJsonRpcProvider>();
//    EthereumNetworkService networkService;
//
//    Address addressCard;
//    HashSet<Address> addressesCard ;
//
//    void testInit() {
//        CryptoUtils.INSTANCE.initCrypto();
//
//        addressCard = new Address(sAddressCard, testBlockchain.defaultAddressType());
//        addressesCard = new HashSet<Address>();
//        addressesCard.add(addressCard);
//        testTokens.add(testToken);
//
//        walletCard = new Wallet(testBlockchain, addressesCard, new Wallet.PublicKey(pubkeyCard, null, null), testTokens);
//
//        transactionBuilderCard = new EthereumTransactionBuilder(pubkeyCard, testBlockchain);
//
//        rpcProviders.add(new EthereumJsonRpcProvider(rpcUrl, ""));
//        networkService = new EthereumNetworkService(rpcProviders);
//    }
//
//    public void setCardAddress(byte[] walletPublicKey) {
//        if( walletPublicKey != null ) {
//            pubkeyCard = walletPublicKey;
//            sAddressCard = (new EthereumAddressService()).makeAddress(pubkeyCard, EllipticCurve.Secp256k1);
//            testInit();
//        }else{
//            pubkeyCard = new byte[]{};
//            sAddressCard = "";
//            testInit();
//        }
//    }
//
//
//    public void doSetup(Reader.UiCallbacks uiCallbacks, BigDecimal approveValue, BigDecimal spendLimit, byte[] otp, int otpCounter, TransactionSimpleSigner signer) throws Exception {
//        testInit();
//
//        EthereumWalletManager walletManager = new EthereumWalletManager(walletCard, transactionBuilderCard, networkService, testTokens);
//
//        doApprove(uiCallbacks, walletManager, signer, approveValue);
//
//        setWallet(uiCallbacks, walletManager, signer);
//
//        setSpendLimit(uiCallbacks, walletManager, signer, spendLimit);
//
//        initOTP(uiCallbacks, walletManager, signer, otp, otpCounter);
//
//        doUpdate(uiCallbacks, walletManager);
//        doGetAllowance(uiCallbacks, walletManager);
//    }
//
//    private void initOTP(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager, TransactionSimpleSigner signer, byte[] otpRoot, int otpRootCounter) throws Exception {
//        // Init OTP
//        uiCallbacks.onStart("Init OTP");
//        doUpdate(uiCallbacks,walletManager);
//
//        Result<List<Amount>> fees = walletManager.getFeeToInitOTPAsync(sAddressProcessorContract, otpRoot, otpRootCounter ).get();
//        Amount feeAmount=extractFeeAmount(uiCallbacks,walletManager,fees);
//        uiCallbacks.onOkay("Gas limit: " + walletManager.getGasLimitToApprove());
//        uiCallbacks.onOkay("Init otp fee: " + feeAmount.toString());
//
//        TransactionToSign transactionToSign = walletManager.getTransactionBuilder().buildInitOTPToSign(sAddressProcessorContract, sAddressCard, otpRoot, otpRootCounter, feeAmount, walletManager.getGasLimitToInitOTP(), BigInteger.valueOf(walletManager.getTxCount()));
//
//        if(!signAndSend(signer, transactionToSign, uiCallbacks, walletManager))
//        {
//            throw new Exception("Can't set wallet");
//        }
//        uiCallbacks.onOkay("Set wallet result: OK");
//        uiCallbacks.onSeparator();
//
//    }
//
//    private void doGetAllowance(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager) throws Exception {
//        uiCallbacks.onStart("Get allowance");
//        Result<Amount> allowance= walletManager.getALlowanceAsync(sAddressProcessorContract,testToken).get();
//        if( allowance instanceof Result.Failure )
//        {
//            uiCallbacks.onError(((Result.Failure) allowance).getError().getCustomMessage());
//            throw new Exception("Can't get allowance");
//        }
//        uiCallbacks.onOkay("Allowance : " + new GsonBuilder().setPrettyPrinting().create().toJson(allowance));
//        uiCallbacks.onSeparator();
//    }
//
//    private void setSpendLimit(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager, TransactionSimpleSigner signer, BigDecimal spendLimit) throws Exception {
//        // Set spend limit
//        uiCallbacks.onStart("Set spend limit");
//        Amount limitAmount=new Amount(testToken, spendLimit);
//
//        doUpdate(uiCallbacks,walletManager);
//
//        Result<List<Amount>> fees = walletManager.getFeeToSetSpendLimitAsync(sAddressProcessorContract, limitAmount).get();
//        Amount feeAmount = extractFeeAmount(uiCallbacks,walletManager,fees);
//        uiCallbacks.onOkay("Gas limit: " + walletManager.getGasLimitToSetSpendLimit());
//        uiCallbacks.onOkay("Set spend limit fee: " + feeAmount.toString());
//
//        TransactionToSign transactionToSign = walletManager.getTransactionBuilder().buildSetSpendLimitToSign(sAddressProcessorContract, sAddressCard, limitAmount, feeAmount, walletManager.getGasLimitToSetSpendLimit(), BigInteger.valueOf(walletManager.getTxCount()));
//
//        if(! signAndSend(signer, transactionToSign, uiCallbacks, walletManager) )
//        {
//            throw new Exception("Can't set spend limit");
//        }
//        uiCallbacks.onOkay("Set spend limit result: OK");
//        uiCallbacks.onSeparator();
//    }
//
//    private void setWallet(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager, TransactionSimpleSigner signer) throws Exception {
//        uiCallbacks.onStart("Set wallet");
//        doUpdate(uiCallbacks,walletManager);
//
//        Result<List<Amount>> fees = walletManager.getFeeToSetWalletAsync(sAddressProcessorContract).get();
//        Amount feeAmount = extractFeeAmount(uiCallbacks, walletManager, fees);
//        uiCallbacks.onOkay("Gas limit: " + walletManager.getGasLimitToSetWallet());
//        uiCallbacks.onOkay("Set wallet fee: " + feeAmount.toString());
//
//        TransactionToSign transactionToSign = walletManager.getTransactionBuilder().buildSetWalletToSign(sAddressProcessorContract, sAddressCard, feeAmount, walletManager.getGasLimitToSetWallet(), BigInteger.valueOf(walletManager.getTxCount()));
//
//        if(!signAndSend(signer, transactionToSign, uiCallbacks, walletManager))
//        {
//            throw new Exception("Can't set wallet");
//        }
//        uiCallbacks.onOkay("Set wallet result: OK");
//        uiCallbacks.onSeparator();
//    }
//
//    private boolean signAndSend(TransactionSimpleSigner signer, TransactionToSign transactionToSign, Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager) throws Exception {
//        uiCallbacks.onSeparator();
//        byte[] signature = signer.sign(transactionToSign.getHash(), new Wallet.PublicKey(pubkeyCard,null,null));
//        if (signature == null) {
//            throw new Exception("Can't get signature from card");
//        }
//        uiCallbacks.onSeparator();
//
//        uiCallbacks.onMessageSendHeader(EthereumExtensionsKt.toPrettyString(transactionToSign.getTransaction()));
//        SimpleResult result = walletManager.sendRawAsync(transactionToSign, signature).get();
//        if (result instanceof SimpleResult.Failure) {
//            uiCallbacks.onError(((SimpleResult.Failure) result).getError().getCustomMessage());
//            return false;
//        }
//        uiCallbacks.onOkay("OK");
//        return true;
//    }
//
//    private void doApprove(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager, TransactionSimpleSigner signer, BigDecimal approveValue) throws Exception {
//        // Approve
//        uiCallbacks.onStart("Approve");
//        doUpdate(uiCallbacks, walletManager);
//
//        Amount approveAmount=new Amount(testToken, approveValue);
//        Result<List<Amount>> fees = walletManager.getFeeToApproveAsync(approveAmount, sAddressProcessorContract).get();
//        Amount feeAmount = extractFeeAmount(uiCallbacks, walletManager, fees);
//        uiCallbacks.onOkay("Gas limit: " + walletManager.getGasLimitToApprove());
//        uiCallbacks.onOkay("Approve fee: " + feeAmount.toString());
//        uiCallbacks.onSeparator();
//
//        TransactionData transactionData = walletManager.createTransaction(approveAmount, feeAmount, sAddressProcessorContract);
//        TransactionToSign transactionToSign = walletManager.getTransactionBuilder().buildApproveToSign(transactionData, BigInteger.valueOf(walletManager.getTxCount()), walletManager.getGasLimitToApprove());
//
//        if(!signAndSend(signer, transactionToSign, uiCallbacks, walletManager))
//        {
//            throw new Exception("Can't approve");
//        }
//        uiCallbacks.onOkay("Approve result: OK");
//        uiCallbacks.onSeparator();
//    }
//
//    private static Amount extractFeeAmount(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager, Result<List<Amount>> fees) throws Exception {
//        uiCallbacks.onOkay("Gas price: " + walletManager.getGasPrice());
//        if (fees instanceof Result.Failure) {
//            uiCallbacks.onError(((Result.Failure) fees).getError().getCustomMessage());
//            throw new Exception("Can't extract fee");
//        }
//        Amount feeAmount=((Result.Success<List<Amount>>) fees).getData().get(1);
//        return feeAmount;
//    }
//
//    private void doUpdate(Reader.UiCallbacks uiCallbacks, EthereumWalletManager walletManager) throws InterruptedException, ExecutionException {
//        boolean firstTime=true;
//        do {
//            walletManager.updateAsync().get();
//            if( firstTime || walletManager.getTxCount() == walletManager.getPendingTxCount() )
//            {
//                uiCallbacks.onSeparator();
//                uiCallbacks.onOkay("Amounts: ");
//                for (Amount amount : walletCard.getAmounts().values()) {
//                    uiCallbacks.onOkay("   " + amount.getValue() + " " + amount.getCurrencySymbol());
//                }
//                uiCallbacks.onOkay("Tx Count: " + walletManager.getTxCount());
//                uiCallbacks.onOkay("Pending Tx Count: " + walletManager.getPendingTxCount());
//                Thread.sleep(1000);
//                firstTime=false;
//            }
//        }while ( walletManager.getTxCount()!= walletManager.getPendingTxCount());
//    }
//
//
//}
