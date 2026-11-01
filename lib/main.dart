import 'package:flutter/material.dart';

import 'handwriting_screen.dart';
import 'lexgo_colors.dart';

void main() {
  runApp(const LexGoApp());
}

class LexGoApp extends StatelessWidget {
  const LexGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexGo!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: indigo),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                  const _SideNavigation(),
                  Expanded(child: _DashboardContent(isTablet: true)),
                ],
              );
            }

            return _DashboardContent(isTablet: isTablet);
          },
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(22, 28, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(),
          const SizedBox(height: 42),
          const Text('WORKSPACE', style: _SectionLabelStyle()),
          const SizedBox(height: 12),
          _NavigationItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: true,
          ),
          _NavigationItem(icon: Icons.edit_note_rounded, label: 'My writing'),
          _NavigationItem(
            icon: Icons.trending_up_rounded,
            label: 'My progress',
          ),
          _NavigationItem(icon: Icons.assessment_outlined, label: 'Reports'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: indigo),
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

  const _DashboardContent({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isTablet ? 40.0 : 20.0;

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
              isTablet ? 36 : 20,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your writing space',
                                style: TextStyle(color: muted, fontSize: 14),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'Hello, learner! 👋',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'What would you like to work on today?',
                                style: TextStyle(color: muted, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        if (isTablet) const _ProfileButton(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _WelcomeCard(isTablet: isTablet),
                    const SizedBox(height: 30),
                    const _SectionHeading(
                      title: 'Get started',
                      subtitle: 'Choose a tool for your next step',
                    ),
                    const SizedBox(height: 16),
                    _ActionGrid(isTablet: isTablet),
                    const SizedBox(height: 30),
                    _OverviewSection(isTablet: isTablet),
                    const SizedBox(height: 28),
                    const _RecentWorkCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isTablet) const _BottomNavigation(),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final bool isTablet;
  const _WelcomeCard({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 30 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [indigo, Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            'YOUR NEXT STEP',
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
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Start a handwriting session with your finger or stylus.',
          style: TextStyle(color: Color(0xFFE8E9FF), height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _openHandwriting(context),
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
    return Container(
      height: compact ? 94 : 154,
      width: compact ? double.infinity : 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            top: 20,
            child: _dot(8, const Color(0xFFFFD46E)),
          ),
          Positioned(
            right: 30,
            top: 28,
            child: _dot(12, const Color(0xFFFFA8D2)),
          ),
          Positioned(
            right: 50,
            bottom: 20,
            child: _dot(7, const Color(0xFFB8F0E1)),
          ),
          const Icon(Icons.draw_rounded, color: Colors.white, size: 64),
          Positioned(
            right: 24,
            top: 28,
            child: Transform.rotate(
              angle: -0.35,
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFD46E),
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ActionGrid extends StatelessWidget {
  final bool isTablet;
  const _ActionGrid({required this.isTablet});

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
              onTap: () => _openHandwriting(context),
            ),
            _ActionCard(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Upload an image',
              description: 'Bring in a handwriting sample',
              accent: pink,
              onTap: () => _showComingSoon(context, 'Image upload'),
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
          title: 'Your workspace',
          subtitle: 'Tools and records in one place',
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

class _RecentWorkCard extends StatelessWidget {
  const _RecentWorkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFF1F2FF),
            child: Icon(Icons.history_rounded, color: indigo),
          ),
          SizedBox(width: 14),
          Expanded(
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
                  'Your saved writing and reports will appear here.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      child: Row(
        children: [
          _IconTile(icon: icon, color: accent, size: 48),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconTile(icon: icon, color: color, size: 42),
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

class _ClickableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ClickableCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF3)),
          ),
          child: child,
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
      child: Icon(icon, color: color, size: 23),
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
        Icon(Icons.auto_stories_rounded, color: indigo, size: 27),
        SizedBox(width: 9),
        Text(
          'LexGo!',
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
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
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFF1F2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showComingSoon(context, label),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
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
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Home',
            selected: true,
          ),
          _BottomNavItem(icon: Icons.edit_note_rounded, label: 'Writing'),
          _BottomNavItem(icon: Icons.trending_up_rounded, label: 'Progress'),
          _BottomNavItem(icon: Icons.assessment_outlined, label: 'Reports'),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showComingSoon(context, label),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: selected ? indigo : muted),
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

void _openHandwriting(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const HandwritingScreen()));
}
