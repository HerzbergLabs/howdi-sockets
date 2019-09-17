//
//  Created by Aaron Nwabuoku on 2019-09-15.
//

import Foundation
import Starscream

public protocol StompClient {
    var isConnected: Bool { get }
    
    func connect()
    func sendJSONMessage(destination: String, data: AnyObject, headers: [String : String])
    func subscribe(destination: String, headers: [String : String]) -> String
    func unsubscribe(subscriptionId: String)
    func disconnect()
    
    func sendFrame(_ frame: StompClientFrame)
    func resignToClient(client: StompClient)
}

public protocol StompClientDelegate {
    func stompClientDidConnect(client: StompClient)
    func stompClientDidReceiveJSONMessage(client: StompClient, destination: String, data: AnyObject, headers: [String : String])
    func stompClientDidEnqueueFrame(client: StompClient, frame: StompClientFrame)
    func stompClientDidEncounterError(client: StompClient, error: Error)
    func stompClientDidDisconnect(client: StompClient, error: Error?)
}

final class StompSpecification {
    public func connect(host: String) -> StompClientFrame {
        let headers: Set<StompHeader> = [.acceptVersion(version: "1.1,1.2"), .host(host: host), .heartBeat(value: "10000,10000")]
        
        return StompClientFrame(command: .connect, headers: headers)
    }
    
    public func subscribe(id: String, destination: String, headers: [String : String] = [:]) -> StompClientFrame {
        var stompHeaders: Set<StompHeader> = [.id(id: id), .destination(destination: destination), .ack(ack: "client-individual")]
        
        for (key, value) in headers {
            stompHeaders.insert(.custom(key: key, value: value))
        }
        
        return StompClientFrame(command: .subscribe, headers: stompHeaders)
    }
    
    public func sendJSONMessage(destination: String, data: AnyObject, headers: [String : String] = [:]) throws -> StompClientFrame {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions())
        let message = String(data: jsonData, encoding: String.Encoding.utf8)!
        
        var stompHeaders: Set<StompHeader> = [.destination(destination: destination), .contentType(type: "application/json;charset=UTF-8"), .contentLength(length: message.utf8.count)]
        
        for (key, value) in headers {
            stompHeaders.insert(.custom(key: key, value: value))
        }
        
        return StompClientFrame(command: .send, headers: stompHeaders, body: message)
    }
    
    public func unsubscribe(subscriptionId: String) -> StompClientFrame {
        let headers: Set<StompHeader> = [.id(id: subscriptionId)]
        
        return StompClientFrame(command: .unsubscribe, headers: headers)
    }
    
    public func ack(messageId: String) -> StompClientFrame {
        let headers: Set<StompHeader> = [.id(id: messageId)]
        
        return StompClientFrame(command: .ack, headers: headers)
    }
    
    public func disconnect(receipt: String) -> StompClientFrame {
        let headers: Set<StompHeader> = [.receipt(receipt: receipt)]
        
        return StompClientFrame(command: .disconnect, headers: headers)
    }
    
    public func generateReceipt() -> String {
        return "receipt-" + Int(arc4random_uniform(1000)).description
    }
    
    public func generateSubscriptionId() -> String {
        return "subscription-id-" + Int(arc4random_uniform(1000)).description
    }
    
    public func generateHeartBeat() -> String {
        return "\n\n"
    }
}

public final class WebsocketStompClient : StompClient, WebSocketDelegate {
    public var delegate: StompClientDelegate?
    
    public var isConnected: Bool {
        return socket.isConnected
    }
    
    private let specification: StompSpecification = StompSpecification()
    private let url: URL
    private let socket: WebSocket
    
    private var disconnectReceipt: String = ""
    
    private var frameQueue: FrameQueue = FrameQueue()
    
    public init(url: URL) {
        self.url = url
        self.socket = WebSocket(url: url)
        
        socket.delegate = self
    }
    
    public func connect() {
        socket.connect()
    }
    
    public func sendJSONMessage(destination: String, data: AnyObject, headers: [String : String] = [:]) {
        do {
            try sendFrame(specification.sendJSONMessage(destination: destination, data: data))
        } catch {
            delegate?.stompClientDidEncounterError(client: self, error: error)
        }
    }
    
