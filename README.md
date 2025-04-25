# MATE – Microwave Ablation Temperature Estimation

**MATE** is a deep learning-based system for non-invasive, continuous estimation of tissue temperature during microwave ablation (MWA) using ultrasound (US) imaging data.

The goal of this project is to develop an AI-assisted method that predicts temperature evolution during thermal tumor ablation based solely on B-mode ultrasound video – eliminating the need for invasive thermoprobes.

## 🔬 Background

In MWA, precise temperature monitoring is critical to ensure effective coagulative necrosis within the target volume and to avoid thermal damage to adjacent structures. Conventional temperature monitoring relies on invasive sensors or imaging-guided follow-up checks, which come with procedural risks and limited spatial coverage. **MATE** leverages convolutional neural networks (CNNs) and transfer learning (ResNet18) to infer thermal information directly from standard US images.

## ⚙️ Key Features

- Automated frame extraction and temperature labeling from synchronized video/thermoprobe data
- Image preprocessing: cropping, artifact removal, resizing to 224×224 px
- CNN training using ResNet18 with regression head (transfer learning)
- Data augmentation (rotation, flipping, brightness shifts)
- Performance evaluation on unseen test data via RMSE

## 🧠 Technologies Used

- MATLAB (Deep Learning Toolbox)
- ResNet18 (ImageNet pretrained)
- Ultrasound video data @ 30 fps

## 📈 Status

This repository accompanies a feasibility study. Initial results demonstrate promising correlation between ultrasound texture and temperature evolution in agar-egg white phantoms. Future work will focus on improving performance and transitioning to in-vivo settings.


