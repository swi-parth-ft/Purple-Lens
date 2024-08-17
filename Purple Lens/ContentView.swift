//
//  ContentView.swift
//  Purple Lens
//
//  Created by Parth Antala on 8/17/24.
//

import SwiftUI
import FirebaseVertexAI

struct ContentView: View {
    
    let vertex = VertexAI.vertexAI()
    @State private var image: UIImage?
    @State private var isShowingImagePicker = false
    let prompt = "What's in this picture?"
    @State private var obervation: String = ""
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Tap the button to take a photo")
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                isShowingImagePicker = true
            }) {
                Text("Take Photo")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button("See") {
                Task {
                    do {
                        try await look()
                    } catch {
                        
                    }
                }
            }
            Text(obervation)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    func look() async throws {
        let model = vertex.generativeModel(modelName: "gemini-1.5-flash")
        let contentStream = model.generateContentStream(image!, prompt)
        for try await chunk in contentStream {
          if let text = chunk.text {
            obervation = text
            print(text)
          }
        }
    }
}


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
#Preview {
    ContentView()
}
