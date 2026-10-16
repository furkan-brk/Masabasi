import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../controller/auth_controller.dart';
import '../view/screen/admin/admin_screen.dart';
import '../view/screen/auth/login_screen.dart';
import '../view/screen/favorites/favorites_screen.dart';
import '../view/screen/gamemaster/gamemaster_screen.dart';
import '../view/screen/library/game_detail_screen.dart';
import '../view/screen/library/library_screen.dart';
import '../view/screen/notifications/notifications_screen.dart';
import '../view/screen/tables/new_table_screen.dart';
import '../view/screen/tables/table_detail_screen.dart';
import '../view/screen/tables/tables_screen.dart';
import '../view/screen/about/about_screen.dart';
import '../view/screen/profile/profile_settings_screen.dart';
import '../view/screen/votes/vote_screen.dart';
import 'theme.dart';

/// Nav destinations shared by the top bar and side nav.
class NavItem {
  const NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const List<NavItem> kTopNav = [
  NavItem('Kütüphane', Icons.menu_book, '/library'),
  NavItem('Oylamalar', Icons.how_to_vote, '/votes'),
  NavItem('Kulüp', Icons.groups, '/tables'), // masalar listesi Kulüp sekmesinde
  NavItem('Hakkımızda', Icons.info_outline, '/about'),
];

const List<NavItem> kSideNav = [
  // "Oyun Filtreleri" (/library yinelemesi) ve "Gelecek Oturumlar" (/tables → Kulüp'e taşındı) kaldırıldı.
  NavItem('AI Oyun Ustası', Icons.smart_toy, '/gamemaster'),
  NavItem('Favoriler', Icons.bookmark, '/favorites'),
];


AuthController get _auth => Get.find<AuthController>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/library',
  redirect: (context, state) {
    final loggedIn = _auth.isLoggedIn;
    final onLogin = state.uri.path == '/auth/login';
    if (!loggedIn && !onLogin) return '/auth/login';
    if (loggedIn && onLogin) return '/library';
    // Admin guard for /admin/* routes
    if (state.uri.path.startsWith('/admin') && !_auth.isAdmin) return '/library';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/library'),
    GoRoute(
      path: '/auth/login',
      builder: (_, __) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
        GoRoute(
          path: '/library/:id',
          builder: (context, state) =>
              GameDetailScreen(gameId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/tables', builder: (_, __) => const TablesScreen()),
        GoRoute(
          path: '/tables/new',
          builder: (_, __) => const NewTableScreen(),
        ),
        GoRoute(
          path: '/tables/:id',
          builder: (context, state) =>
              TableDetailScreen(tableId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/votes', builder: (_, __) => const VoteScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/gamemaster',
          builder: (_, __) => const GamemasterScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/about',
          builder: (_, __) => const AboutScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const ProfileSettingsScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminScreen(),
        ),
      ],
    ),
  ],
);

/// Scholar's Table app shell: fixed parchment top bar + side nav on desktop,
/// drawer on mobile.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: isDesktop ? null : _MobileDrawer(location: location),
      body: Column(
        children: [
          _TopNavBar(isDesktop: isDesktop, location: location),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _SideNav(location: location),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.surface,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({required this.isDesktop, required this.location});

  final bool isDesktop;
  final String location;

  bool _isActive(String route) => location.startsWith(route);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.topNavHeight,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x08800000), blurRadius: 15, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              children: [
                if (!isDesktop)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.primaryContainer),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                _brand(),
                if (isDesktop) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _desktopNav(context)),
                ] else
                  const Spacer(),
                _actions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.casino, color: AppColors.onPrimary, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Masabaşı Oyun Kulübü',
            style: AppText.headlineMd.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryContainer,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _desktopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (final item in kTopNav)
          _TopNavLink(
            item: item,
            active: _isActive(item.route),
            onTap: () => context.go(item.route),
          ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant),
              onPressed: () => context.go('/notifications'),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(width: 1, height: 24, color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(width: AppSpacing.sm),
        _ProfilePill(),
      ],
    );
  }
}

class _TopNavLink extends StatefulWidget {
  const _TopNavLink({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TopNavLink> createState() => _TopNavLinkState();
}

class _TopNavLinkState extends State<_TopNavLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final highlight = active || _hovering;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: AppSpacing.topNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: highlight
                    ? AppColors.primaryContainer.withValues(alpha: active ? 1 : 0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.item.label,
            style: AppText.bodyMd.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePill extends StatefulWidget {
  @override
  State<_ProfilePill> createState() => _ProfilePillState();
}

class _ProfilePillState extends State<_ProfilePill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthController>();
      final name = auth.currentUser.value?.name ?? 'Profil';

      return PopupMenuButton<String>(
        offset: const Offset(0, 44),
        color: AppColors.surface,
        elevation: 4,
        tooltip: '',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        onSelected: (value) async {
          if (value == 'settings') {
            context.go('/settings');
          } else if (value == 'admin') {
            context.go('/admin');
          } else if (value == 'logout') {
            await Get.find<AuthController>().logout();
            if (context.mounted) context.go('/auth/login');
          }
        },
        itemBuilder: (ctx) {
          final isAdmin = Get.find<AuthController>().isAdmin;
          return [
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(children: [
                const Icon(Icons.settings_outlined, size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Ayarlar', style: AppText.bodyMd.copyWith(color: AppColors.onSurface)),
              ]),
            ),
            if (isAdmin)
              PopupMenuItem<String>(
                value: 'admin',
                child: Row(children: [
                  const Icon(Icons.admin_panel_settings, size: 18, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Admin Paneli',
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Çıkış Yap', style: AppText.bodyMd.copyWith(color: AppColors.error)),
              ]),
            ),
          ];
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(left: 6, right: 12, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: _hovering ? AppColors.surfaceContainerHigh : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: _hovering
                    ? AppColors.primaryContainer.withValues(alpha: 0.4)
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hovering ? AppColors.primaryContainer : AppColors.surfaceContainer,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: _hovering ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: AppText.labelMd.copyWith(
                    color: _hovering ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.navWidth,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: _SideNavHeader(),
          ),
          for (final item in kSideNav)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _SideNavItem(
                item: item,
                active: location.startsWith(item.route),
                onTap: () => context.go(item.route),
              ),
            ),
          const Spacer(),
          _SideNavItem(
            item: const NavItem('Ayarlar', Icons.settings, '/settings'),
            active: location.startsWith('/settings'),
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(height: AppSpacing.md),
          _newTableButton(context),
        ],
      ),
    );
  }

  Widget _newTableButton(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go('/tables/new'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 18, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Yeni Masa Kur',
                style: AppText.labelMd.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavHeader extends StatelessWidget {
  const _SideNavHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Oyun Odası', style: AppText.headlineMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(
          'Kitaplık ve Danışman',
          style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatefulWidget {
  const _SideNavItem({required this.item, required this.active, required this.onTap});

  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final Color bg = active
        ? AppColors.primaryContainer.withValues(alpha: 0.12)
        : _hovering
            ? AppColors.surfaceContainerHigh
            : Colors.transparent;
    final Color fg = active ? AppColors.primaryContainer : AppColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(active ? 4 : 0, 0, 0),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(widget.item.icon, size: 22, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.item.label,
                    style: AppText.labelMd.copyWith(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Bordo sol aksan çizgisi — yalnızca aktif öğede gösterilir.
            Positioned(
              left: 0,
              top: 4,
              bottom: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 3,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: _SideNavHeader(),
              ),
              for (final item in [...kTopNav, ...kSideNav])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _SideNavItem(
                    item: item,
                    active: location.startsWith(item.route),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(item.route);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