    public func subscribe(destination: String, headers: [String : String] = [:]) -> String {
        let id = specification.generateSubscriptionId()
        
        sendFrame(specification.subscribe(id: id, destination: destination, headers: headers))
        
        return id
    }
    
    public func unsubscribe(subscriptionId: String) {
        sendFrame(specification.unsubscribe(subscriptionId: subscriptionId))
    }
    
    public func disconnect() {
        disconnectReceipt = specification.generateReceipt()
        
        sendFrame(specification.disconnect(receipt: disconnectReceipt))
    }
    
    public func sendFrame(_ frame: StompClientFrame) {
        if socket.isConnected {
            socket.write(string: frame.description)
            print("Sent frame:\n\(frame)")
        } else {
            frameQueue.enqueue(frame)
            delegate?.stompClientDidEnqueueFrame(client: self, frame: frame)
        }
    }
    
    public func resignToClient(client: StompClient) {
        sendFramesToClient(client: client)
        
        socket.disconnect()
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        sendFrame(specification.connect(host: url.host!))
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.stompClientDidDisconnect(client: self, error: error)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        do {
            let components = text.components(separatedBy: "\n")
            
            if components.first == "" {
                sendHeartBeat()
            } else {
                let frame = try StompServerFrame(text: text)
                
                print("Recieved frame:\n\(frame)")
                
                switch frame.command {
                case .connected:
                    sendFramesToClient(client: self)
                    
                    delegate?.stompClientDidConnect(client: self)
                case .message:
                    sendFrame(specification.ack(messageId: frame.getHeader("message-id")))
                case .receipt:
                    if frame.getHeader("receipt-id") == disconnectReceipt {
                        socket.disconnect()
                    }
                case .error:
                    print("Error recieved")
                default:
                    break
                }
            }
        } catch {
            delegate?.stompClientDidEncounterError(client: self, error: error)
        }
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        // Not called in STOMP
    }
    
    private func sendHeartBeat() {
        socket.write(string: specification.generateHeartBeat())
    }
    
    private func sendFramesToClient(client: StompClient) {
        while !frameQueue.isEmpty {
            client.sendFrame(frameQueue.dequeue()!)
        }
    }
}

public final class OfflineStompClient : StompClient {
    public var isConnected: Bool = false
    
    private let specification: StompSpecification = StompSpecification()
    
    private var frameQueue: FrameQueue = FrameQueue()
    
    public func connect() {}
    
    public func sendJSONMessage(destination: String, data: AnyObject, headers: [String : String] = [:]) {
        do {
            try sendFrame(specification.sendJSONMessage(destination: destination, data: data))
        } catch {}
    }
    
    public func subscribe(destination: String, headers: [String : String] = [:]) -> String {
        let id = specification.generateSubscriptionId()
        
        sendFrame(specification.subscribe(id: id, destination: destination, headers: headers))
        
        return id
    }
    
    public func unsubscribe(subscriptionId: String) {
        sendFrame(specification.unsubscribe(subscriptionId: subscriptionId))
    }
    
    public func disconnect() {
        sendFrame(specification.disconnect(receipt: specification.generateReceipt()))
    }
    
    public func sendFrame(_ frame: StompClientFrame) {
        frameQueue.enqueue(frame)
    }
    
    public func resignToClient(client: StompClient) {
        while !frameQueue.isEmpty {
            client.sendFrame(frameQueue.dequeue()!)
        }
    }
}

fileprivate struct FrameQueue {
    private var array = [StompClientFrame?]()
    private var head = 0
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public var count: Int {
        return array.count - head
    }
    
    public mutating func enqueue(_ element: StompClientFrame) {
        array.append(element)
    }
    
    public mutating func dequeue() -> StompClientFrame? {
        guard head < array.count, let element = array[head] else { return nil }
        
        array[head] = nil
        head += 1
        
        let percentage = Double(head)/Double(array.count)
        if array.count > 50 && percentage > 0.25 {
            array.removeFirst(head)
            head = 0
        }
        
        return element
    }
    
    public var front: StompClientFrame? {
        if isEmpty {
            return nil
        } else {
            return array[head]
        }
    }
}
