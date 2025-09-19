//
//  CollectionStatisticsView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI
import SwiftData
import Charts

struct CollectionStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let collectionService = CollectionService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    overviewSection
                    valueSection
                    partsSection
                    themesSection
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Collection Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var stats: CollectionStats {
        collectionService.getCollectionStats(from: modelContext)
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection Overview")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "Total Sets",
                    value: "\(stats.ownedSetsCount)",
                    icon: "cube.box",
                    color: .blue
                )
                
                StatCardView(
                    title: "Total Parts",
                    value: formatNumber(stats.totalParts),
                    icon: "puzzlepiece.extension",
                    color: .green
                )
                
                StatCardView(
                    title: "Wishlist Sets",
                    value: "\(stats.wishlistCount)",
                    icon: "star",
                    color: .yellow
                )
                
                StatCardView(
                    title: "Missing Parts",
                    value: "\(stats.missingPartsCount)",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
            }
        }
    }
    
    private var valueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "Total Investment",
                    value: formatPrice(stats.totalInvestment),
                    icon: "dollarsign.circle",
                    color: .blue
                )
                
                StatCardView(
                    title: "Current Value",
                    value: formatPrice(stats.totalRetailValue),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatCardView(
                    title: "Value Gain",
                    value: formatPrice(stats.totalValueGain),
                    icon: "arrow.up.circle",
                    color: stats.totalValueGain >= 0 ? .green : .red
                )
                
                StatCardView(
                    title: "ROI",
                    value: String(format: "%.1f%%", stats.investmentROI),
                    icon: "percent",
                    color: stats.investmentROI >= 0 ? .green : .red
                )
            }
            
            if stats.wishlistCount > 0 {
                StatCardView(
                    title: "Wishlist Value",
                    value: formatPrice(stats.wishlistValue),
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var partsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parts Analysis")
                .font(.title2)
                .bold()
            
            let averageParts = stats.ownedSetsCount > 0 ? stats.totalParts / stats.ownedSetsCount : 0
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "Average Parts",
                    value: "\(averageParts)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCardView(
                    title: "Completion Rate",
                    value: String(format: "%.1f%%", completionPercentage),
                    icon: "checkmark.circle",
                    color: .green
                )
            }
        }
    }
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Themes Distribution")
                .font(.title2)
                .bold()
            
            let themeGroups = collectionService.getOwnedSetsByTheme(from: modelContext)
            let topThemes = Array(themeGroups.sorted { $0.value.count > $1.value.count }.prefix(5))
            
            ForEach(topThemes, id: \.key) { themeName, sets in
                HStack {
                    VStack(alignment: .leading) {
                        Text(themeName)
                            .font(.headline)
                        Text("\(sets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(Double(sets.count) / Double(stats.ownedSetsCount) * 100))%")
                        .font(.title3)
                        .bold()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(achievements, id: \.title) { achievement in
                    AchievementCardView(achievement: achievement)
                }
            }
        }
    }
    
    private var achievements: [Achievement] {
        var achievements: [Achievement] = []
        
        // Collection size achievements
        if stats.ownedSetsCount >= 100 {
            achievements.append(Achievement(title: "Collector", description: "Own 100+ sets", icon: "star.fill", isUnlocked: true))
        } else if stats.ownedSetsCount >= 50 {
            achievements.append(Achievement(title: "Enthusiast", description: "Own 50+ sets", icon: "heart.fill", isUnlocked: true))
        } else if stats.ownedSetsCount >= 10 {
            achievements.append(Achievement(title: "Builder", description: "Own 10+ sets", icon: "hammer.fill", isUnlocked: true))
        }
        
        // Parts achievements
        if stats.totalParts >= 10000 {
            achievements.append(Achievement(title: "Parts Master", description: "Own 10,000+ parts", icon: "puzzlepiece.extension.fill", isUnlocked: true))
        }
        
        // Theme diversity
        let themeCount = collectionService.getOwnedSetsByTheme(from: modelContext).count
        if themeCount >= 10 {
            achievements.append(Achievement(title: "Theme Explorer", description: "Collect from 10+ themes", icon: "globe", isUnlocked: true))
        }
        
        // Investment achievements
        if stats.investmentROI >= 50 {
            achievements.append(Achievement(title: "Smart Investor", description: "50%+ ROI", icon: "chart.line.uptrend.xyaxis", isUnlocked: true))
        }
        
        return achievements
    }
    
    private var completionPercentage: Double {
        guard stats.totalParts > 0 else { return 100 }
        return Double(stats.totalParts - stats.missingPartsCount) / Double(stats.totalParts) * 100
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Supporting Views

private struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.title2)
                    .bold()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(achievement.isUnlocked ? .yellow : .gray)
            
            Text(achievement.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.5)
    }
}

// MARK: - Data Models

private struct Achievement {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

#Preview {
    CollectionStatisticsView()
        .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], inMemory: true)
}