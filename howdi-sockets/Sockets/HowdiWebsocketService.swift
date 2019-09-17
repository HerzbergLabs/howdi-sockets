import Foundation

public class HowdiWebsocketService: NSObject, StompClientDelegate {
    public static let shared = HowdiWebsocketService()
    
    private var stompClient: StompClient?
    
    public func initializeService(url: String) {
        let client = StompClient(url: URL(string: url)!)
        
        client.delegate = self
        client.connect()
        
        self.stompClient = client
    }
    
    public func pauseEvents() {
        if stompClient?.isConnected ?? false {
            stompClient?.disconnect()
        }
    }
    
    public func resumeEvents() {
        if !(stompClient?.isConnected ?? false) {
            stompClient?.connect()
        }
    }
    
    public func stompClientDidConnect(client: StompClient) {
        print("STOMP client did connect")
    }
    
    public func stompClientDidDisconnect(client: StompClient) {
        print("STOMP client did disconnect")
    }
    
    public func stompClientDidDisconnectWithError(client: StompClient, error: Error) {
        print("STOMP client did disconnect with error: \(error)")
    }
    
    public func stompClientDidReceiveData(client: StompClient, data: Data, destination: String) {
        print("STOMP client did receive data")
    }
    
    public func stompClientDidEncounterError(client: StompClient, error: Error) {
        print("STOMP client did encounter error")
    }
}
