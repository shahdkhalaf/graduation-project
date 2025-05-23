import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MakeComplaintScreen extends StatefulWidget {
  const MakeComplaintScreen({Key? key}) : super(key: key);

  @override
  _MakeComplaintScreenState createState() => _MakeComplaintScreenState();
}

class _MakeComplaintScreenState extends State<MakeComplaintScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _detailsController = TextEditingController();

  String? selectedComplaintType;
  XFile? imageFile;

  final List<String> complaintTypes = [
    'رفع سعر المواصلة',
    'عدم التزام السائق بالخط الرئيسي للطريق',
    'العربية مش بتقف فى المكان المخصص ليها فى الموقف',
    'سلوك السواقين و تعاملهم مع الركاب',
    'نوع آخر',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => imageFile = pickedFile);
    }
  }

  void _submitComplaint() {
    if (selectedComplaintType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complaint type.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF175579),
                child: Icon(Icons.check, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 16),
              const Text(
                "Complaint Submitted",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "Type:\n$selectedComplaintType\n\nYour complaint and photo have been saved successfully!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF175579),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 120),
                ),
                child: const Text("OK",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF175579),
              child: Image.asset('assets/img_1.png', width: 32, height: 32),
            ),
            const SizedBox(width: 12),
            const Text(
              'Make a Complaint',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Complaint Type'),
            const SizedBox(height: 15),
            _buildDropdown(),
            const SizedBox(height: 20),
            _buildSectionTitle('Upload Evidence'),
            const SizedBox(height: 16),
            _buildImageUploadRow(),
            const SizedBox(height: 35),
            _buildSectionTitle('Additional Details'),
            const SizedBox(height: 16),
            _buildDetailsField(),
            const SizedBox(height: 80),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedComplaintType,
          hint: const Text('Select complaint type'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (value) => setState(() => selectedComplaintType = value),
          items: complaintTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImageUploadRow() {
    return Row(
      children: [
        Expanded(
            child: _buildImageUploadOption('Upload Image', Icons.upload,
                () => _pickImage(ImageSource.gallery))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildImageUploadOption('Take Photo', Icons.camera_alt,
                () => _pickImage(ImageSource.camera))),
      ],
    );
  }

  Widget _buildImageUploadOption(
      String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: DottedBorder(
        dashPattern: const [6, 4],
        color: Colors.grey,
        strokeWidth: 1,
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: Container(
          height: 100,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsField() {
    return DottedBorder(
      dashPattern: const [4, 4],
      color: Colors.grey,
      strokeWidth: 1,
      borderType: BorderType.RRect,
      radius: const Radius.circular(8),
      child: Container(
        height: 135,
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _detailsController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText:
                'Please provide any additional details about your complaint...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _submitComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF175579),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: const Text('Submit Complaint',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
