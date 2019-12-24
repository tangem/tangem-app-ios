import Foundation
import SwiftProtobuf

public class Message {

    private enum MessageType: String {
        case newOrder = "CE6DC043"
        case cancelOrder = "166E681B"
        case freeze = "E774B32D"
        case unfreeze = "6515FF0D"
        case transfer = "2A2C87FA"
        case vote = "A1CADD36"
        case stdtx = "F0625DEE"
        case signature = ""
        case publicKey = "EB5AE987"
    }

    private enum Source: Int {
        case hidden = 0
        case broadcast = 1
    }

    private var type: MessageType = .newOrder
    private var wallet: Wallet
    private var symbol: String = ""
    private var orderId: String = ""
    private var orderType: OrderType = .limit
    private var side: Side = .buy
    private var price: Double = 0
    private var amount: Double = 0
    private var quantity: Double = 0
    private var timeInForce: TimeInForce = .goodTillExpire
    private var data: Data = Data()
    private var memo: String = ""
    private var toAddress: String = ""
    private var proposalId: Int = 0
    private var voteOption: VoteOption = .no
    private var source: Source = .broadcast

    // MARK: - Constructors

    private init(type: MessageType, wallet: Wallet) {
        self.type = type
        self.wallet = wallet
    }

    public static func newOrder(symbol: String, orderType: OrderType, side: Side, price: Double, quantity: Double, timeInForce: TimeInForce, wallet: Wallet) -> Message {
        let message = Message(type: .newOrder, wallet: wallet)
        message.symbol = symbol
        message.orderType = orderType
        message.side = side
        message.price = price
        message.quantity = quantity
        message.timeInForce = timeInForce
        message.orderId = wallet.nextAvailableOrderId()
        return message
    }

    public static func cancelOrder(symbol: String, orderId: String, wallet: Wallet) -> Message {
        let message = Message(type: .cancelOrder, wallet: wallet)
        message.symbol = symbol
        message.orderId = orderId
        return message
    }

    public static func freeze(symbol: String, amount: Double, wallet: Wallet) -> Message  {
        let message = Message(type: .freeze, wallet: wallet)
        message.symbol = symbol
        message.amount = amount
        return message
    }

    public static func unfreeze(symbol: String, amount: Double, wallet: Wallet) -> Message  {
        let message = Message(type: .unfreeze, wallet: wallet)
        message.symbol = symbol
        message.amount = amount
        return message
    }

    public static func transfer(symbol: String, amount: Double, to address: String, wallet: Wallet) -> Message {
        let message = Message(type: .transfer, wallet: wallet)
        message.symbol = symbol
        message.amount = amount
        message.toAddress = address
        return message
    }

    public static func vote(proposalId: Int, vote option: VoteOption, wallet: Wallet) -> Message {
        let message = Message(type: .vote, wallet: wallet)
        message.proposalId = proposalId
        message.voteOption = option
        return message
    }

    // MARK: - Public

    public func encode() throws -> Data {

        // Generate encoded message
        var message = Data()
        message.append(self.type.rawValue.unhexlify)
        message.append(try self.body(for: self.type))
        
        // Generate signature
        let signature = try self.body(for: .signature)

        // Wrap in StdTx structure
        var stdtx = StdTx()
        stdtx.msgs.append(message)
        stdtx.signatures.append(signature)
        stdtx.memo = self.memo
        stdtx.source = Int64(Source.broadcast.rawValue)
        stdtx.data = self.data

        // Prefix length and stdtx type
        var content = Data()
        content.append(MessageType.stdtx.rawValue.unhexlify)
        content.append(try stdtx.serializedData())

        // Complete Standard Transaction
        var transaction = Data()
        transaction.append(content.count.varint)
        transaction.append(content)

        // Prepare for next transaction
        self.wallet.incrementSequence()

        return transaction

    }
    
    // MARK: - Private

