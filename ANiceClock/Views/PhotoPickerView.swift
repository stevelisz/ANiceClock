import SwiftUI
import Photos
import PhotosUI

// MARK: - Native Photo Picker with Selection State (Like Screenshots)
struct PhotoPickerView: View {
    @ObservedObject var galleryManager: GalleryManager
    @Binding var isPresented: Bool
    
    var body: some View {
        Button("Select Photos") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            NativePhotoPickerView(galleryManager: galleryManager, isPresented: $isPresented)
        }
    }
}

// MARK: - Native Photo Picker Implementation
struct NativePhotoPickerView: View {
    @ObservedObject var galleryManager: GalleryManager
    @Binding var isPresented: Bool
    @State private var allPhotos: [PHAsset] = []
    @State private var selectedAssets: Set<String> = []
    @State private var hasPermission = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if hasPermission {
                    if allPhotos.isEmpty {
                        VStack {
                            ProgressView()
                            Text("Loading photos...")
                                .padding(.top)
                        }
                    } else {
                        VStack(spacing: 0) {
                            // Photo count and clear button
                            HStack {
                                Text("\(selectedAssets.count) photos selected")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !selectedAssets.isEmpty {
                                    Button("Clear All") {
                                        selectedAssets.removeAll()
                                    }
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            
                            // Photo grid
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 2) {
                                    ForEach(allPhotos.indices, id: \.self) { index in
                                        let asset = allPhotos[index]
                                        PhotoGridItem(
                                            asset: asset,
                                            isSelected: selectedAssets.contains(asset.localIdentifier),
                                            onTap: {
                                                toggleSelection(asset)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("Photo Access Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Please allow access to your photo library to select photos for the gallery")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Grant Access") {
                            requestPhotoPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    isPresented = false
                },
                trailing: HStack {
                    if !selectedAssets.isEmpty {
                        Text("Selected: \(selectedAssets.count)")
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                }
            )
        }
        .onAppear {
            loadCurrentSelection()
            checkPhotoPermission()
        }
        .onDisappear {
            saveSelection()
        }
    }
    
    private func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            hasPermission = true
            loadPhotos()
        case .notDetermined:
            requestPhotoPermission()
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }
    
    private func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    hasPermission = true
                    loadPhotos()
                default:
                    hasPermission = false
                }
            }
        }
    }
    
    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var photos: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }
        
        DispatchQueue.main.async {
            allPhotos = photos
        }
    }
    
    private func loadCurrentSelection() {
        selectedAssets = Set(galleryManager.getSelectedAssetIDs())
        print("📸 Loaded \(selectedAssets.count) previously selected photos")
    }
    
    private func toggleSelection(_ asset: PHAsset) {
        if selectedAssets.contains(asset.localIdentifier) {
            selectedAssets.remove(asset.localIdentifier)
        } else {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
    
    private func saveSelection() {
        print("📸 Saving \(selectedAssets.count) selected asset IDs...")
        
        // Clear existing photos
        galleryManager.clearAllPhotos()
        
        // Add selected asset IDs (no file copying)
        for assetID in selectedAssets {
            galleryManager.addPhotoAsset(assetID: assetID)
        }
        
        print("✅ Saved \(selectedAssets.count) asset IDs (no storage used)")
    }
}

// MARK: - Photo Grid Item with Blue Selection Borders
struct PhotoGridItem: View {
    let asset: PHAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            // Photo
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            }
            .frame(width: 100, height: 100)
            .clipped()
            .cornerRadius(8)
            
            // Blue selection border (like native iOS behavior)
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 100, height: 100)
            }
            
            // Selection checkmark (top right corner)
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.blue : Color.black.opacity(0.5))
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
} 