//
//  File.swift
//  
//
//  Created by mdomans on 30/10/2021.
//

import Foundation
import NIO
import NIORedis

public func run_server(port: Int, max_size:Int) throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let bootstrap = ServerBootstrap(group: group)
        // Define backlog and enable SO_REUSEADDR options atethe server level
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

        // Handler Pipeline: handlers that are processing events from accepted Channels
        // To demonstrate that we can have several reusable handlers we start with a Swift-NIO default
        // handler that limits the speed at which we read from the client if we cannot keep up with the
        // processing through EchoHandler.
        // This is to protect the server from overload.
        .childChannelInitializer { channel in
            channel.pipeline.add(handler: BackPressureHandler()).then { v in
                channel.pipeline.configureRedisPipeline().then { v in
                    channel.pipeline.add(handler: CacheHandler(max_size: max_size))
                }
            }
        }

        // Enable common socket options at the channel level (TCP_NODELAY and SO_REUSEADDR).
        // These options are applied to accepted Channels
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        // Message grouping
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        // Let Swift-NIO adjust the buffer size, based on actual trafic.
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator()
        )
    defer {
        try! group.syncShutdownGracefully()
    }
    // Bind the port and run the server
    let channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
    print("Server started and listening on \(channel.localAddress!)")
    // Clean-up (never called, as we do not have a code to decide when to stop
    // the server). We assume we will be killing it with Ctrl-C.
    try channel.closeFuture.wait()
    print("Server terminated")
}



