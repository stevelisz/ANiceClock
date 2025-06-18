import SwiftUI
import Photos
import UIKit

// MARK: - Gallery Manager (Pure Native PHAsset Approach)
class GalleryManager: ObservableObject {
    @Published var selectedAssetIDs: [String] = []
    @Published var currentAssetIndex = 0
    @Published var hasPermission = false
    @Published var isLoading = false
    @Published var currentDisplayImage: UIImage?
    
    private var slideshowTimer: Timer?
    var slideshowDuration: TimeInterval = 10.0 // Default 10 seconds, configurable
    
    private let selectedAssetIDsKey = "ANiceClock_SelectedAssetIDs"
    private let slideshowDurationKey = "ANiceClock_SlideshowDuration"
    
    init() {
        loadPersistedData()
        checkPermission()
    }
    
    // MARK: - Persistence (Pure Native - just asset ID strings)
    private func loadPersistedData() {
        // Load slideshow duration
        let savedDuration = UserDefaults.standard.object(forKey: slideshowDurationKey) as? TimeInterval
        if let duration = savedDuration {
            slideshowDuration = duration
        }
        
        // Load selected asset IDs
        if let savedAssetIDs = UserDefaults.standard.stringArray(forKey: selectedAssetIDsKey) {
            // Filter out assets that no longer exist in photo library
            let validAssetIDs = savedAssetIDs.filter { assetID in
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                return fetchResult.firstObject != nil
            }
            selectedAssetIDs = validAssetIDs
            print("🔵 Loaded \(validAssetIDs.count) valid assets from persistence")
            
            // Load first image if we have assets
            if !selectedAssetIDs.isEmpty {
                loadCurrentImage()
            }
        }
    }
    
    private func savePersistedData() {
        UserDefaults.standard.set(selectedAssetIDs, forKey: selectedAssetIDsKey)
        UserDefaults.standard.set(slideshowDuration, forKey: slideshowDurationKey)
        print("🔵 Saved \(selectedAssetIDs.count) asset IDs to persistence")
    }
    
    // MARK: - Asset Management (Pure Native)
    func addAsset(_ asset: PHAsset) {
        let assetID = asset.localIdentifier
        print("🔵 addAsset called with asset ID: \(assetID)")
        print("🔵 Current selectedAssetIDs count: \(selectedAssetIDs.count)")
        
        // Native duplicate prevention - PHAsset IDs are unique
        if !selectedAssetIDs.contains(assetID) {
            print("🔵 Asset is new, adding to collection...")
            selectedAssetIDs.append(assetID)
            print("🔵 New selectedAssetIDs count: \(selectedAssetIDs.count)")
            savePersistedData()
            
            if selectedAssetIDs.count == 1 {
                print("🔵 First asset added, starting slideshow...")
                startSlideshow()
            }
        } else {
            print("🔵 Asset already exists in collection, skipping duplicate")
        }
    }
    
    func removeAsset(withID assetID: String) {
        print("🔵 removeAsset called for ID: \(assetID)")
        print("🔵 Current selectedAssetIDs: \(selectedAssetIDs)")
        print("🔵 Current index: \(currentAssetIndex)")
        
        // Find the index of the asset to remove
        guard let indexToRemove = selectedAssetIDs.firstIndex(of: assetID) else {
            print("❌ Asset ID not found in collection")
            return
        }
        
        print("🔵 Found asset at index: \(indexToRemove)")
        
        // Remove the asset
        selectedAssetIDs.remove(at: indexToRemove)
        print("🔵 Asset removed. New count: \(selectedAssetIDs.count)")
        
        // Adjust currentAssetIndex based on what was removed
        if indexToRemove < currentAssetIndex {
            // Removed asset was before current index, shift index down
            currentAssetIndex -= 1
            print("🔵 Adjusted currentAssetIndex to: \(currentAssetIndex)")
        } else if indexToRemove == currentAssetIndex {
            // Removed the currently displayed asset
            if selectedAssetIDs.isEmpty {
                // No more assets
                print("🔵 No more assets, stopping slideshow")
                stopSlideshow()
                currentDisplayImage = nil
                currentAssetIndex = 0
            } else {
                // Load new current asset (stay at same index, or wrap to 0 if at end)
                if currentAssetIndex >= selectedAssetIDs.count {
                    currentAssetIndex = 0
                }
                print("🔵 Loading new current asset at index: \(currentAssetIndex)")
                loadCurrentImage()
            }
        }
        // If indexToRemove > currentAssetIndex, no adjustment needed
        
        savePersistedData()
    }
    
    func clearSelectedAssets() {
        selectedAssetIDs.removeAll()
        savePersistedData()
        stopSlideshow()
        currentDisplayImage = nil
        currentAssetIndex = 0
    }
    
    // MARK: - Image Loading (On-Demand, Memory Efficient)
    private func loadCurrentImage() {
        guard !selectedAssetIDs.isEmpty else { return }
        let currentAssetID = selectedAssetIDs[currentAssetIndex]
        print("🔵 Loading current image for asset: \(currentAssetID)")
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [currentAssetID], options: nil)
        guard let asset = fetchResult.firstObject else { 
            print("❌ Could not fetch asset: \(currentAssetID)")
            return 
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        let targetSize = CGSize(width: 1000, height: 1000) // Reasonable size for display
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    print("✅ Current image loaded successfully")
                    self?.currentDisplayImage = image
                } else {
                    print("❌ Failed to load current image")
                }
            }
        }
    }
    
    // MARK: - Slideshow Control
    func startSlideshow() {
        guard !selectedAssetIDs.isEmpty else { return }
        print("🔵 Starting slideshow with \(selectedAssetIDs.count) assets")
        
        // Load the first image
        loadCurrentImage()
        
        // Start timer for slideshow
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: slideshowDuration, repeats: true) { [weak self] _ in
            self?.nextPhoto()
        }
    }
    
    func stopSlideshow() {
        print("🔵 Stopping slideshow")
        slideshowTimer?.invalidate()
        slideshowTimer = nil
    }
    
    func nextPhoto() {
        guard !selectedAssetIDs.isEmpty else { return }
        currentAssetIndex = (currentAssetIndex + 1) % selectedAssetIDs.count
        print("🔵 Next photo: index \(currentAssetIndex)")
        loadCurrentImage()
    }
    
    func previousPhoto() {
        guard !selectedAssetIDs.isEmpty else { return }
        currentAssetIndex = currentAssetIndex > 0 ? currentAssetIndex - 1 : selectedAssetIDs.count - 1
        print("🔵 Previous photo: index \(currentAssetIndex)")
        loadCurrentImage()
    }
    
    // MARK: - Permission Handling
    private func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            hasPermission = true
        case .denied, .restricted:
            hasPermission = false
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.hasPermission = (newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            hasPermission = false
        }
    }
    
    // MARK: - Gallery Display Support
    func ensureCurrentImageLoaded() {
        // Load current image if we have assets but no current display image
        if !selectedAssetIDs.isEmpty && currentDisplayImage == nil {
            loadCurrentImage()
        }
    }
    
    // MARK: - Computed Properties for UI Compatibility
    var selectedPhotos: [GalleryPhoto] {
        return selectedAssetIDs.map { GalleryPhoto(assetID: $0) }
    }
} 