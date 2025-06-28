# **OpenT**

## **Overview**
OpenT is a project designed to facilitate optical projection tomography (OPT) reconstruction and acquisition. This project uses proprietary camera software for acquisition and an Arduino for hardware triggering to the camera and CoolLed p2. The reconstruction process leverages ImageJ Fiji and the discontinued Bruker software nRecon.

## **Features**
- **Hardware Triggering**: Utilize an Arduino to control the camera and CoolLed p2.
- **Acquisition Software**: Compatible with proprietary camera software.
- **Reconstruction**: Based on ImageJ Fiji and Bruker software nRecon.

## **Installation**

### **Hardware Setup**
1. **Arduino**: Set up the Arduino for hardware triggering. Connect it to your camera and CoolLed p2.
2. **CoolLed p2**: Ensure CoolLed p2 is connected and configured correctly.

### **Software Setup**
1. **ImageJ Fiji**: Download and install ImageJ Fiji from [here](https://imagej.net/Fiji/Downloads).
2. **nRecon**: Obtain a copy of the discontinued Bruker software nRecon if available.

## **Usage**

### **Acquisition**
1. Use the proprietary camera software to perform the image acquisition.
2. The Arduino will handle the hardware triggering process.

### **Reconstruction**
1. Load the acquired images into ImageJ Fiji.
2. Use the reconstruction plugin in ImageJ Fiji to process the images.
3. Optionally, use nRecon for additional reconstruction capabilities.

## **Requirements**
- **Arduino**: For hardware triggering.
- **CoolLed p2**: Light source for imaging.
- **Proprietary Camera Software**: For image acquisition.
- **ImageJ Fiji**: For image reconstruction.
- **nRecon**: Optional, for enhanced reconstruction features.

## **Contributors**
- Gabriel Martins and Alexandre Lopes

## **License**
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

### **MIT License**

