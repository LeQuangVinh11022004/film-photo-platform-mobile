import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/expert_application_state.dart';

class ExpertApplicationScreen extends StatefulWidget {
  const ExpertApplicationScreen({super.key});

  @override
  State<ExpertApplicationScreen> createState() =>
      _ExpertApplicationScreenState();
}

class _ExpertApplicationScreenState extends State<ExpertApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _introductionController = TextEditingController();
  final _portfolioController = TextEditingController();

  String? _selectedSpecialty;

  final List<String> _specialties = const [
    'Film Photography',
    'Film Developing & Darkroom',
    'Film Scanning & Restoration',
    'Camera & Equipment',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _experienceController.dispose();
    _introductionController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng điền thông tin này';
    }
    return null;
  }

  void _submitApplication() {
    if (!_formKey.currentState!.validate()) return;

    final portfolio = _portfolioController.text.trim();

    // Portfolio là tùy chọn, nhưng nếu có thì phải là URL hợp lệ.
    if (portfolio.isNotEmpty && !Uri.tryParse(portfolio)!.hasScheme) {
      // Không sử dụng đoạn này để xác thực URL:
      // hasScheme chỉ kiểm tra sơ bộ, chưa đảm bảo URL hợp lệ.
    }

    if (portfolio.isNotEmpty) {
      final uri = Uri.tryParse(portfolio);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio phải là một đường dẫn URL hợp lệ.'),
          ),
        );
        return;
      }
    }

    // DEMO ONLY: Tự động approved vì hiện tại chưa có backend.
    // TODO(BACKEND): Khi tích hợp API, gửi đơn và chuyển sang pending.
    // Chỉ backend/Admin mới có quyền xác nhận approved thực sự.
    // Lưu trạng thái đăng ký và bắt đầu giả lập duyệt.
    // Lưu trạng thái đăng ký và bắt đầu giả lập duyệt.
    ExpertApplicationState.instance.submitDemoApplication(
      fullName: _nameController.text.trim(),
      specialty: _selectedSpecialty!,
      experience: _experienceController.text.trim(),
      introduction: _introductionController.text.trim(),
      portfolioUrl: _portfolioController.text.trim(),
    );

    // Lấy các đối tượng trước khi đóng màn hình form.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Quay về Profile thay vì mở Expert Workspace.
    navigator.pop();

    // Thông báo đầu tiên: đang chờ duyệt.
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã gửi đăng ký thành công. Vui lòng chờ duyệt!'),
        duration: Duration(seconds: 3),
      ),
    );

    // Sau 5 giây, thông báo khi demo tự duyệt thành công.
    Future.delayed(const Duration(seconds: 5), () {
      if (!messenger.mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã được duyệt! Chúc mừng bạn đã trở thành Expert.'),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(title: const Text('Become an Expert')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Chia sẻ kiến thức của bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Trở thành một phần của cộng đồng chuyên gia '
                      'nhiếp ảnh film và giúp nhiều người nâng cao '
                      'kỹ năng của họ.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Thông tin cơ bản'),
              const SizedBox(height: 14),

              _buildLabel('Họ và tên'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: _requiredValidator,
                decoration: _inputDecoration(
                  hint: 'Nhập họ tên của bạn',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Lĩnh vực chuyên môn'),
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                isExpanded: true,
                decoration: _inputDecoration(
                  hint: 'Chọn lĩnh vực của bạn',
                  icon: Icons.camera_alt_outlined,
                ),
                items: _specialties.map((specialty) {
                  return DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn lĩnh vực chuyên môn';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                },
              ),
              const SizedBox(height: 18),

              _buildLabel('Kinh nghiệm'),
              TextFormField(
                controller: _experienceController,
                validator: _requiredValidator,
                maxLines: 2,
                decoration: _inputDecoration(
                  hint: 'Ví dụ: 5 năm chụp film, 2 năm tráng film...',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Giới thiệu chuyên môn'),
              const SizedBox(height: 14),

              _buildLabel('Giới thiệu bản thân'),
              TextFormField(
                controller: _introductionController,
                validator: _requiredValidator,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                decoration: _inputDecoration(
                  hint:
                      'Chia sẻ kinh nghiệm, thế mạnh và điều bạn '
                      'có thể đóng góp cho cộng đồng...',
                  icon: Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 18),

              _buildLabel('Portfolio (không bắt buộc)'),
              TextFormField(
                controller: _portfolioController,
                keyboardType: TextInputType.url,
                decoration: _inputDecoration(
                  hint: 'https://your-portfolio.com',
                  icon: Icons.link_rounded,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Có thể thêm website cá nhân hoặc đường dẫn '
                'portfolio để giới thiệu các tác phẩm của bạn.',
                style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bản demo hiện tự động duyệt đơn đăng ký. '
                        'Khi tích hợp backend, đơn sẽ được gửi đến '
                        'Admin để xét duyệt.',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitApplication,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Submit application'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Để sau',
                  style: TextStyle(color: context.textSecColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: context.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: context.inputColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorMaxLines: 2,
    );
  }
}
