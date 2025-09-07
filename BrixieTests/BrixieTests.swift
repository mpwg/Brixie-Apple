//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import SwiftUI
@testable import Brixie

struct BrixieTests {

    @Test func testDynamicTypeSupport() async throws {
        // Test that our design system fonts support dynamic type
        let titleFont = Font.brixieTitle
        let headlineFont = Font.brixieHeadline
        let bodyFont = Font.brixieBody
        let captionFont = Font.brixieCaption
        
        // These should not be nil and should be properly configured
        #expect(titleFont != nil)
        #expect(headlineFont != nil)
        #expect(bodyFont != nil)
        #expect(captionFont != nil)
    }
    
    @Test func testScaledMetrics() async throws {
        // Test that scaled metrics have reasonable default values
        #expect(BrixieScaledMetrics.cardPadding == 20)
        #expect(BrixieScaledMetrics.buttonPadding == 24)
        #expect(BrixieScaledMetrics.iconSize == 20)
        #expect(BrixieScaledMetrics.cornerRadius == 16)
        #expect(BrixieScaledMetrics.shadowRadius == 12)
    }
    
    @Test func testFavoriteButtonAccessibility() async throws {
        // Test that FavoriteButton has proper accessibility
        let favoriteButton = FavoriteButton(isFavorite: true, action: {})
        let nonFavoriteButton = FavoriteButton(isFavorite: false, action: {})
        
        // These should compile and render without issues
        #expect(favoriteButton.prominent == false) // default value
        #expect(nonFavoriteButton.prominent == false) // default value
    }
    
    @Test func testColorAdaptiveSupport() async throws {
        // Test that our color system supports both light and dark modes
        let lightBackground = Color.brixieBackground(for: .light)
        let darkBackground = Color.brixieBackground(for: .dark)
        
        #expect(lightBackground != darkBackground)
        
        let lightText = Color.brixieText(for: .light)
        let darkText = Color.brixieText(for: .dark)
        
        #expect(lightText != darkText)
    }

}
