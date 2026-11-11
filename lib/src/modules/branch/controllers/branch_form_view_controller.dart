import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../tools/cache/app_image_cache.dart';
import '../../../tools/uploaders/image_uploader.dart';

/// Firma de función para la subida de imágenes, permitiendo inyección de mocks en pruebas unitarias.
typedef ImageUploadFunction = Future<String?> Function({
  required Uint8List bytes,
  required String fileName,
});

/// Controlador de estado local para el diálogo de sucursal (`BranchFormDialog`).
/// Sigue la arquitectura canónica ViewController del estándar OKF v0.2.
class BranchFormViewController extends ChangeNotifier {
  final BranchInDb? initialBranch;

  // Controladores de texto para información general
  late final TextEditingController nameController;
  late final TextEditingController addressController;
  late final TextEditingController cityController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController facebookController;

  // Controladores de texto para el Bioanalista Representante
  late final TextEditingController bioanalystNameController;
  late final TextEditingController bioanalystTitleController;
  late final TextEditingController bioanalystCodeController;

  // Bioanalistas Auxiliares en memoria
  List<AuxBioanalyst> _auxBioList = [];

  // Logotipo (símbolo o icono compacto)
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoName;
  bool _isUploadingLogo = false;

  // IsoLogo (símbolo + nombre comercial integrado)
  String? _isoLogoUrl;
  Uint8List? _selectedIsoLogoBytes;
  String? _selectedIsoLogoName;
  bool _isUploadingIsoLogo = false;

  // Sello de Tinta del Bioanalista Representante
  String? _sealUrl;
  Uint8List? _selectedSealBytes;
  String? _selectedSealName;
  bool _isUploadingSeal = false;

  // Preferencias operativas y clínicas de la sucursal
  bool _autoCalculateFormulas = true;

  // Estado de persistencia general
  bool _isSaving = false;

  BranchFormViewController({this.initialBranch}) {
    nameController = TextEditingController(text: initialBranch?.name ?? '');
    addressController =
        TextEditingController(text: initialBranch?.address ?? '');
    cityController = TextEditingController(text: initialBranch?.city ?? '');
    phoneController = TextEditingController(text: initialBranch?.phone ?? '');
    emailController = TextEditingController(text: initialBranch?.email ?? '');
    facebookController =
        TextEditingController(text: initialBranch?.facebook ?? '');

    bioanalystNameController = TextEditingController(
      text: initialBranch?.bioanalyst?.name ?? '',
    );
    bioanalystTitleController = TextEditingController(
      text: initialBranch?.bioanalyst?.title ?? '',
    );
    bioanalystCodeController = TextEditingController(
      text: initialBranch?.bioanalyst?.code ?? '',
    );

    _logoUrl = initialBranch?.effectiveLogo;
    _isoLogoUrl = initialBranch?.isoLogoUrl;
    _sealUrl = initialBranch?.bioanalyst?.sealUrl;

    _autoCalculateFormulas = initialBranch?.autoCalculateFormulas ?? true;

    if (initialBranch?.auxBio != null) {
      _auxBioList = List<AuxBioanalyst>.from(initialBranch!.auxBio!);
    }
  }

  // --- Getters de Estado y Derivados ---

  bool get isEditing => initialBranch != null;
  bool get isSaving => _isSaving;

  String? get logoUrl => _logoUrl;
  Uint8List? get selectedLogoBytes => _selectedLogoBytes;
  String? get selectedLogoName => _selectedLogoName;
  bool get isUploadingLogo => _isUploadingLogo;
  bool get hasLogo =>
      _selectedLogoBytes != null || (_logoUrl != null && _logoUrl!.isNotEmpty);

  String? get isoLogoUrl => _isoLogoUrl;
  Uint8List? get selectedIsoLogoBytes => _selectedIsoLogoBytes;
  String? get selectedIsoLogoName => _selectedIsoLogoName;
  bool get isUploadingIsoLogo => _isUploadingIsoLogo;
  bool get hasIsoLogo =>
      _selectedIsoLogoBytes != null ||
      (_isoLogoUrl != null && _isoLogoUrl!.isNotEmpty);

  String? get sealUrl => _sealUrl;
  Uint8List? get selectedSealBytes => _selectedSealBytes;
  String? get selectedSealName => _selectedSealName;
  bool get isUploadingSeal => _isUploadingSeal;
  bool get hasSeal =>
      _selectedSealBytes != null || (_sealUrl != null && _sealUrl!.isNotEmpty);

  bool get isUploadingAny =>
      _isUploadingLogo || _isUploadingIsoLogo || _isUploadingSeal;

  List<AuxBioanalyst> get auxBioList => List.unmodifiable(_auxBioList);

  bool get autoCalculateFormulas => _autoCalculateFormulas;

  // --- Mutaciones de Estado ---

  void setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void setAutoCalculateFormulas(bool value) {
    _autoCalculateFormulas = value;
    notifyListeners();
  }

  void setUploadingLogo(bool uploading) {
    _isUploadingLogo = uploading;
    notifyListeners();
  }

  void setUploadingIsoLogo(bool uploading) {
    _isUploadingIsoLogo = uploading;
    notifyListeners();
  }

  void setUploadingSeal(bool uploading) {
    _isUploadingSeal = uploading;
    notifyListeners();
  }

  void setLogo({required Uint8List bytes, required String name}) {
    _selectedLogoBytes = bytes;
    _selectedLogoName = name;
    notifyListeners();
  }

  void removeLogo() {
    if (_logoUrl != null) {
      AppImageCache.evict(_logoUrl!);
    }
    _logoUrl = null;
    _selectedLogoBytes = null;
    _selectedLogoName = null;
    notifyListeners();
  }

