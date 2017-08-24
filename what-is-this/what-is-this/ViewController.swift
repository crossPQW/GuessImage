//
//  ViewController.swift
//  what-is-this
//
//  Created by 黄少华 on 2017/8/24.
//  Copyright © 2017年 黄少华. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var probability: UILabel!    
    @IBOutlet weak var resultLabel: UILabel!
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func grabAPicture(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: "选择图片", preferredStyle:  .actionSheet)
        let cameraAction = UIAlertAction(title: "相机", style: .default) {
            _ in
            self.takePhoto(from: .camera)
        }
        
        let libraryAction = UIAlertAction(title: "照片图库", style: .default, handler: {
            _ in
            self.takePhoto(from: .photoLibrary)
        })
        
        let cancelLibrary = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelLibrary)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
}

extension ViewController {
    enum PhotoSource {
        case camera, photoLibrary
    }
    
    func takePhoto(from source: PhotoSource) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = (source == .camera ? .camera : .photoLibrary)
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func resize(image: UIImage, to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return newImage
    }
}

extension ViewController {
    func guess(image: UIImage) {
        guard let ciImage = CIImage(image: image) else { fatalError("无法创建 core image 对象") }
        
        //1.加载 CoreML 模型
        guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else { fatalError("无法加载 CoreML 模型") }
        
        //2.创建 vision 请求
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else {
                fatalError("无法从 VNCoreMLRequest 中获取结果")
            }
            
            DispatchQueue.main.async {
                self.resultLabel.text = firstResult.identifier
                self.probability.text = "有 \(firstResult.confidence * 100)/100的概率上图是"
            }
        }
        
        //3.执行 Vision request
        let requestHandler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            try? requestHandler.perform([request])
        }
    }
}

// MARK UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = image
            
            if let newImage = resize(image: image, to: CGSize(width: 224, height: 224)) {
                guess(image: newImage)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
