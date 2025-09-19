import SwiftUI
import Network
import Foundation

/// Manages offline state detection and queued actions
@MainActor
internal final class OfflineManager {
    static let shared = OfflineManager()
    
    // MARK: - Published Properties
    private(set) var isOffline = false
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var queuedActions: [QueuedAction] = []
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "offline.monitor")
    private let userDefaults = UserDefaults.standard
    private let queueKey = "BrixieQueuedActions"
    
    enum ConnectionType: String, CaseIterable {
        case wifi = "wifi"
        case cellular = "cellular" 
        case ethernet = "ethernet"
        case unknown = "unknown"
        case none = "none"
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            case .none: return "No Connection"
            }
        }
        
        var systemImage: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            case .none: return "wifi.slash"
            }
        }
    }
    
    private init() {
        loadQueuedActions()
        startMonitoring()
    }
    
    deinit {
        // Cancel the NWPathMonitor directly in deinit. This avoids capturing `self` in an
        // asynchronous task which the compiler warns could introduce data races.
        monitor.cancel()
    } 
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        let wasOffline = isOffline
        isOffline = path.status != .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if isOffline {
            connectionType = .none
        } else {
            connectionType = .unknown
        }
        
        // Process queued actions when coming back online
        if wasOffline && !isOffline {
            Task {
                await processQueuedActions()
            }
        }
        
        // Provide haptic feedback for connection changes
        if wasOffline && !isOffline {
            HapticFeedback.success()
        } else if !wasOffline && isOffline {
            HapticFeedback.warning()
        }
    }
    
    // MARK: - Action Queueing
    
    func queueAction(_ action: QueuedAction) {
        queuedActions.append(action)
        saveQueuedActions()
        
        // Try to process immediately if online
        if !isOffline {
            Task {
                await processQueuedActions()
            }
        }
    }
    
    func removeQueuedAction(_ action: QueuedAction) {
        queuedActions.removeAll { $0.id == action.id }
        saveQueuedActions()
    }
    
    func clearAllQueuedActions() {
        queuedActions.removeAll()
        saveQueuedActions()
    }
    
    private func processQueuedActions() async {
        guard !isOffline && !queuedActions.isEmpty else { return }
        
        let actionsToProcess = queuedActions
        
        for action in actionsToProcess {
            do {
                try await action.execute()
                removeQueuedAction(action)
            } catch {
                print("Failed to process queued action: \(error)")
                // Action remains in queue for next attempt
                break // Stop processing on first failure
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveQueuedActions() {
        do {
            let data = try JSONEncoder().encode(queuedActions)
            userDefaults.set(data, forKey: queueKey)
        } catch {
            print("Failed to save queued actions: \(error)")
        }
    }
    
    private func loadQueuedActions() {
        guard let data = userDefaults.data(forKey: queueKey) else { return }
        
        do {
            queuedActions = try JSONDecoder().decode([QueuedAction].self, from: data)
        } catch {
            print("Failed to load queued actions: \(error)")
            queuedActions = []
        }
    }
}

// MARK: - QueuedAction

internal struct QueuedAction: Identifiable, Codable {
    // Make id mutable so it can be decoded from storage. Using `var` allows JSONDecoder
    // to overwrite the initial value when restoring saved queued actions.
    var id: UUID = UUID()
    let type: ActionType
    let data: [String: String] // Simple string-based data storage
    let timestamp: Date
    
    init(type: ActionType, data: [String: String]) {
        self.type = type
        self.data = data
        self.timestamp = Date()
    }
    
    enum ActionType: String, CaseIterable, Codable {
        case addToCollection = "add_to_collection"
        case removeFromCollection = "remove_from_collection"
        case addToWishlist = "add_to_wishlist"  
        case removeFromWishlist = "remove_from_wishlist"
        case addMissingPart = "add_missing_part"
        case updateMissingPart = "update_missing_part"
        case deleteMissingPart = "delete_missing_part"
        
        var displayName: String {
            switch self {
            case .addToCollection: return "Add to Collection"
            case .removeFromCollection: return "Remove from Collection"
            case .addToWishlist: return "Add to Wishlist"
            case .removeFromWishlist: return "Remove from Wishlist"
            case .addMissingPart: return "Add Missing Part"
            case .updateMissingPart: return "Update Missing Part"
            case .deleteMissingPart: return "Delete Missing Part"
            }
        }
    }
    
    func execute() async throws {
        // This would contain the actual execution logic
        // For now, we'll just simulate the execution
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        switch type {
        case .addToCollection, .removeFromCollection:
            // Execute collection service operations
            break
        case .addToWishlist, .removeFromWishlist:
            // Execute wishlist service operations  
            break
        case .addMissingPart, .updateMissingPart, .deleteMissingPart:
            // Execute missing parts operations
            break
        }
    }
}

// MARK: - SwiftUI Environment

private struct OfflineManagerKey: EnvironmentKey {
    static let defaultValue = OfflineManager.shared
}

extension EnvironmentValues {
    var offlineManager: OfflineManager {
        get { self[OfflineManagerKey.self] }
        set { self[OfflineManagerKey.self] = newValue }
    }
}

// MARK: - Offline UI Components

struct OfflineIndicator: View {
    @Environment(\.offlineManager) private var offlineManager
    
    var body: some View {
        if offlineManager.isOffline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if !offlineManager.queuedActions.isEmpty {
                    Text("(\(offlineManager.queuedActions.count) queued)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct QueuedActionsView: View {
    @Environment(\.offlineManager) private var offlineManager
    
    var body: some View {
        if !offlineManager.queuedActions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Queued Actions")
                    .font(.headline)
                
                ForEach(offlineManager.queuedActions) { action in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(action.type.displayName)
                                .font(.subheadline)
                            Text(action.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button("Cancel") {
                            offlineManager.removeQueuedAction(action)
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Button("Clear All") {
                    offlineManager.clearAllQueuedActions()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding()
        }
    }
}