  void setIsoLogo({required Uint8List bytes, required String name}) {
    _selectedIsoLogoBytes = bytes;
    _selectedIsoLogoName = name;
    notifyListeners();
  }

  void removeIsoLogo() {
    if (_isoLogoUrl != null) {
      AppImageCache.evict(_isoLogoUrl!);
    }
    _isoLogoUrl = null;
    _selectedIsoLogoBytes = null;
    _selectedIsoLogoName = null;
    notifyListeners();
  }

  void setSeal({required Uint8List bytes, required String name}) {
    _selectedSealBytes = bytes;
    _selectedSealName = name;
    notifyListeners();
  }

  void removeSeal() {
    if (_sealUrl != null) {
      AppImageCache.evict(_sealUrl!);
    }
    _sealUrl = null;
    _selectedSealBytes = null;
    _selectedSealName = null;
    notifyListeners();
  }

  void addAuxBioanalyst(AuxBioanalyst aux) {
    _auxBioList.add(aux);
    notifyListeners();
  }

  void updateAuxBioanalyst(int index, AuxBioanalyst aux) {
    if (index >= 0 && index < _auxBioList.length) {
      _auxBioList[index] = aux;
      notifyListeners();
    }
  }

  void removeAuxBioanalyst(int index) {
    if (index >= 0 && index < _auxBioList.length) {
      _auxBioList.removeAt(index);
      notifyListeners();
    }
  }

  // --- Generación de DTOs de Dominio ---

  Future<({String? logoUrl, String? isoLogoUrl, String? sealUrl})>
      _resolveImages({ImageUploadFunction? uploader}) async {
    final upload = uploader ?? ImageUploader.uploadImage;
    String? finalLogoUrl = _logoUrl;
    String? finalIsoLogoUrl = _isoLogoUrl;
    String? finalSealUrl = _sealUrl;

    try {
      if (_selectedLogoBytes != null) {
        setUploadingLogo(true);
        final fileName = _selectedLogoName ??
            'branch_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalLogoUrl = await upload(
          bytes: _selectedLogoBytes!,
          fileName: fileName,
        );
      }

      if (_selectedIsoLogoBytes != null) {
        setUploadingIsoLogo(true);
        final fileName = _selectedIsoLogoName ??
            'branch_isologo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalIsoLogoUrl = await upload(
          bytes: _selectedIsoLogoBytes!,
          fileName: fileName,
        );
      }

      if (_selectedSealBytes != null) {
        setUploadingSeal(true);
        final fileName = _selectedSealName ??
            'branch_seal_${DateTime.now().millisecondsSinceEpoch}.png';
        finalSealUrl = await upload(
          bytes: _selectedSealBytes!,
          fileName: fileName,
        );
      }
    } finally {
      _isUploadingLogo = false;
      _isUploadingIsoLogo = false;
      _isUploadingSeal = false;
    }

    return (
      logoUrl: finalLogoUrl,
      isoLogoUrl: finalIsoLogoUrl,
      sealUrl: finalSealUrl,
    );
  }

  BranchBioanalyst? _buildBioanalyst(String? finalSealUrl) {
    final bioName = bioanalystNameController.text.trim();
    final bioTitle = bioanalystTitleController.text.trim();
    final bioCode = bioanalystCodeController.text.trim();

    if (bioName.isNotEmpty ||
        bioTitle.isNotEmpty ||
        bioCode.isNotEmpty ||
        (finalSealUrl != null && finalSealUrl.isNotEmpty)) {
      return BranchBioanalyst(
        name: bioName,
        title: bioTitle,
        code: bioCode,
        sealUrl: finalSealUrl,
      );
    }
    return null;
  }

  /// Sube las imágenes pendientes si existen y construye el DTO inmutable [CreateBranch].
  Future<CreateBranch> generateCreateDto({
    ImageUploadFunction? uploader,
  }) async {
    final images = await _resolveImages(uploader: uploader);
    final emailText = emailController.text.trim();
    final facebookText = facebookController.text.trim();

    return CreateBranch(
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailText.isNotEmpty ? emailText : null,
      facebook: facebookText.isNotEmpty ? facebookText : null,
      logoUrl: images.logoUrl,
      imageUrl: images.logoUrl,
      isoLogoUrl: images.isoLogoUrl,
      bioanalyst: _buildBioanalyst(images.sealUrl),
      auxBio: _auxBioList.isNotEmpty ? List<AuxBioanalyst>.from(_auxBioList) : null,
      autoCalculateFormulas: _autoCalculateFormulas,
    );
  }

  /// Sube las imágenes pendientes si existen y construye el DTO inmutable [UpdateBranch].
  Future<UpdateBranch> generateUpdateDto({
    ImageUploadFunction? uploader,
  }) async {
    final images = await _resolveImages(uploader: uploader);
    final emailText = emailController.text.trim();
    final facebookText = facebookController.text.trim();

    return UpdateBranch(
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailText.isNotEmpty ? emailText : null,
      facebook: facebookText.isNotEmpty ? facebookText : null,
      logoUrl: images.logoUrl,
      imageUrl: images.logoUrl,
      isoLogoUrl: images.isoLogoUrl,
      bioanalyst: _buildBioanalyst(images.sealUrl),
      auxBio: _auxBioList,
      autoCalculateFormulas: _autoCalculateFormulas,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    emailController.dispose();
    facebookController.dispose();
    bioanalystNameController.dispose();
    bioanalystTitleController.dispose();
    bioanalystCodeController.dispose();
    super.dispose();
  }
}
