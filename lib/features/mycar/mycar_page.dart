// マイカー登録・編集画面
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/vehicle_model.dart';
import '../../core/services/vehicle_store.dart';

class MyCarPage extends StatefulWidget {
  const MyCarPage({super.key});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  
  bool _isEv = false;
  String? _photoPath;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleData() async {
    setState(() => _isLoading = true);
    
    try {
      final vehicle = await VehicleStore.loadVehicle();
      if (vehicle != null && mounted) {
        setState(() {
          _nameController.text = vehicle.name;
          _manufacturerController.text = vehicle.manufacturer;
          _yearController.text = vehicle.year?.toString() ?? '';
          _plateController.text = vehicle.plateNumber ?? '';
          _isEv = vehicle.isEv;
          _photoPath = vehicle.photoPath;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('車両情報の読み込みに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null && mounted) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('写真の選択に失敗しました');
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final vehicle = VehicleModel(
        name: _nameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        year: _yearController.text.isNotEmpty 
            ? int.tryParse(_yearController.text.trim()) 
            : null,
        plateNumber: _plateController.text.trim().isNotEmpty 
            ? _plateController.text.trim() 
            : null,
        isEv: _isEv,
        photoPath: _photoPath,
      );
      
      final result = await VehicleStore.saveVehicleWithValidation(vehicle);
      
      if (mounted) {
        if (result['success']) {
          _showSuccessSnackBar(result['message']);
          // 保存成功時は前の画面に戻る
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar(result['error']);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('保存に失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイカー登録'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveVehicle,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 車の写真
                    _buildPhotoSection(),
                    const SizedBox(height: 24),
                    
                    // 車名（必須）
                    _buildTextField(
                      controller: _nameController,
                      label: '車名',
                      hint: '例: プリウス、アクア',
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '車名は必須です';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // メーカー
                    _buildTextField(
                      controller: _manufacturerController,
                      label: 'メーカー',
                      hint: '例: トヨタ、日産、ホンダ',
                    ),
                    const SizedBox(height: 16),
                    
                    // 年式
                    _buildTextField(
                      controller: _yearController,
                      label: '年式',
                      hint: '例: 2020',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final year = int.tryParse(value);
                          if (year == null || year < 1900 || year > DateTime.now().year) {
                            return '1900年以降の年式を入力してください';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ナンバー（任意）
                    _buildTextField(
                      controller: _plateController,
                      label: 'ナンバー（任意）',
                      hint: '例: 品川 123 あ 1234',
                    ),
                    const SizedBox(height: 24),
                    
                    // EVスイッチ
                    _buildEvSwitch(),
                    const SizedBox(height: 32),
                    
                    // 保存ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '車の写真（任意）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _photoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photoPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'タップして写真を選択',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFB300)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEv ? const Color(0xFFFFB300).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEv ? const Color(0xFFFFB300) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.electric_car,
            color: _isEv ? const Color(0xFFFFB300) : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EV（電気自動車）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isEv ? const Color(0xFFFFB300) : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEv 
                      ? 'EV車として登録されます（ポイント優遇あり）'
                      : 'ガソリン車として登録されます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEv,
            onChanged: (value) {
              setState(() => _isEv = value);
            },
            activeColor: const Color(0xFFFFB300),
          ),
        ],
      ),
    );
  }
}
