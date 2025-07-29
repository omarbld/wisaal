import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface, // A slightly different background
      appBar: AppBar(
        title: const Text('الشروط والأحكام'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('مرحباً بك في وصال', textTheme),
              const SizedBox(height: 8),
              Text(
                'يرجى قراءة الشروط التالية بعناية قبل استخدام التطبيق.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              _buildSectionCard(
                theme,
                icon: Icons.handshake_outlined,
                title: 'قبول الشروط',
                content:
                    'باستخدام منصة وصال، فإنك توافق على جميع الشروط والأحكام المذكورة',
              ),
              _buildSectionCard(
                theme,
                icon: Icons.assignment_late_outlined,
                title: 'المسؤوليات',
                content: 'كل طرف له مسؤوليات محددة يجب الالتزام بها',
              ),
              _buildSectionCard(
                theme,
                icon: Icons.security_outlined,
                title: 'الأمان والحماية',
                content: 'نلتزم بحماية جميع المستخدمين وضمان بيئة آمنة',
              ),
              _buildSectionCard(
                theme,
                icon: Icons.gavel_outlined,
                title: 'القوانين المعمول بها',
                content: 'تخضع هذه الشروط للقوانين المغربية',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('تفاصيل الشروط', textTheme),
              const SizedBox(height: 16),
              _buildExpansionTile(
                theme,
                title: '1. الشروط العامة',
                children: [
                  _buildBodyText(
                      'منصة وصال هي خدمة مجانية تهدف إلى ربط المتبرعين بالجمعي��ت الخيرية والمتطوعين',
                      theme),
                  _buildBodyText(
                      'وصال لا تتدخل في عملية التبرع نفسها، بل تعمل كوسيط تقني لتسهيل التواصل',
                      theme),
                  _buildBodyText(
                      'يجب أن يكون عمر المستخدم 18 سنة أو أكثر، أو بموافقة ولي الأمر',
                      theme),
                  _buildBodyText(
                      'جميع المعلومات المقدمة يجب أن تكون صحيحة ومحدثة',
                      theme),
                ],
              ),
              _buildExpansionTile(
                theme,
                title: '2. مسؤوليات المستخدمين',
                children: [
                  _buildSubTitle('المتبرعون', theme),
                  _buildBulletPoint(
                      'ضمان جودة وسلامة الطعام المتبرع به', theme),
                  _buildBulletPoint('تقديم معلومات صحيحة عن التبرع', theme),
                  _buildBulletPoint('الالتزام بمواعيد التسليم المحددة', theme),
                  _buildBulletPoint('احترام شروط التخزين والنقل', theme),
                  const SizedBox(height: 16),
                  _buildSubTitle('الجمعيات الخيرية', theme),
                  _buildBulletPoint('التحقق من صلاحية الطعام المستلم', theme),
                  _buildBulletPoint('توزيع التبرعات على المستحقين', theme),
                  _buildBulletPoint('تقديم تقارير دورية عن الأنشطة', theme),
                  _buildBulletPoint('الحفاظ على سرية بيانات المستفيدين', theme),
                ],
              ),
              _buildExpansionTile(
                theme,
                title: '3. قواعد استخدام المنصة',
                children: [
                  _buildSubTitle('المسموح', theme),
                  _buildBulletPoint(
                      'تقديم تبرعات غذائية صالحة للاستهلاك', theme),
                  _buildBulletPoint('التواصل المهذب مع جميع المستخدمين', theme),
                  _buildBulletPoint('مشاركة تجاربك الإيجابية', theme),
                  const SizedBox(height: 16),
                  _buildSubTitle('الممنوع', theme),
                  _buildBulletPoint('تقديم طعام منتهي الصلاحية أو فاسد', theme),
                  _buildBulletPoint('استخدام المنصة لأغراض تجارية', theme),
                  _buildBulletPoint('التحرش أو الإساءة لأي مستخدم', theme),
                ],
              ),
              _buildExpansionTile(
                theme,
                title: '4. المسؤولية القانونية',
                children: [
                  _buildSubTitle('إخلاء المسؤولية', theme),
                  _buildBodyText(
                      'منصة وصال تعمل كوسيط تقني فقط. نحن غير مسؤولين عن جودة الطعام، سلامة التوصيل، أو أي أضرار قد تنتج عن استخدام الخدمة.',
                      theme),
                ],
              ),
              _buildExpansionTile(
                theme,
                title: '5. إنهاء الخدمة',
                children: [
                  _buildBodyText(
                      'نحتفظ بالحق في إيقاف أو إنهاء حساب أي مستخدم في حالة انتهاك هذه الشروط.',
                      theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text, TextTheme textTheme) {
    return Center(
      child: Text(
        text,
        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme,
      {required IconData icon,
      required String title,
      required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildExpansionTile(ThemeData theme,
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(16.0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSubTitle(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildBodyText(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge
            ?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildBulletPoint(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
