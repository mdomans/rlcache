import Foundation
import NIO
import NIORedis

enum Op {
    case get         (String)
    case set         (String, Data)
    case del         (String)
    case debug
    case stats
    case reset
    case config
  }

public class CacheHandler: ChannelInboundHandler {
    public typealias InboundIn = RESPValue
    public typealias OutboundOut = RESPValue

    // Keep tracks of the number of message received in a single session
    // (an EchoHandler is created per client connection).
    private var count: Int = 0
    private var storage: Storage
    
    init(max_size: Int) {
        self.storage = Storage(max_size: max_size)
    }

    // Invoked on client connection
    public func channelRegistered(ctx: ChannelHandlerContext) {
        print("channel registered:", ctx.remoteAddress ?? "unknown")
    }

    // Invoked on client disconnect
    public func channelUnregistered(ctx: ChannelHandlerContext) {
        print("we have processed \(count) messages")
        
    }
    
    func processBuffer(data: RESPValue) -> Op?{
        switch data {
        case .simpleString(_):
            print("")
        case .bulkString(_):
            print("bulk string")
        case .integer(_):
            print("INt")
        case .array(let optional):
            if let optional = optional {
                switch optional[0].stringValue! {
                case "GET":
                    return .get(optional[1].stringValue!)
                case "SET":
                    return .set(optional[1].stringValue!, optional[2].dataValue!)
                case "DEL":
                    return .del(optional[1].stringValue!)
                case "DEBUG":
                    return .debug
                case "STATS":
                    return .stats
                case "RESET":
                    return .reset
                case "CONFIG":
                    return .config
                case _:
                    print("Can't read")
                }
            }
        case .error(let rESPError):
            print("Some error \(rESPError)")
        }
        return nil
    }

    // Invoked when data are received from the client
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let in_buffer = self.unwrapInboundIn(data)
        if let op = self.processBuffer(data: in_buffer) {
            switch op {
            case .get(let key):
                if let val = self.storage.get(key: key){
                    ctx.write(self.wrapOutboundOut(val.toRESPValue()), promise: nil)
                } else {
                    ctx.write(self.wrapOutboundOut(false.toRESPValue()), promise: nil)
                }
            case .set(let key, let val):
                self.storage.set(key: key, value: val)
                ctx.write(self.wrapOutboundOut("OK".toRESPValue()), promise: nil)
            case .del(let key):
                print("Deleteing key: \(key)")
            case .debug:
                print("Storage info: \(storage.debug())")
                ctx.write(self.wrapOutboundOut("OK".toRESPValue()), promise: nil)
            case .stats:
                ctx.write(self.wrapOutboundOut(self.storage.stats.toRESPValue()), promise: nil)
            case .config:
                // asked for capabilities outside basic
                ctx.write(self.wrapOutboundOut(false.toRESPValue()), promise: nil)
            case .reset:
                self.storage.reset()
                ctx.write(self.wrapOutboundOut("OK".toRESPValue()), promise: nil)
            }
        }
        count = count + 1
    }

    // Invoked when channelRead as processed all the read event in the current read operation
    public func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }

    // Invoked when an error occurs
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        ctx.close(promise: nil)
    }
}
