import Foundation

public class HowdiWebsocketService: NSObject, StompClientDelegate {
    
    public static let shared = HowdiWebsocketService()
    
    private var client: StompClient = OfflineStompClient()
    
    public func initializeService(url: String) {
        let client = WebsocketStompClient(url: URL(string: url)!)
        
        client.delegate = self
        client.connect()
        
        self.client.resignToClient(client: client)
        self.client = client
    }
    
    public func pauseEvents() {
        if client.isConnected {
            client.disconnect()
        }
    }
    
    public func resumeEvents() {
        if !client.isConnected {
            client.connect()
        }
    }
    
    public func stompClientDidConnect(client: StompClient) {
        print("STOMP client did connect")
    }
    
    public func stompClientDidReceiveJSONMessage(client: StompClient, destination: String, data: AnyObject, headers: [String : String]) {
        print("STOMP client did receive message: destination \(destination), data \(data) headers \(headers)")
    }
    
    public func stompClientDidEnqueueFrame(client: StompClient) {
        print("STOMP client did enqueue frame")
    }
    
    public func stompClientDidEncounterError(client: StompClient, error: Error) {
        print("STOMP client did encounter error \(error)")
    }
    
    public func stompClientDidDisconnect(client: StompClient, error: Error?) {
        print("STOMP client did disconnect: error \(String(describing: error))")
    }
}
