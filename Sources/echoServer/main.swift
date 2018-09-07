
import NIO

final class EchoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutBoundOut = ByteBuffer
    
    var count = 0
    
    func channelRegistered(ctx: ChannelHandlerContext) {
        print("Channel registered", ctx.remoteAddress ?? "Unknown")
    }
    
    func channelUnregistered(ctx: ChannelHandlerContext) {
        print("Channel unregistered")
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        ctx.write(data, promise: nil)
    }
    
    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)
        ctx.close(promise: nil)
    }
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    
    .childChannelInitializer { channel in
        channel.pipeline.add(handler: BackPressureHandler()).then { v in
            channel.pipeline.add(handler: EchoHandler())
        }
    }

    .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
    .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
    .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

defer {
    try! group.syncShutdownGracefully()
}

let channel = try bootstrap.bind(host: "::1", port: 9999).wait()
print("Server started and listening on \(channel.localAddress!)")

try channel.closeFuture.wait()
