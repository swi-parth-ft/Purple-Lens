//
//  ContentView.swift
//  Purple Lens
//
//  Created by Parth Antala on 8/17/24.
//

import SwiftUI
import FirebaseVertexAI
import DotLottie

struct ContentView: View {
    
    let vertex = VertexAI.vertexAI()
    @State private var image: UIImage?
    @State private var isShowingImagePicker = false
    @State private var prompt = "What's in this picture?"
    @State private var obervation: String = ""
    @State private var isLoading = false
    @State private var isLoaded = false
    
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        
        ZStack {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color(red: 0.2, green: 0.2, blue: 0.7),  // Dark Blue
                Color(red: 0.4, green: 0.4, blue: 0.8),  // Medium Blue
                Color(red: 0.6, green: 0.6, blue: 0.9),  // Light Blue
                Color(red: 0.3, green: 0.2, blue: 0.5),  // Purple
                Color(red: 0.5, green: 0.3, blue: 0.7),  // Medium Purple
                Color(red: 0.7, green: 0.4, blue: 0.9),  // Light Purple
                Color(red: 0.2, green: 0.5, blue: 0.5),  // Teal
                Color(red: 0.4, green: 0.7, blue: 0.7),  // Medium Teal
                Color(red: 0.6, green: 0.9, blue: 0.9)   // Light Teal
            ])
            .ignoresSafeArea()
            
            
            VStack {
                
                VStack(spacing: -30) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(22)
                            .shadow(color: .gray, radius: 10)
                            .frame(width: UIScreen.main.bounds.width * 0.9)
                            .padding(.top, -70)
                        
                        
                        
                    } else {
                        VStack {
                            Spacer()
                            Text("Welcome to Purple Eye!")
                                .font(.title)
                                .foregroundStyle(.white)
                            Text("Capture a Photo to continue")
                                .foregroundStyle(.secondary)
                            
                            
                            ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to take a photo"))
                                .foregroundStyle(.white)
                                .onTapGesture {
                                    isShowingImagePicker = true
                                }
                                .frame(width: 300, height: 300)
                            Spacer()
                        }
                    }
                    if image != nil {
                        HStack {
                            TextField("What are you looking for?", text: $prompt)
                                .padding()
                                .background(
                                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                                        .cornerRadius(22)
                                )
                                .cornerRadius(22) // Make sure the corner radius matches
                                .padding()
                            
                            
                            Button {
                                hideKeyboard()
                                obervation = ""
                                isLoaded = false
                                Task {
                                    do {
                                        
                                        try await look()
                                    } catch {
                                        
                                    }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 50)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20))
                                        .foregroundStyle((image != nil) ? .purple : .gray)
                                        .shadow(radius: 5)
                                }
                                
                            }
                            .tint(.white)
                            .padding(.trailing)
                        }
                    }
                }
                
                if isLoaded {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.5))
                        ScrollView {
                            Text(obervation)
                                .padding()
                                .animation(.easeInOut(duration: 0.5), value: obervation)
                        }
                    }
                } else if isLoading {
                    DotLottieAnimation(fileName: "StoryLoading", config: AnimationConfig(autoplay: true, loop: true)).view()
                        .frame(width: 340, height: 150)
                }
                Spacer()
                
                if isLoaded {
                    Button("Clear", systemImage: "bubbles.and.sparkles") {
                        obervation = ""
                        isLoaded = false
                        isLoading = false
                        image = nil
                    }
                    .tint(.white)
                    .padding()
                    .background(.white.opacity(0.4))
                    .cornerRadius(22)
                }
                
                
                
                
                
                
                
            }
            .padding()
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $image)
            }
        }
        
        
    }
    
    func look() async throws {
            isLoading = true
            let model = vertex.generativeModel(modelName: "gemini-1.5-flash")
            let contentStream = model.generateContentStream(image!, prompt)
            
            // Buffer to accumulate text chunks
            var accumulatedText = ""
            
            for try await chunk in contentStream {
                if let text = chunk.text {
                    // Add new chunk to the buffer
                    accumulatedText += text
                    
                    await MainActor.run {
                        // Append characters with delay to simulate typing effect
                        Task {
                            // Clear observation and append characters one by one
                            var tempText = ""
                            for character in accumulatedText {
                                tempText += String(character)
                                obervation = tempText
                                // Delay for a brief moment between characters
                                try? await Task.sleep(nanoseconds: 20_000_000) // 0.1 seconds
                            }
                        }
                        isLoading = false
                        isLoaded = true
                    }
                }
            }
        }}


import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: blurStyle)
        let view = UIVisualEffectView(effect: effect)
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ContentView()
}
