import SwiftUI
import Photos
import PhotosUI

// MARK: - Photo Collection Picker View (Native Approach)
struct PhotoCollectionPickerView: View {
    @ObservedObject var galleryManager: GalleryManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSystemPicker = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    // Add Photos Button
                    AddPhotosButton {
                        print("🔍 Add Photos button tapped - checking permission...")
                        print("🔍 Current permission status: \(galleryManager.hasPermission)")
                        print("🔍 Current photo count: \(galleryManager.selectedAssetIDs.count)")
                        showingSystemPicker = true
                    }
                    
                    // Grid of selected photos (native thumbnails)
                    ForEach(galleryManager.selectedPhotos) { photo in
                        SelectedPhotoThumbnail(
                            photo: photo, 
                            galleryManager: galleryManager,
                            onRemove: {
                                galleryManager.removeAsset(withID: photo.id)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Selected Photos (\(galleryManager.selectedAssetIDs.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingSystemPicker) {
                NativePHPickerView(galleryManager: galleryManager)
            }
        }
    }
}

// MARK: - Native PHPicker Implementation
struct NativePHPickerView: UIViewControllerRepresentable {
    @ObservedObject var galleryManager: GalleryManager
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        print("🎯 Creating PHPickerViewController...")
        
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // 0 means no limit
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        print("🎯 PHPickerViewController created with config: images only, no limit")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: NativePHPickerView
        
        init(_ parent: NativePHPickerView) {
            self.parent = parent
            super.init()
            print("🎯 PHPicker Coordinator initialized")
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("🎯 PHPicker didFinishPicking called with \(results.count) results")
            
            Task { @MainActor in
                // Process each selected result
                for (index, result) in results.enumerated() {
                    print("🎯 Processing result \(index + 1)/\(results.count)")
                    
                    // Try the direct assetIdentifier first
                    if let assetIdentifier = result.assetIdentifier {
                        print("🎯 Got direct asset identifier: \(assetIdentifier)")
                        
                        // Fetch the PHAsset using the identifier
                        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                        if let asset = fetchResult.firstObject {
                            print("🎯 Successfully fetched PHAsset, adding to gallery...")
                            parent.galleryManager.addAsset(asset)
                            print("🎯 Asset added! New count: \(parent.galleryManager.selectedAssetIDs.count)")
                        } else {
                            print("❌ Failed to fetch PHAsset for identifier: \(assetIdentifier)")
                        }
                    } else {
                        print("🎯 No direct asset identifier, trying alternative native approach...")
                        
                        // Alternative method: Try to get asset identifier from the itemProvider
                        // This works by loading the data and then using Photos framework to find the asset
                        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                            print("🎯 ItemProvider has image data, attempting to find PHAsset...")
                            
                            // Load image data
                            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                                if let error = error {
                                    print("❌ Error loading image data: \(error)")
                                    return
                                }
                                
                                guard let imageData = data, let image = UIImage(data: imageData) else {
                                    print("❌ Failed to create image from data")
                                    return
                                }
                                
                                // Try to find matching PHAsset in photo library
                                self?.findMatchingPHAsset(for: image) { asset in
                                    DispatchQueue.main.async {
                                        if let asset = asset {
                                            print("🎯 Found matching PHAsset: \(asset.localIdentifier)")
                                            self?.parent.galleryManager.addAsset(asset)
                                            print("🎯 Asset added! New count: \(self?.parent.galleryManager.selectedAssetIDs.count ?? 0)")
                                        } else {
                                            print("❌ Could not find matching PHAsset for image")
                                        }
                                    }
                                }
                            }
                        } else {
                            print("❌ ItemProvider does not have image data")
                        }
                    }
                }
                
                print("🎯 Finished processing all results, dismissing picker...")
                // Dismiss the picker
                parent.dismiss()
            }
        }
        
        // Helper method to find matching PHAsset for an image
        private func findMatchingPHAsset(for image: UIImage, completion: @escaping (PHAsset?) -> Void) {
            print("🔍 Searching for matching PHAsset...")
            
            // Create fetch options to get recent photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 100 // Check last 100 photos
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // Get image size for comparison
            let targetSize = image.size
            
            DispatchQueue.global(qos: .userInitiated).async {
                var foundAsset: PHAsset?
                
                fetchResult.enumerateObjects { asset, index, stop in
                    // Compare image dimensions as a quick filter
                    if abs(asset.pixelWidth - Int(targetSize.width)) < 10 && 
                       abs(asset.pixelHeight - Int(targetSize.height)) < 10 {
                        print("🔍 Found potential match at index \(index): \(asset.localIdentifier)")
                        foundAsset = asset
                        stop.pointee = true
                    }
                }
                
                completion(foundAsset)
            }
        }
    }
}

// MARK: - Add Photos Button
struct AddPhotosButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                Text("Add Photos")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Selected Photo Thumbnail (Native Approach)
struct SelectedPhotoThumbnail: View {
    let photo: GalleryPhoto
    let galleryManager: GalleryManager
    let onRemove: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    private let thumbnailSize = CGSize(width: 150, height: 150)
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Fixed square container
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                
                ZStack {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size, height: size)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: size, height: size)
            }
            .aspectRatio(1.0, contentMode: .fit)
            
            // Remove button (native removal)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onRemove()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                    )
            }
            .padding(6)
        }
        .onAppear(perform: loadThumbnail)
    }
    
    private func loadThumbnail() {
        // Load PHAsset thumbnail
        guard let asset = photo.asset else { 
            print("❌ No PHAsset found for photo ID: \(photo.id)")
            return 
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    print("✅ PHAsset thumbnail loaded successfully")
                    self.thumbnailImage = image
                } else {
                    print("❌ Failed to load PHAsset thumbnail")
                }
            }
        }
    }
} 