    private func body(for type: MessageType) throws -> Data {

        switch (type) {

        case .newOrder:
            var pb = NewOrder()
            pb.sender = self.wallet.address.unhexlify
            pb.id = self.orderId
            pb.symbol = symbol
            pb.timeinforce = Int64(self.timeInForce.rawValue)
            pb.ordertype = Int64(self.orderType.rawValue)
            pb.side = Int64(self.side.rawValue)
            pb.price = Int64(price.encoded)
            pb.quantity = Int64(quantity.encoded)
            return try pb.serializedData()

        case .cancelOrder:
            var pb = CancelOrder()
            pb.symbol = self.symbol
            pb.sender = self.wallet.address.unhexlify
            pb.refid = self.orderId
            return try pb.serializedData()

        case .freeze:
            var pb = TokenFreeze()
            pb.symbol = symbol
            pb.from = self.wallet.address.unhexlify
            pb.amount = Int64(self.amount.encoded)
            return try pb.serializedData()

        case .unfreeze:
            var pb = TokenUnfreeze()
            pb.symbol = symbol
            pb.from = self.wallet.address.unhexlify
            pb.amount = Int64(self.amount.encoded)
            return try pb.serializedData()

        case .transfer:
            var token = Send.Token()
            token.denom = self.symbol
            token.amount = Int64(amount.encoded)

            var input = Send.Input()
            input.address = self.wallet.address.unhexlify
            input.coins = [token]

            var output = Send.Output()
            output.address = self.wallet.address(from: toAddress).unhexlify
            output.coins = [token]
            
            var send = Send()
            send.inputs.append(input)
            send.outputs.append(output)
            return try send.serializedData()

        case .signature:
            var pb = StdSignature()
            pb.sequence = Int64(self.wallet.sequence)
            pb.accountNumber = Int64(self.wallet.accountNumber)
            pb.pubKey = try self.body(for: .publicKey)
            pb.signature = self.signature()
            return try pb.serializedData()

        case .publicKey:
            let key = self.wallet.publicKey
            var data = Data()
            data.append(type.rawValue.unhexlify)
            data.append(key.count.varint)
            data.append(key)
            return data

        case .vote:
            var vote = Vote()
            vote.proposalID = Int64(self.proposalId)
            vote.voter = self.wallet.address.unhexlify
            vote.option = Int64(self.voteOption.rawValue)
            return try vote.serializedData()
            
        default:
            throw BinanceError(message: "Invalid type")

        }

    }

    private func signature() -> Data {
        let json = self.json(for: .signature)
        let data = Data(json.utf8)
        return self.wallet.sign(message: data)
    }

    private func json(for type: MessageType) -> String {

        switch (type) {

        case .newOrder:
            return String(format: JSON.newOrder,
                          self.orderId,
                          self.orderType.rawValue,
                          self.price.encoded,
                          self.quantity.encoded,
                          self.wallet.account,
                          self.side.rawValue,
                          self.symbol,
                          self.timeInForce.rawValue)

        case .cancelOrder:
            return String(format: JSON.cancelOrder,
                          self.orderId,
                          self.wallet.account,
                          self.symbol)

        case .freeze:
            return String(format: JSON.freeze,
                          self.amount.encoded,
                          self.wallet.account,
                          self.symbol)

        case .unfreeze:
            return String(format: JSON.unfreeze,
                          self.amount.encoded,
                          self.wallet.account,
                          self.symbol)

        case .transfer:
            return String(format: JSON.transfer,
                          self.wallet.account,
                          self.amount.encoded,
                          self.symbol,
                          self.toAddress,
                          self.amount.encoded,
                          self.symbol)
            
        case .vote:
            return String(format: JSON.vote,
                          self.voteOption.rawValue,
                          self.proposalId,
                          self.wallet.account)

        case .signature:
            return String(format: JSON.signature,
                          self.wallet.accountNumber,
                          self.wallet.chainId,
                          self.memo,
                          self.json(for: self.type),
                          self.wallet.sequence,
                          self.source.rawValue)

        default:
            return "{}"
            
        }
        
    }

}

fileprivate extension Double {
    var encoded: Int {
        // Multiply by 1e8 (10^8) and round to int
        return Int(self * pow(10, 8))
    }
}

fileprivate class JSON {

    // Signing requires a strictly ordered JSON string. Neither swift nor
    // SwiftyJSON maintained the order, so instead we use strings.

    static let signature = """
    {"account_number":"%d","chain_id":"%@","data":null,"memo":"%@","msgs":[%@],"sequence":"%d","source":"%d"}
    """

    static let newOrder = """
    {"id":"%@","ordertype":%d,"price":%d,"quantity":%d,"sender":"%@","side":%d,"symbol":"%@","timeinforce":%d}
    """

    static let cancelOrder = """
    {"refid":"%@","sender":"%@","symbol":"%@"}
    """

    static let freeze = """
    {"amount":%ld,"from":"%@","symbol":"%@"}
    """

    static let unfreeze = """
    {"amount":%ld,"from":"%@","symbol":"%@"}
    """

    static let transfer = """
    {"inputs":[{"address":"%@","coins":[{"amount":%ld,"denom":"%@"}]}],"outputs":[{"address":"%@","coins":[{"amount":%ld,"denom":"%@"}]}]}
    """

    static let vote = """
    {"option":%d,proposal_id":%d,voter":"%@"}
    """

}
