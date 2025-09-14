//
//  NetworkMonitorService.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import Network

@Observable
@MainActor
final class NetworkMonitorService: @unchecked Sendable {
    static let shared = NetworkMonitorService()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected = false
    var connectionType: ConnectionType = .none
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = ConnectionType(from: path)
            }
        }
        monitor.start(queue: queue)
    }
    
    nonisolated private func stopMonitoring() {
        monitor.cancel()
    }
}

enum ConnectionType: String, CaseIterable, Sendable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case none = "none"
    
    init(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            self = .wifi
        } else if path.usesInterfaceType(.cellular) {
            self = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            self = .ethernet
        } else {
            self = .none
        }
    }
    
    var iconName: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .none:
            return "wifi.slash"
        }
    }
}