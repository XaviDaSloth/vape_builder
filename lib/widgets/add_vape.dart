import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';

void showAddVapeItemDialog(BuildContext context, Function(Map<String, dynamic>) onAddItem) {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stocksController = TextEditingController();
  final TextEditingController dateReleasedController = TextEditingController(text: DateTime.now().toLocal().toString().split(' ')[0]);
  final TextEditingController priceController = TextEditingController();


  double tempVaporProduction = 1;
  double tempPuffCount = 1000;

  String selectedVapeType = "Vape Mods"; // Default selection
  String selectedNicotine = "0 mg";
  String selectedSize = "Small";
  String selectedPodSystemType = "Closed";
  String selectedBatteryLife = "Short";
  String selectedNicotineType = "Salt Nicotine";
  File? selectedImage; // Holds the selected image file
  
  String _getDefaultImage(String vapeType) {
    switch (vapeType) {
      case "Vape Mods":
        return "assets/images/vapeMod.png";
      case "Vape Dispos":
        return "assets/images/vapeDispo.png";
      case "Pod Systems":
        return "assets/images/podSystems.png";
      default:
        return "assets/images/vapemods_test.png"; // Fallback image
    }
  }

  Future<File?> pickAndCompressImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,  // or ImageSource.camera
      imageQuality: 100, // Keeps high quality
      maxWidth: 1080,
    );

    if (pickedFile == null) return null; // No image selected

    // Crop the image to 120x150 pixels
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: CropAspectRatio(ratioX: 120, ratioY: 250),
      maxWidth: 120, // Set exact size
      maxHeight: 250,
      compressQuality: 100, // Keep original quality
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true, // Keep the 120x150 aspect ratio
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return null; // No cropping done

    // Read the cropped image as bytes
    Uint8List bytes = await File(croppedFile.path).readAsBytes();

    // Compress the cropped image
    Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 85, // Adjust quality (lower value = smaller size)
      format: CompressFormat.jpeg, // Ensure JPEG format
    );

    // Generate a unique filename using timestamp
    final String uniqueFileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Save compressed image to a temporary file
    final directory = await getTemporaryDirectory();
    final compressedFile = File('${directory.path}/$uniqueFileName');
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            title: Text("Add New Vape Item", style: Theme.of(context).textTheme.bodyLarge,),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 5),
                    _buildDropdown(
                      context,
                      "Vape Type",
                      selectedVapeType,
                      ["Vape Mods", "Vape Dispos", "Pod Systems"],
                      (value) => setModalState(() {
                        _onDropdownChanged(value, (newValue) => selectedVapeType = newValue);
                      }),
                    ),
                    SizedBox(height: 10),
                    _buildValidatedTextField(context,"Name", nameController),
                    SizedBox(height: 10, ),
                    _buildValidatedTextField(context,"Brand", brandController),
                    SizedBox(height: 10),
                    if(selectedVapeType != "Vape Mods")...[
                      _buildDropdown(
                        context,
                        "Nicotine (mg)",
                        selectedNicotine,
                        ["0 mg", "3 mg", "6 mg", "12 mg", "18 mg"],
                        (value) => setModalState(() => selectedNicotine = value),
                      ),
                      SizedBox(height: 10)],
                    if (selectedVapeType != "Pod Systems")
                      _buildDropdown(
                        context,
                        "Size",
                        selectedSize,
                        ["Small", "Medium", "Large"],
                        (value) => setModalState(() => selectedSize = value),
                      ),
                    SizedBox(height: 10),
                    if(selectedVapeType != "Vape Mods")...[
                    Text("Puff Count: ${tempPuffCount.toInt()}"),
                    Slider(
                      value: tempPuffCount,
                      min: 0,
                      max: 20000,
                      divisions: 40,
                      label: "${tempPuffCount.toInt()}",
                      onChanged: (value) {
                        setModalState(() => tempPuffCount = value);
                      },
                    )],
                    Text("Vapor Production: ${_getVaporLabel(tempVaporProduction)}"),
                    Slider(
                      value: tempVaporProduction,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      label: _getVaporLabel(tempVaporProduction),
                      onChanged: (value) {
                        setModalState(() => tempVaporProduction = value);
                      },
                    ),
                    _buildValidatedTextField(context, "Description", descriptionController),
                    SizedBox(height: 10),
                    _buildValidatedTextField(context,"Stocks", stocksController, isNumeric: true),
                    SizedBox(height: 10),
                    TextField(
                      controller: dateReleasedController,
                      readOnly: true, // So users can't manually type
                      decoration: InputDecoration(
                        labelText: "Date Released",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context,dateReleasedController),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    if (selectedVapeType == "Pod Systems") ...[
                      _buildDropdown(
                        context,
                        "Pod System Type",
                        selectedPodSystemType,
                        ["Closed", "Open"],
                        (value) => setModalState(() => selectedPodSystemType = value),
                      ),
                      SizedBox(height: 10),
                      _buildDropdown(
                        context,
                        "Battery Life",
                        selectedBatteryLife,
                        ["Short", "Medium", "Long"],
                        (value) => setModalState(() => selectedBatteryLife = value),
                      ),
                      SizedBox(height: 10),
                      _buildDropdown(
                        context,
                        "Nicotine Type",
                        selectedNicotineType,
                        ["Salt Nicotine", "Freebase"],
                        (value) => setModalState(() => selectedNicotineType = value),
                      ),
                    ],
                    SizedBox(height: 10),
                    _buildValidatedTextField(context, "Price", priceController, isNumeric: true),
                    SizedBox(height: 10),
                      
                    Row(
                      children: [
                        Text("Add Image:"),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            File? compressedFile = await pickAndCompressImage();
                            setModalState(() {
                              selectedImage = compressedFile;
                            });
                          },
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(selectedImage!, fit: BoxFit.cover),
                                  )
                                : Image.asset(
                                    _getDefaultImage(selectedVapeType),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: Theme.of(context).textTheme.bodyMedium),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {

                    final String defaultImagePath = _getDefaultImage(selectedVapeType);

                    final newItem = {
                      "name": nameController.text,
                      "brand": brandController.text,
                      "nicotine_mg": selectedNicotine,
                      "size": selectedVapeType == "Pod Systems" ? null : selectedSize,
                      "puff_count": tempPuffCount.toInt(),
                      "vapor": _getVaporLabel(tempVaporProduction),
                      "description": descriptionController.text,
                      "stocks": int.tryParse(stocksController.text) ?? 0,
                      "price": double.tryParse(priceController.text) ?? 0.0,
                      "date_released": dateReleasedController.text,
                      "image": selectedImage?.path ?? defaultImagePath,  // Assign default image path,
                      "category": selectedVapeType,
                    };

                    if (selectedVapeType == "Pod Systems") {
                      newItem["pod_system_type"] = selectedPodSystemType;
                      newItem["battery_life"] = selectedBatteryLife;
                      newItem["nicotine_type"] = selectedNicotineType;
                    }

                    print("Adding item: $newItem"); // Final check before saving
                    onAddItem(newItem);
                    Navigator.pop(context);
                  }
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

// Vapor Label Helper
String _getVaporLabel(double value) {
  switch (value.toInt()) {
    case 0: return "Low";
    case 1: return "Medium";
    case 2: return "High";
    default: return "Low";
  }
}

// Helper Functions for UI
Widget _buildDropdown(BuildContext context, String label, String selectedValue, List<String> items, Function(String) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          labelStyle: GoogleFonts.raleway(
            fontSize: 16,
            color: const Color(0xFF41378B),
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.all(4),
        ),
        style: GoogleFonts.raleway(
          fontWeight: FontWeight.normal,
          color: const Color.fromARGB(255, 214, 214, 214),
        ),
        value: selectedValue,
        isExpanded: true,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (value) => onChanged(value!),
        dropdownColor: Theme.of(context).colorScheme.tertiary ,
        
      ),
    ],
  );
}

Widget _buildValidatedTextField(BuildContext context, String label, TextEditingController controller, {bool isNumeric = false}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return "$label is required";
      }
      if (isNumeric && int.tryParse(value) == null) {
        return "Enter a valid number";
      }
      return null;
    },
  );
}

Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  
  if (picked != null) {
    controller.text = "${picked.toLocal()}".split(' ')[0]; // Formats as YYYY-MM-DD
  }
}

_onDropdownChanged(String value, Function(String) setStateFunction) {
  print("Dropdown changed to: $value");
  setStateFunction(value);
}
