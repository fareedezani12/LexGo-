import 'package:flutter/material.dart';

import 'handwriting_screen.dart';
import 'lexgo_colors.dart';
import 'models/handwriting_sample.dart';
import 'my_writing_screen.dart';
import 'upload_image_screen.dart';
import 'services/handwriting_api_service.dart';
import 'services/handwriting_sample_store.dart';

final HandwritingSampleStore _defaultRepository = HandwritingApiService();

void main() {
  runApp(const LexGoApp());
}

class LexGoApp extends StatelessWidget {
  final HandwritingSampleStore? repository;

  const LexGoApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexGo!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: indigo).copyWith(
          primary: indigo,
          secondary: pink,
          tertiary: amber,
          surface: surface,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBackground,
          surfaceTintColor: pageBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: ink,
          iconTheme: IconThemeData(color: ink),
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: indigo,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            side: const BorderSide(color: Color(0xFFDCDDFA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFBFF),
          labelStyle: const TextStyle(color: muted),
          hintStyle: const TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: indigo, width: 1.7),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: indigo,
          linearTrackColor: Color(0xFFDADCFB),
        ),
      ),
      home: DashboardScreen(repository: repository),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final HandwritingSampleStore? repository;

  const DashboardScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            final isTablet = constraints.maxWidth >= 680;

            if (isWide) {
              return Row(
                children: [
                  _SideNavigation(repository: repository),
                  Expanded(
                    child: _DashboardContent(
                      isTablet: true,
                      repository: repository,
                    ),
                  ),
                ],
              );
            }

            return _DashboardContent(
              isTablet: isTablet,
              repository: repository,
            );
          },
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  final HandwritingSampleStore? repository;

  const _SideNavigation({required this.repository});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      padding: const EdgeInsets.fromLTRB(20, 26, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: _Brand(),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF1F2FF), Color(0xFFF4FAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6E8FF)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: 2,
                  top: 0,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0x556366F1),
                    size: 18,
                  ),
                ),
                const Row(
                  children: [
                    _IconTile(
                      icon: Icons.auto_awesome_rounded,
                      color: indigo,
                      size: 42,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learner space',
                            style: TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Practice at your pace',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text('WORKSPACE', style: _SectionLabelStyle()),
          ),
          const SizedBox(height: 10),
          _NavigationItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: true,
          ),
          _NavigationItem(
            icon: Icons.edit_note_rounded,
            label: 'My writing',
            onTap: () => _openMyWriting(context, repository),
          ),
          _NavigationItem(
            icon: Icons.trending_up_rounded,
            label: 'My progress',
          ),
          _NavigationItem(icon: Icons.assessment_outlined, label: 'Reports'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: amber),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Small steps make progress.',
                    style: TextStyle(color: ink, fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final bool isTablet;
  final HandwritingSampleStore? repository;

  const _DashboardContent({required this.isTablet, required this.repository});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isTablet ? 44.0 : 20.0;

    return Column(
      children: [
        if (!isTablet)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              8,
            ),
            child: const Row(children: [_Brand(), Spacer(), _ProfileButton()]),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              isTablet ? 32 : 18,
              horizontalPadding,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR WRITING SPACE',
                                style: TextStyle(
                                  color: indigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'Hello, learner!',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: isTablet ? 32 : 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'What would you like to work on today?',
                              style: TextStyle(color: muted, fontSize: 15, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        if (isTablet) const _ProfileButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _WelcomeCard(
                      isTablet: isTablet,
                      repository: repository ?? _defaultRepository,
                    ),
                    const SizedBox(height: 30),
                    const _SectionHeading(
                      title: 'Get started',
                      subtitle: 'Choose a tool for your next step',
                    ),
                    const SizedBox(height: 16),
                    _ActionGrid(
                      isTablet: isTablet,
                      repository: repository ?? _defaultRepository,
                    ),
                    const SizedBox(height: 30),
                    _OverviewSection(isTablet: isTablet),
                    const SizedBox(height: 28),
                    _RecentWorkCard(
                      repository: repository ?? _defaultRepository,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isTablet)
          _BottomNavigation(repository: repository ?? _defaultRepository),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final bool isTablet;
  final HandwritingSampleStore repository;

  const _WelcomeCard({required this.isTablet, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 30 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5558E8), Color(0xFF8588F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x256366F1),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: isTablet
          ? Row(
              children: [
                Expanded(child: _welcomeCopy(context)),
                const SizedBox(width: 24),
                const _WritingIllustration(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeCopy(context),
                const SizedBox(height: 20),
                const _WritingIllustration(compact: true),
              ],
            ),
    );
  }

  Widget _welcomeCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
          'A LITTLE PRACTICE GOES A LONG WAY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Make room for\nyour ideas.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'A calm place to practise, build confidence, and share your progress.',
          style: TextStyle(color: Color(0xFFE8E9FF), height: 1.55, fontSize: 14),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _openHandwriting(context, repository),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: indigo,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          icon: const Icon(Icons.draw_rounded),
          label: const Text('Start writing'),
        ),
      ],
    );
  }
}

