import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/add_lock_viewmodel.dart';

class AddLockStep2View extends StatelessWidget {
  const AddLockStep2View({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo ViewModel
    final viewModel = Get.put(AddLockViewModel());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        scrolledUnderElevation: 0,
        surfaceTintColor: theme.colorScheme.surface,
        title: Text(
          'Thêm Khóa Mới',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: pagePadding,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeaderCard(context),
                      const SizedBox(height: 20),
                      _buildFormCard(context, viewModel),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0C1425), const Color(0xFF0F1B30)]
              : [const Color(0xFFF4F7FF), const Color(0xFFF8FBF7)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF1C2B52) : const Color(0xFFDCE8FF),
              190,
            ),
          ),
          Positioned(
            bottom: -110,
            left: -90,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF112138) : const Color(0xFFDFF4E6),
              240,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.6), color.withOpacity(0.05)],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withOpacity(0.4),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(context, currentStep: 2, totalSteps: 3),
          const SizedBox(height: 16),
          Text(
            'Cấu hình WiFi qua Bluetooth',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ứng dụng sẽ gửi thông tin WiFi xuống khóa bằng BLE.',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context, {
    required int currentStep,
    required int totalSteps,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.outlineVariant;

    Widget dot(int step) {
      final isCompleted = step < currentStep;
      final isActive = step == currentStep;

      if (isCompleted) {
        return CircleAvatar(
          radius: 14,
          backgroundColor: activeColor,
          child: Icon(
            Icons.check,
            color: theme.colorScheme.onPrimary,
            size: 16,
          ),
        );
      }

      return CircleAvatar(
        radius: isActive ? 15 : 14,
        backgroundColor: isActive
            ? activeColor
            : theme.colorScheme.surfaceVariant,
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.outline,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget line(bool active) {
      return Container(
        width: 36,
        height: 2,
        color: active ? activeColor : inactiveColor,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        dot(1),
        line(currentStep > 1),
        dot(2),
        line(currentStep > 2),
        dot(3),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, AddLockViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TÊN KHÓA (TÙY CHỌN)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.deviceNameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              context,
              hintText: 'Khóa cửa chính',
              icon: Icons.lock_outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TÊN WIFI NHÀ BẠN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.ssidController,
            decoration: _inputDecoration(
              context,
              hintText: 'Tên WiFi',
              icon: Icons.wifi,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'MẬT KHẨU WIFI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextField(
              controller: viewModel.passwordController,
              obscureText: !viewModel.isPasswordVisible.value,
              decoration: _inputDecoration(
                context,
                hintText: 'Nhập mật khẩu',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: viewModel.togglePasswordVisibility,
                  icon: Icon(
                    viewModel.isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  tooltip: viewModel.isPasswordVisible.value
                      ? 'Ẩn mật khẩu'
                      : 'Hiện mật khẩu',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'ID NGƯỜI DÙNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextField(
              readOnly: true,
              controller: TextEditingController(text: viewModel.ownerId.value),
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
              decoration: _inputDecoration(
                context,
                hintText: '',
                icon: Icons.fingerprint,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '* ID này được tự động gán cho thiết bị mới.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 24),

          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  viewModel.isSending.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : CircleAvatar(
                          radius: 6,
                          backgroundColor: theme.colorScheme.primary,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      viewModel.connectionStatus.value,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: viewModel.isSending.value
                    ? null
                    : () => viewModel.sendConfigToLock(),
                child: viewModel.isSending.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gửi cấu hình',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send, size: 18, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
