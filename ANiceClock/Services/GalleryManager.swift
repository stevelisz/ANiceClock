import Foundation
import Photos
import UIKit
import PhotosUI

// MARK: - Native Gallery Manager - Asset IDs Only (No Storage Bloat)
class GalleryManager: ObservableObject {
    @Published var selectedAssetIDs: [String] = [] // Only store Photo Library asset IDs
    @Published var currentIndex = 0
    @Published var currentImage: UIImage?
    
    private var slideshowTimer: Timer?
    var slideshowDuration: TimeInterval = 10.0
    
    // In-memory cache for performance (automatically managed by iOS)
    private var imageCache = NSCache<NSString, UIImage>()
    
    // UserDefaults keys
    private let selectedAssetIDsKey = "ANiceClock_SelectedAssetIDs"
    private let slideshowDurationKey = "ANiceClock_SlideshowDuration"
    
    init() {
        setupCache()
        loadSavedData()
        print("📱 GalleryManager initialized with \(selectedAssetIDs.count) asset IDs")
    }
    
    private func setupCache() {
        imageCache.countLimit = 50 // Keep max 50 images in memory
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB memory limit
    }
    
    // MARK: - Asset-Based Photo Management (No File Storage)
    func addPhotoAsset(assetID: String) {
        // Check if this asset is already selected
        if selectedAssetIDs.contains(assetID) {
            print("📸 Photo already selected, skipping: \(assetID)")
            return
        }
        
        // Only store the asset ID - no file copying
        selectedAssetIDs.append(assetID)
        saveAssetIDs()
        print("✅ Asset ID added: \(assetID) (no local copy)")
        
        // Load this image if it's the first one
        if selectedAssetIDs.count == 1 {
            loadCurrentImageFromAsset()
        }
    }
    
    func removePhoto(at index: Int) {
        guard index < selectedAssetIDs.count else { return }
        
        let assetID = selectedAssetIDs[index]
        
        // Remove from selection
        selectedAssetIDs.remove(at: index)
        
        // Remove from cache
        imageCache.removeObject(forKey: assetID as NSString)
        
        // Adjust current index
        if currentIndex >= selectedAssetIDs.count {
            currentIndex = max(0, selectedAssetIDs.count - 1)
        }
        
        saveAssetIDs()
        loadCurrentImageFromAsset()
        print("🗑️ Asset ID removed: \(assetID)")
    }
    
    func clearAllPhotos() {
        stopSlideshow()
        
        selectedAssetIDs.removeAll()
        currentIndex = 0
        currentImage = nil
        imageCache.removeAllObjects()
        saveAssetIDs()
        print("🗑️ All asset IDs removed (no files deleted)")
    }
    
    // MARK: - On-Demand Image Loading from Photo Library
    private func loadCurrentImageFromAsset() {
        guard !selectedAssetIDs.isEmpty, currentIndex < selectedAssetIDs.count else {
            currentImage = nil
            return
        }
        
        let assetID = selectedAssetIDs[currentIndex]
        loadImageFromAsset(assetID: assetID) { [weak self] image in
            DispatchQueue.main.async {
                self?.currentImage = image
                if image != nil {
                    print("🖼️ Loaded image from Photo Library: \(assetID)")
                } else {
                    print("❌ Failed to load image from Photo Library: \(assetID)")
                }
            }
        }
    }
    
    private func loadImageFromAsset(assetID: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: assetID as NSString) {
            completion(cachedImage)
            return
        }
        
        // Load from Photo Library
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            completion(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // Allow iCloud downloads
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1920, height: 1920), // High quality for gallery
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            if let image = image {
                // Cache the loaded image
                self?.imageCache.setObject(image, forKey: assetID as NSString)
            }
            completion(image)
        }
    }
    
    func ensureCurrentImageLoaded() {
        if currentImage == nil && !selectedAssetIDs.isEmpty {
            loadCurrentImageFromAsset()
        }
    }
    
    // MARK: - Slideshow
    func startSlideshow() {
        guard !selectedAssetIDs.isEmpty && selectedAssetIDs.count > 1 else {
            print("📷 Not starting slideshow - need at least 2 photos")
            return
        }
        
        stopSlideshow()
        print("▶️ Starting slideshow with \(selectedAssetIDs.count) photos, duration: \(slideshowDuration)s")
        
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: slideshowDuration, repeats: true) { _ in
            self.nextPhoto()
        }
    }
    
    func stopSlideshow() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
        print("⏹️ Stopping slideshow")
    }
    
    func nextPhoto() {
        guard !selectedAssetIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % selectedAssetIDs.count
        loadCurrentImageFromAsset()
        print("➡️ Next photo: \(currentIndex + 1)/\(selectedAssetIDs.count)")
    }
    
    func previousPhoto() {
        guard !selectedAssetIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : selectedAssetIDs.count - 1
        loadCurrentImageFromAsset()
        print("⬅️ Previous photo: \(currentIndex + 1)/\(selectedAssetIDs.count)")
    }
    
    // MARK: - Persistence (Only Asset IDs)
    private func saveAssetIDs() {
        UserDefaults.standard.set(selectedAssetIDs, forKey: selectedAssetIDsKey)
        print("💾 Saved \(selectedAssetIDs.count) asset IDs to UserDefaults")
    }
    
    private func loadSavedData() {
        // Load asset IDs
        if let savedAssetIDs = UserDefaults.standard.array(forKey: selectedAssetIDsKey) as? [String] {
            selectedAssetIDs = savedAssetIDs
        }
        
        // Load slideshow duration
        let savedDuration = UserDefaults.standard.double(forKey: slideshowDurationKey)
        if savedDuration > 0 {
            slideshowDuration = savedDuration
        }
        
        // Load current image
        loadCurrentImageFromAsset()
        
        print("📁 Loaded \(selectedAssetIDs.count) asset IDs, duration: \(slideshowDuration)s")
    }
    
    func updateSlideshowDuration(_ newDuration: TimeInterval) {
        slideshowDuration = newDuration
        UserDefaults.standard.set(slideshowDuration, forKey: slideshowDurationKey)
        
        // Restart slideshow with new duration if it's running
        if slideshowTimer != nil {
            startSlideshow()
        }
        
        print("⏱️ Slideshow duration updated to \(slideshowDuration)s")
    }
    
    // MARK: - Selection State Management
    func isAssetSelected(_ assetID: String) -> Bool {
        return selectedAssetIDs.contains(assetID)
    }
    
    func getSelectedAssetIDs() -> [String] {
        return selectedAssetIDs
    }
    
    // MARK: - Compatibility Properties for UI
    var selectedPhotos: [String] {
        return selectedAssetIDs // For compatibility with existing UI code
    }
    
    var currentAssetIndex: Int {
        return currentIndex
    }
} 