class _WritingIllustration extends StatelessWidget {
  final bool compact;
  const _WritingIllustration({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final paperScale = compact ? 0.72 : 1.0;
    return Container(
      height: compact ? 112 : 176,
      width: compact ? double.infinity : 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 26,
            top: 20,
            child: _shape(26, const Color(0xFFB9B7FF)),
          ),
          Positioned(
            right: 35,
            top: 18,
            child: _shape(18, const Color(0xFFF9A8D4)),
          ),
          Positioned(
            right: 27,
            bottom: 20,
            child: _shape(28, const Color(0xFFFCD58A)),
          ),
          Container(
            width: 104 * paperScale,
            height: 128 * paperScale,
            padding: EdgeInsets.fromLTRB(
              15 * paperScale,
              18 * paperScale,
              15 * paperScale,
              14 * paperScale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332A2C7A),
                  blurRadius: 18,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34 * paperScale,
                  height: 6 * paperScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD46E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                SizedBox(height: 13 * paperScale),
                for (final width in [72.0, 61.0, 70.0, 49.0]) ...[
                  Container(
                    width: width * paperScale,
                    height: 3 * paperScale,
                    margin: EdgeInsets.only(bottom: 9 * paperScale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE3EF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    size: 20 * paperScale,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: compact ? null : 68,
            right: compact ? 74 : null,
            bottom: 15,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: 21,
                height: 89,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9A92F)),
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: Color(0xFF8A5B20),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 27,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFD46E),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _shape(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ActionGrid extends StatelessWidget {
  final bool isTablet;
  final HandwritingSampleStore repository;

  const _ActionGrid({required this.isTablet, required this.repository});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : (constraints.maxWidth >= 520 ? 2 : 1);
        final ratio = columns == 1 ? 3.2 : 1.55;
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionCard(
              icon: Icons.edit_rounded,
              title: 'Handwriting',
              description: 'Write with your finger or stylus',
              accent: indigo,
              onTap: () => _openHandwriting(context, repository),
            ),
            _ActionCard(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Upload an image',
              description: 'Bring in a handwriting sample',
              accent: pink,
              onTap: () => _openImageUpload(context, repository),
            ),
            _ActionCard(
              icon: Icons.spellcheck_rounded,
              title: 'Text correction',
              description: 'Review and improve recognised text',
              accent: amber,
              onTap: () => _showComingSoon(context, 'Text correction'),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final bool isTablet;
  const _OverviewSection({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Overview',
          subtitle: 'More ways to practise and track your learning',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth < 420 ? 1.15 : 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MiniCard(
                  icon: Icons.psychology_alt_outlined,
                  title: 'Handwriting analysis',
                  caption: 'Dyslexia related indicators',
                  color: amber,
                  onTap: () => _showComingSoon(context, 'Handwriting analysis'),
                ),
                _MiniCard(
                  icon: Icons.insights_rounded,
                  title: 'My progress',
                  caption: 'Follow your practice over time',
                  color: indigo,
                  onTap: () => _showComingSoon(context, 'Progress'),
                ),
                _MiniCard(
                  icon: Icons.description_outlined,
                  title: 'Reports',
                  caption: 'Review saved reports',
                  color: pink,
                  onTap: () => _showComingSoon(context, 'Reports'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecentWorkCard extends StatefulWidget {
  final HandwritingSampleStore repository;

  const _RecentWorkCard({required this.repository});

  @override
  State<_RecentWorkCard> createState() => _RecentWorkCardState();
}

class _RecentWorkCardState extends State<_RecentWorkCard> {
  late Future<List<HandwritingSample>> _samplesFuture;

  @override
  void initState() {
    super.initState();
    _samplesFuture = widget.repository.loadSamples();
  }

  void _retry() {
    setState(() => _samplesFuture = widget.repository.loadSamples());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081E293B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.history_rounded,
                color: indigo,
                size: 48,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent work',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your latest handwriting practice',
                      style: TextStyle(color: muted, fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<HandwritingSample>>(
            future: _samplesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _loadError();
              if (!snapshot.hasData) return _loadingState();
              final samples = snapshot.data!;
              if (samples.isEmpty) return _emptyState();
              return _sampleList(samples);
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openMyWriting(context, widget.repository),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('My writing'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _IconTile(icon: Icons.edit_note_rounded, color: indigo, size: 42),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Finding your latest writing…',
              style: TextStyle(color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 500;
          final illustration = Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF0FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: indigo,
              size: 30,
            ),
          );
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your first page starts here',
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Try a short writing session. Your saved work will show up here.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    _openHandwriting(context, widget.repository),
                icon: const Icon(Icons.draw_rounded, size: 18),
                label: const Text('Start writing'),
                style: TextButton.styleFrom(
                  foregroundColor: indigo,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          );

          if (!horizontal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [illustration, const SizedBox(height: 14), copy],
            );
          }
          return Row(
            children: [
              illustration,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }

  Widget _loadError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: amber),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recent writing is unavailable right now.',
              style: TextStyle(color: ink, fontSize: 13),
            ),
          ),
          TextButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _sampleList(List<HandwritingSample> samples) {
    final recentSamples = samples.take(3).toList();
    return Column(
      children: [
        for (var index = 0; index < recentSamples.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          Material(
            color: const Color(0xFFFAFAFF),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _openMyWriting(context, widget.repository),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const _IconTile(
                      icon: Icons.edit_note_rounded,
                      color: indigo,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recentSamples[index].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSampleDate(recentSamples[index].createdAt),
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${samples.length} saved',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

String _formatSampleDate(DateTime date) {
  final localDate = date.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ClickableCard(
      onTap: onTap,
      surfaceColor: accent.withValues(alpha: 0.055),
      borderColor: accent.withValues(alpha: 0.18),
      child: Row(
        children: [
          _IconTile(icon: icon, color: accent, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: muted),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ClickableCard(
      onTap: onTap,
      surfaceColor: color.withValues(alpha: 0.045),
      borderColor: color.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconTile(icon: icon, color: color, size: 48),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClickableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;

  const _ClickableCard({
    required this.child,
    required this.onTap,
    this.surfaceColor = Colors.white,
    this.borderColor = const Color(0xFFE8ECF3),
  });

  @override
  State<_ClickableCard> createState() => _ClickableCardState();
}

class _ClickableCardState extends State<_ClickableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.surfaceColor,
      elevation: _isHovered ? 4 : 0,
      shadowColor: indigo.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (isHovered) {
          if (_isHovered != isHovered) setState(() => _isHovered = isHovered);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? widget.borderColor.withValues(alpha: 0.85)
                  : widget.borderColor,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconTile({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE9E9FF), Color(0xFFFFEFF7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.auto_stories_rounded, color: indigo, size: 25),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LexGo!',
              style: TextStyle(
                color: ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'WRITE · LEARN · GROW',
              style: TextStyle(
                color: muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () => _showComingSoon(context, 'Profile'),
      tooltip: 'Profile',
      style: IconButton.styleFrom(backgroundColor: Colors.white),
      icon: const Icon(Icons.person_outline_rounded, color: ink),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFF1F2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap ?? () => _showComingSoon(context, label),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? indigo : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: selected ? indigo : muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? indigo : muted,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabelStyle extends TextStyle {
  const _SectionLabelStyle()
    : super(
        color: muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );
}

class _BottomNavigation extends StatelessWidget {
  final HandwritingSampleStore repository;

  const _BottomNavigation({required this.repository});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A1E293B),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                selected: true,
              ),
              _BottomNavItem(
                icon: Icons.edit_note_rounded,
                label: 'Writing',
                onTap: () => _openMyWriting(context, repository),
              ),
              _BottomNavItem(icon: Icons.trending_up_rounded, label: 'Progress'),
              _BottomNavItem(icon: Icons.assessment_outlined, label: 'Reports'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => _showComingSoon(context, label),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF1F2FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: selected ? indigo : muted),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? indigo : muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Placeholder: $feature will be available later.')),
  );
}

void _openHandwriting(BuildContext context, HandwritingSampleStore repository) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HandwritingScreen(repository: repository),
    ),
  );
}

void _openMyWriting(BuildContext context, HandwritingSampleStore? repository) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          MyWritingScreen(repository: repository ?? _defaultRepository),
    ),
  );
}

void _openImageUpload(BuildContext context, HandwritingSampleStore repository) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => UploadImageScreen(repository: repository),
    ),
  );
}
