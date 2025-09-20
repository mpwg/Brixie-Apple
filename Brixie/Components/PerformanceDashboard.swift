//
//  PerformanceDashboard.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import SwiftUI
import OSLog

/// Performance monitoring dashboard for debugging and development
/// Shows real-time performance metrics and optimization status
struct PerformanceDashboard: View {
    @StateObject private var scrollMonitor = ScrollPerformanceMonitor()
    @State private var showingDashboard = false
    @State private var imageProcessorStatus = BackgroundImageProcessor.shared.processingStatus
    @State private var updateTimer: Timer?
    
    private let logger = Logger(subsystem: "com.brixie", category: "PerformanceDashboard")
    
    // Computed properties for metric statuses
    private var performanceStatus: MetricStatus {
        switch scrollMonitor.performanceLevel {
        case .excellent: return .excellent
        case .good: return .good  
        case .poor: return .warning
        case .critical: return .critical
        }
    }
    
    private var memoryStatus: MetricStatus {
        if scrollMonitor.memoryUsageMB > 200 {
            return .critical
        } else if scrollMonitor.memoryUsageMB > 100 {
            return .warning
        } else {
            return .good
        }
    }
    
    var body: some View {
        VStack {
            if showingDashboard {
                dashboardContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            startUpdating()
        }
        .onDisappear {
            stopUpdating()
        }
        .onTapGesture(count: 3) {
            // Triple tap to show/hide dashboard (debug feature)
            withAnimation(.spring()) {
                showingDashboard.toggle()
            }
        }
    }
    
    private var dashboardContent: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Performance Dashboard")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    withAnimation(.spring()) {
                        showingDashboard = false
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Divider()
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // FPS Metric
            // Performance Metrics
            MetricCard(
                title: "FPS",
                value: scrollMonitor.averageFPS.formatted(.number.precision(.fractionLength(1))),
                status: performanceStatus,
                icon: "speedometer"
            )                // Memory Usage
                MetricCard(
                    title: "Memory",
                    value: "\(Int(scrollMonitor.memoryUsageMB))MB",
                    status: memoryStatus,
                    icon: "memorychip"
                )
                
                // Image Processing
                MetricCard(
                    title: "Image Tasks",
                    value: "\(imageProcessorStatus.activeTasks)/\(imageProcessorStatus.maxConcurrentTasks)",
                    status: processingStatus,
                    icon: "photo"
                )
                
                // Dropped Frames
                MetricCard(
                    title: "Dropped Frames",
                    value: "\(scrollMonitor.droppedFrames)",
                    status: droppedFramesStatus,
                    icon: "exclamationmark.triangle"
                )
            }
            
            // Performance Level Bar
            PerformanceLevelBar(level: scrollMonitor.performanceLevel)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button("Clear Cache") {
                    clearImageCache()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Force GC") {
                    forceGarbageCollection()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Reset Metrics") {
                    resetMetrics()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .font(.caption)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var fpsStatus: MetricStatus {
        switch scrollMonitor.averageFPS {
        case 55...: return .excellent
        case 45..<55: return .good
        case 30..<45: return .warning
        default: return .critical
        }
    }
    
    private var processingStatus: MetricStatus {
        let utilization = imageProcessorStatus.utilizationPercentage
        switch utilization {
        case 0..<50: return .excellent
        case 50..<80: return .good
        case 80..<95: return .warning
        default: return .critical
        }
    }
    
    private var droppedFramesStatus: MetricStatus {
        switch scrollMonitor.droppedFrames {
        case 0: return .excellent
        case 1...5: return .good
        case 6...15: return .warning
        default: return .critical
        }
    }
    
    private func startUpdating() {
        scrollMonitor.startMonitoring()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                imageProcessorStatus = BackgroundImageProcessor.shared.processingStatus
            }
        }
    }
    
    private func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func clearImageCache() {
        Task { @MainActor in
            let cacheService = ImageCacheService.shared
            cacheService.clearMemoryCache()
            logger.debug("Image cache cleared from performance dashboard")
        }
    }
    
    private func forceGarbageCollection() {
        // Trigger memory pressure to force cleanup
        Task { @MainActor in
            let cacheService = ImageCacheService.shared
            cacheService.clearMemoryCache()
            logger.debug("Forced garbage collection from performance dashboard")
        }
    }
    
    private func resetMetrics() {
        scrollMonitor.droppedFrames = 0
        scrollMonitor.averageFPS = 60.0
        logger.debug("Performance metrics reset")
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let status: MetricStatus
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(status.color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(status.color)
                
                Spacer()
            }
        }
        .padding(12)
        .background(status.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PerformanceLevelBar: View {
    let level: ScrollPerformanceMonitor.PerformanceLevel
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Overall Performance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(level.color)
            }
            
            ProgressView(value: levelProgress, total: 1.0)
                .tint(level.color)
        }
    }
    
    private var levelProgress: Double {
        switch level {
        case .excellent: return 1.0
        case .good: return 0.75
        case .poor: return 0.5
        case .critical: return 0.25
        }
    }
}

enum MetricStatus {
    case excellent, good, warning, critical
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - View Modifier

struct PerformanceMonitored: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            #if DEBUG
            PerformanceDashboard()
            #endif
        }
    }
}

extension View {
    /// Adds performance monitoring to the view (DEBUG only)
    func performanceMonitored() -> some View {
        self.modifier(PerformanceMonitored())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Sample App Content")
            .font(.largeTitle)
            .padding()
        
        Spacer()
    }
    .performanceMonitored()
}