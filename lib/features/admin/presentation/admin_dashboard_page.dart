import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../announcements/models/announcement.dart';
import '../../announcements/presentation/widgets/announcement_form_dialog.dart';
import '../../announcements/providers/announcement_provider.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/models/member_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../birthdays/models/birthday_anniversary_week.dart';
import '../../birthdays/providers/birthday_provider.dart';
import '../models/audit_log.dart';
import '../providers/admin_provider.dart';
import 'widgets/manage_birthdays_dialog.dart';
import 'widgets/member_verification_dialog.dart';

/// Navigation views for the Staff / Admin Portal.
enum AdminNavView {
  dashboard,
  members,
  audit,
}

/// Comprehensive, modern, responsive Staff/Admin Portal Dashboard for Flutter Web.
/// Used by: Admin, Committee, Pastor / Presbyter.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  AdminNavView _activeView = AdminNavView.dashboard;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _memberPage = 1;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isStaff = ref.watch(isStaffUserProvider);

    // 1. Enforce Role-Based Access: Deny non-staff members
    if (!isStaff) {
      return _buildAccessDeniedView(context, auth);
    }

    final counts = ref.watch(memberCountsProvider);
    final allMembersAsync = ref.watch(allMembersStreamProvider);
    final auditLogsAsync = ref.watch(auditLogsStreamProvider);
    final announcementsAsync = ref.watch(allAnnouncementsStreamProvider);
    final currentWeekAsync = ref.watch(weekBulletinStreamProvider);
    final activeStatusFilter = ref.watch(adminStatusFilterProvider);
    final filteredMembers = ref.watch(filteredMembersProvider);

    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundIvory,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF271512),
              child: SafeArea(
                child: _buildSidebarContent(
                  context: context,
                  auth: auth,
                  counts: counts,
                  isDrawer: true,
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Persistent Desktop Sidebar
            if (isDesktop)
              Container(
                width: 250,
                color: const Color(0xFF271512),
                child: _buildSidebarContent(
                  context: context,
                  auth: auth,
                  counts: counts,
                  isDrawer: false,
                ),
              ),

            // Main Dashboard Workspace
            Expanded(
              child: Column(
                children: [
                  // Top App Bar
                  _buildTopAppBar(context, auth, counts, isDesktop),

                  // Active View Body
                  Expanded(
                    child: switch (_activeView) {
                      AdminNavView.dashboard => _buildDashboardView(
                          context: context,
                          auth: auth,
                          counts: counts,
                          allMembersAsync: allMembersAsync,
                          announcementsAsync: announcementsAsync,
                          currentWeekAsync: currentWeekAsync,
                          auditLogsAsync: auditLogsAsync,
                        ),
                      AdminNavView.members => _buildMembersView(
                          context: context,
                          activeStatusFilter: activeStatusFilter,
                          filteredMembers: filteredMembers,
                          allMembersAsync: allMembersAsync,
                          counts: counts,
                        ),
                      AdminNavView.audit => _buildAuditView(
                          context: context,
                          auditLogsAsync: auditLogsAsync,
                        ),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // A. Sidebar Navigation (Dark Espresso)
  // ===============================================================
  Widget _buildSidebarContent({
    required BuildContext context,
    required AuthState auth,
    required Map<MemberStatus, int> counts,
    required bool isDrawer,
  }) {
    final pendingCount = counts[MemberStatus.pending] ?? 0;
    final role = (auth.profile?.role ?? 'Staff').toLowerCase();
    final isAdmin = role == 'admin';

    void closeDrawerIfOpen() {
      if (isDrawer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.mutedGold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mutedGold, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.church_rounded,
                        color: AppColors.mutedGold,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSI Church',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'Community',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedGold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.mutedGold.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                  border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.5), width: 0.8),
                ),
                child: const Text(
                  'Staff Portal',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF0D59E),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Color(0xFF452C27), height: 1),

        // Scrollable Navigation Links
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            children: [
              // 1. Dashboard
              _buildSidebarItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _activeView == AdminNavView.dashboard,
                onTap: () {
                  setState(() => _activeView = AdminNavView.dashboard);
                  closeDrawerIfOpen();
                },
              ),
              const SizedBox(height: 4),

              // 2. Members Directory
              _buildSidebarItem(
                icon: Icons.people_outline_rounded,
                label: 'Members',
                isSelected: _activeView == AdminNavView.members &&
                    ref.read(adminStatusFilterProvider) != MemberStatus.pending,
                onTap: () {
                  ref.read(adminStatusFilterProvider.notifier).setFilter(null);
                  setState(() => _activeView = AdminNavView.members);
                  closeDrawerIfOpen();
                },
              ),
              const SizedBox(height: 4),

              // 3. Member Verification (with pending counter badge)
              _buildSidebarItem(
                icon: Icons.assignment_turned_in_outlined,
                label: 'Member Verification',
                badgeCount: pendingCount,
                isSelected: _activeView == AdminNavView.members &&
                    ref.read(adminStatusFilterProvider) == MemberStatus.pending,
                onTap: () {
                  ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
                  setState(() => _activeView = AdminNavView.members);
                  closeDrawerIfOpen();
                },
              ),
              const SizedBox(height: 4),

              // 4. Announcements
              _buildSidebarItem(
                icon: Icons.campaign_outlined,
                label: 'Announcements',
                onTap: () {
                  closeDrawerIfOpen();
                  context.push('/announcements');
                },
              ),
              const SizedBox(height: 4),

              // 5. Celebrations
              _buildSidebarItem(
                icon: Icons.cake_outlined,
                label: 'Celebrations',
                onTap: () {
                  closeDrawerIfOpen();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ManageBirthdaysDialog(),
                  );
                },
              ),
              const SizedBox(height: 4),

              // Non-implemented modules (clearly communicated)
              _buildSidebarItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Community Posts',
                isPending: true,
                onTap: () => _showComingSoonSnackBar(context, 'Community Posts'),
              ),
              const SizedBox(height: 4),

              _buildSidebarItem(
                icon: Icons.calendar_today_outlined,
                label: 'Events & Calendar',
                isPending: true,
                onTap: () => _showComingSoonSnackBar(context, 'Events & Calendar'),
              ),
              const SizedBox(height: 4),

              _buildSidebarItem(
                icon: Icons.volunteer_activism_outlined,
                label: 'Prayer Requests',
                isPending: true,
                onTap: () => _showComingSoonSnackBar(context, 'Prayer Requests'),
              ),
              const SizedBox(height: 4),

              _buildSidebarItem(
                icon: Icons.description_outlined,
                label: 'Documents',
                isPending: true,
                onTap: () => _showComingSoonSnackBar(context, 'Church Documents'),
              ),
              const SizedBox(height: 4),

              _buildSidebarItem(
                icon: Icons.info_outline_rounded,
                label: 'Church Information',
                isPending: true,
                onTap: () => _showComingSoonSnackBar(context, 'Church Information'),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFF452C27), height: 1),
              ),

              // 11. Audit & Activity
              _buildSidebarItem(
                icon: Icons.access_time_rounded,
                label: 'Audit & Activity',
                isSelected: _activeView == AdminNavView.audit,
                onTap: () {
                  setState(() => _activeView = AdminNavView.audit);
                  closeDrawerIfOpen();
                },
              ),
              const SizedBox(height: 4),

              // 12. Staff & Roles (Admin Only)
              _buildSidebarItem(
                icon: Icons.manage_accounts_outlined,
                label: 'Staff & Roles',
                isRestricted: !isAdmin,
                onTap: () {
                  closeDrawerIfOpen();
                  if (!isAdmin) {
                    _showRestrictedAccessDialog(context, 'Staff & Role Management');
                  } else {
                    _showRoleManagementInfoDialog(context);
                  }
                },
              ),
              const SizedBox(height: 4),

              // 13. Settings (Admin Only)
              _buildSidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isRestricted: !isAdmin,
                onTap: () {
                  closeDrawerIfOpen();
                  if (!isAdmin) {
                    _showRestrictedAccessDialog(context, 'Church Application Settings');
                  } else {
                    _showSettingsInfoDialog(context);
                  }
                },
              ),
            ],
          ),
        ),

        // Bottom User Shortcut & Sign Out
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E0E0C),
            border: Border(top: BorderSide(color: Color(0xFF452C27))),
          ),
          child: _buildSidebarActionItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFE57373),
            label: 'Sign Out',
            labelColor: const Color(0xFFE57373),
            onTap: () => showLogoutConfirmationDialog(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    int? badgeCount,
    bool isPending = false,
    bool isRestricted = false,
    required VoidCallback onTap,
  }) {
    const activeBg = Color(0xFF9E7B35);
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected
          ? Colors.white
          : (isPending || isRestricted ? const Color(0xFFA89A95) : const Color(0xFFEAE3DF)),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected
                  ? Colors.white
                  : (isPending || isRestricted ? const Color(0xFFA89A95) : AppColors.mutedGold),
            ),
            const SizedBox(width: AppStyles.space12),
            Expanded(
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            if (isRestricted) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF9E958F)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarActionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color labelColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 19),
            const SizedBox(width: AppStyles.space12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E958F), size: 12),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // B. Top App Bar (Workspace Header)
  // ===============================================================
  Widget _buildTopAppBar(
    BuildContext context,
    AuthState auth,
    Map<MemberStatus, int> counts,
    bool isDesktop,
  ) {
    final pendingCount = counts[MemberStatus.pending] ?? 0;
    final staffRole = (auth.profile?.role ?? 'Staff').toUpperCase();
    final staffName = auth.fullName ?? 'Church Administrator';

    String title = 'Dashboard';
    if (_activeView == AdminNavView.members) {
      title = 'Member Management & Verification';
    } else if (_activeView == AdminNavView.audit) {
      title = 'Verification Audit Trail';
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1.0)),
      ),
      child: Row(
        children: [
          // Drawer hamburger button on Mobile/Tablet
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primaryBrown),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 4),
          ],

          // Page Title
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBrown,
              ),
            ),
          ),
          const SizedBox(width: AppStyles.space12),

          // Search Field on Desktop (shrinks or expands smoothly)
          if (isDesktop) ...[
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320, minWidth: 100),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(adminSearchQueryProvider.notifier).setQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search members, announcements...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(adminSearchQueryProvider.notifier).setQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceCream,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                          borderSide: const BorderSide(color: AppColors.mutedGold, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppStyles.space16),
          ] else
            const Spacer(),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryBrown),
                tooltip: 'Church Notifications',
                onPressed: () => _showNotificationSummaryModal(context, pendingCount),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppStyles.space8),

          // Staff Profile Chip & Menu
          PopupMenuButton<String>(
            tooltip: 'Staff Account Menu',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: AppStyles.roundedMedium),
            onSelected: (val) {
              if (val == 'announcements') {
                context.push('/announcements');
              } else if (val == 'celebrations') {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const ManageBirthdaysDialog(),
                );
              } else if (val == 'logout') {
                showLogoutConfirmationDialog(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                    Text(
                      'ROLE: $staffRole',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedGoldDark,
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'announcements',
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined, size: 18, color: AppColors.primaryBrown),
                    SizedBox(width: 10),
                    Text('Manage Announcements'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'celebrations',
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, size: 18, color: AppColors.primaryBrown),
                    SizedBox(width: 10),
                    Text('Manage Celebrations'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.errorRed),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberAvatar(
                  imageUrl: auth.profile?.profileImageUrl,
                  radius: 17,
                  backgroundColor: AppColors.surfaceCream,
                  iconColor: AppColors.mutedGold,
                  border: Border.all(color: AppColors.mutedGold, width: 1.5),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: AppStyles.space8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          staffName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        Text(
                          staffRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // C. Primary Dashboard View (Banner + Stats + 2-Column Content)
  // ===============================================================
  Widget _buildDashboardView({
    required BuildContext context,
    required AuthState auth,
    required Map<MemberStatus, int> counts,
    required AsyncValue<List<MemberProfile>> allMembersAsync,
    required AsyncValue<List<Announcement>> announcementsAsync,
    required AsyncValue<BirthdayAnniversaryWeek?> currentWeekAsync,
    required AsyncValue<List<AuditLog>> auditLogsAsync,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Banner
          _buildWelcomeBanner(context, auth),
          const SizedBox(height: AppStyles.space20),

          // 2. Real Dashboard Statistics Row
          _buildStatisticsCards(context, counts, announcementsAsync, currentWeekAsync),
          const SizedBox(height: AppStyles.space24),

          // 3. Two-Column Dashboard Workspace (Desktop) vs Stacked (Mobile/Tablet)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Pending Member Approvals & Recent Announcements
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPendingApprovalsCard(context, allMembersAsync),
                      const SizedBox(height: AppStyles.space24),
                      _buildRecentAnnouncementsCard(context, announcementsAsync),
                    ],
                  ),
                ),
                const SizedBox(width: AppStyles.space24),

                // Right Column: This Week in Celebrations & Staff Quick Actions
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeeklyCelebrationsCard(context, currentWeekAsync),
                      const SizedBox(height: AppStyles.space24),
                      _buildStaffQuickActionsCard(context, counts),
                      const SizedBox(height: AppStyles.space24),
                      _buildRecentAuditFeedCard(context, auditLogsAsync),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            // Stacked column on Mobile / Tablet
            _buildPendingApprovalsCard(context, allMembersAsync),
            const SizedBox(height: AppStyles.space20),
            _buildWeeklyCelebrationsCard(context, currentWeekAsync),
            const SizedBox(height: AppStyles.space20),
            _buildRecentAnnouncementsCard(context, announcementsAsync),
            const SizedBox(height: AppStyles.space20),
            _buildStaffQuickActionsCard(context, counts),
            const SizedBox(height: AppStyles.space20),
            _buildRecentAuditFeedCard(context, auditLogsAsync),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // Welcome Banner (Personalized Greeting + Spire Artwork)
  // ===============================================================
  Widget _buildWelcomeBanner(BuildContext context, AuthState auth) {
    final staffName = auth.fullName ?? 'Church Administrator';
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning,';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon,';
    } else if (hour >= 17) {
      greeting = 'Good Evening,';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppStyles.roundedLarge,
        border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.35), width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBF4E8),
            Color(0xFFF5E6CC),
          ],
        ),
        boxShadow: AppStyles.elevation1,
      ),
      child: ClipRRect(
        borderRadius: AppStyles.roundedLarge,
        child: Stack(
          children: [
            // Decorative Church Spire Graphic in background right
            Positioned(
              right: -10,
              top: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.12,
                child: const Icon(
                  Icons.church_rounded,
                  size: 160,
                  color: AppColors.primaryBrownDark,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppStyles.space24, vertical: AppStyles.space20),
              child: Row(
                children: [
                  // Olive branch decorative icon
                  Container(
                    padding: const EdgeInsets.all(AppStyles.space12),
                    decoration: BoxDecoration(
                      color: AppColors.mutedGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: AppColors.mutedGoldDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedGoldDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBrown,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Church Staff Portal • Manage members, announcements and parish activities',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // Dashboard Statistics Cards
  // ===============================================================
  Widget _buildStatisticsCards(
    BuildContext context,
    Map<MemberStatus, int> counts,
    AsyncValue<List<Announcement>> announcementsAsync,
    AsyncValue<BirthdayAnniversaryWeek?> currentWeekAsync,
  ) {
    final totalApproved = counts[MemberStatus.approved] ?? 0;
    final totalPending = counts[MemberStatus.pending] ?? 0;

    final announcementsCount = announcementsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    final celebrationsCount = currentWeekAsync.maybeWhen(
      data: (week) => (week?.birthdays.length ?? 0) + (week?.anniversaries.length ?? 0),
      orElse: () => 0,
    );

    final statCards = [
      AppStatCard(
        title: 'Total Members',
        count: '$totalApproved',
        icon: Icons.people_alt_rounded,
        color: AppColors.successGreen,
        subtitle: 'Approved Members',
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.approved);
          setState(() => _activeView = AdminNavView.members);
        },
      ),
      AppStatCard(
        title: 'Pending Approvals',
        count: '$totalPending',
        icon: Icons.schedule_rounded,
        color: AppColors.warningAmber,
        subtitle: 'Awaiting Review',
        isSelected: totalPending > 0,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
          setState(() => _activeView = AdminNavView.members);
        },
      ),
      AppStatCard(
        title: 'Announcements',
        count: '$announcementsCount',
        icon: Icons.campaign_rounded,
        color: AppColors.accentBurgundy,
        subtitle: 'Published Notices',
        onTap: () => context.push('/announcements'),
      ),
      AppStatCard(
        title: 'Celebrations',
        count: '$celebrationsCount',
        icon: Icons.cake_rounded,
        color: AppColors.mutedGoldDark,
        subtitle: 'This week',
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const ManageBirthdaysDialog(),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: statCards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else {
          return GridView.count(
            crossAxisCount: constraints.maxWidth < 500 ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 500 ? 3.0 : 2.2,
            children: statCards,
          );
        }
      },
    );
  }

  // ===============================================================
  // Pending Member Approvals Card
  // ===============================================================
  Widget _buildPendingApprovalsCard(
    BuildContext context,
    AsyncValue<List<MemberProfile>> allMembersAsync,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Pending Member Approvals',
            icon: Icons.assignment_turned_in_outlined,
            action: TextButton(
              onPressed: () {
                ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
                setState(() => _activeView = AdminNavView.members);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppStyles.space8),

          allMembersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppStyles.space24),
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(AppStyles.space16),
              child: Text('Error loading pending requests: $err', style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
            ),
            data: (members) {
              final pendingList = members.where((m) => m.status == MemberStatus.pending).take(3).toList();

              if (pendingList.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All Caught Up!',
                  message: 'No pending member applications awaiting verification.',
                  padding: EdgeInsets.all(AppStyles.space20),
                );
              }

              return Column(
                children: pendingList.map((m) {
                  final formattedDate = m.createdAt != null
                      ? DateFormat('d MMM, y').format(m.createdAt!)
                      : 'Recent';

                  return InkWell(
                    onTap: () => _openVerificationDialog(context, m),
                    borderRadius: AppStyles.roundedMedium,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          MemberAvatar(
                            imageUrl: m.profileImageUrl,
                            radius: 20,
                            backgroundColor: AppColors.surfaceCream,
                            iconColor: AppColors.mutedGold,
                            border: Border.all(color: AppColors.mutedGold, width: 1.5),
                          ),
                          const SizedBox(width: AppStyles.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.fullName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBrown,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'New member request • Family #${m.familyNumber}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // Recent Announcements Card
  // ===============================================================
  Widget _buildRecentAnnouncementsCard(
    BuildContext context,
    AsyncValue<List<Announcement>> announcementsAsync,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Announcements',
            icon: Icons.campaign_rounded,
            action: TextButton(
              onPressed: () => context.push('/announcements'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppStyles.space8),

          announcementsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppStyles.space20),
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(AppStyles.space12),
              child: Text('Error loading notices: $err', style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No Announcements',
                  message: 'No published announcements or drafts found.',
                  padding: EdgeInsets.all(AppStyles.space20),
                );
              }

              final recent = list.take(2).toList();
              return Column(
                children: recent.map((a) {
                  final dateStr = a.createdAt != null
                      ? DateFormat('EEE, d MMM y').format(a.createdAt!)
                      : 'Notice';

                  String badgeLabel = 'General';
                  Color badgeColor = AppColors.primaryBrown;
                  Color badgeBg = AppColors.surfaceCream;
                  IconData badgeIcon = Icons.campaign_rounded;

                  if (a.announcementType == AnnouncementType.marriage) {
                    badgeLabel = 'Marriage';
                    badgeColor = AppColors.accentBurgundy;
                    badgeBg = AppColors.accentBurgundyLight;
                    badgeIcon = Icons.favorite_rounded;
                  } else if (a.announcementType == AnnouncementType.special) {
                    badgeLabel = 'Special';
                    badgeColor = AppColors.mutedGoldDark;
                    badgeBg = AppColors.statusDraftBg;
                    badgeIcon = Icons.celebration_rounded;
                  }

                  final subtitle = a.announcementType == AnnouncementType.marriage &&
                          a.brideName != null &&
                          a.groomName != null
                      ? '${a.brideName} & ${a.groomName}'
                      : (a.description.isNotEmpty ? a.description : 'Parish notice details');

                  return InkWell(
                    onTap: () => context.push('/announcements/${a.id}', extra: a),
                    borderRadius: AppStyles.roundedMedium,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1),
                            ),
                            child: Icon(badgeIcon, color: badgeColor, size: 22),
                          ),
                          const SizedBox(width: AppStyles.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                                        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dateStr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBrown,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // This Week in Celebrations Card
  // ===============================================================
  Widget _buildWeeklyCelebrationsCard(
    BuildContext context,
    AsyncValue<BirthdayAnniversaryWeek?> currentWeekAsync,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'This Week in Celebrations',
            icon: Icons.cake_rounded,
            action: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const ManageBirthdaysDialog(),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppStyles.space8),

          currentWeekAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppStyles.space16),
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(AppStyles.space12),
              child: Text('Error loading celebrations: $err', style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
            ),
            data: (week) {
              final bdayCount = week?.birthdays.length ?? 0;
              final annivCount = week?.anniversaries.length ?? 0;
              final hasEvents = bdayCount > 0 || annivCount > 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlight Summary Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      border: Border.all(color: AppColors.mutedGold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, size: 18, color: AppColors.mutedGoldDark),
                        const SizedBox(width: AppStyles.space8),
                        Expanded(
                          child: Text(
                            '$bdayCount Birthdays  •  $annivCount Wedding Anniversaries',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!hasEvents) ...[
                    const SizedBox(height: AppStyles.space12),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppStyles.space12),
                        child: Text(
                          'No birthdays or anniversaries scheduled for this week in fellowship.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppStyles.space10),
                    if (week!.birthdays.isNotEmpty)
                      ...week.birthdays.take(2).map((b) => _buildCelebrantListRow(
                            icon: Icons.cake_rounded,
                            iconColor: AppColors.primaryBrown,
                            name: b.memberName,
                            eventText: 'Birthday • ${DateFormat('EEE, d MMM').format(b.eventDate)}',
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const ManageBirthdaysDialog(),
                              );
                            },
                          )),
                    if (week.anniversaries.isNotEmpty)
                      ...week.anniversaries.take(2).map((a) => _buildCelebrantListRow(
                            icon: Icons.favorite_rounded,
                            iconColor: AppColors.accentBurgundy,
                            name: a.coupleName,
                            eventText: 'Anniversary • ${DateFormat('EEE, d MMM').format(a.eventDate)}',
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const ManageBirthdaysDialog(),
                              );
                            },
                          )),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrantListRow({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String eventText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.roundedSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: AppStyles.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eventText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppStyles.space8),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // Staff Quick Actions Card
  // ===============================================================
  Widget _buildStaffQuickActionsCard(BuildContext context, Map<MemberStatus, int> counts) {
    final pendingCount = counts[MemberStatus.pending] ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Staff Quick Actions',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: AppStyles.space8),

          _buildQuickActionTile(
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.primaryBrown,
            title: 'Review Pending Applications',
            subtitle: '$pendingCount applicant(s) awaiting approval',
            onTap: () {
              ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
              setState(() => _activeView = AdminNavView.members);
            },
          ),
          const Divider(height: 12),
          _buildQuickActionTile(
            icon: Icons.add_circle_outline_rounded,
            iconColor: AppColors.accentBurgundy,
            title: 'Draft New Announcement',
            subtitle: 'Create general, marriage or special notices',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AnnouncementFormDialog(),
              );
            },
          ),
          const Divider(height: 12),
          _buildQuickActionTile(
            icon: Icons.cake_outlined,
            iconColor: AppColors.mutedGoldDark,
            title: 'Manage Celebrations Bulletin',
            subtitle: 'Review & publish weekly parish calendar',
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const ManageBirthdaysDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.roundedMedium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.space8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppStyles.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // Recent Audit Feed Card
  // ===============================================================
  Widget _buildRecentAuditFeedCard(
    BuildContext context,
    AsyncValue<List<AuditLog>> auditLogsAsync,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Verification Activity',
            icon: Icons.history_rounded,
            action: TextButton(
              onPressed: () => setState(() => _activeView = AdminNavView.audit),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Audit Trail', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppStyles.space8),

          auditLogsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Error loading activity: $err', style: const TextStyle(fontSize: 11, color: AppColors.errorRed)),
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No verification activity recorded yet.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                );
              }

              final recentLogs = logs.take(3).toList();
              return Column(
                children: recentLogs.map((log) {
                  final formattedDate = log.timestamp != null
                      ? DateFormat('d MMM, h:mm a').format(log.timestamp!)
                      : 'Recent';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.successGreen),
                        const SizedBox(width: AppStyles.space8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.action.toUpperCase()}: ${log.targetFullName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
                              ),
                              Text(
                                'Role: ${log.performedByRole.toUpperCase()} • $formattedDate',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // D. Members Directory & Verification View
  // ===============================================================
  Widget _buildMembersView({
    required BuildContext context,
    required MemberStatus? activeStatusFilter,
    required List<MemberProfile> filteredMembers,
    required AsyncValue<List<MemberProfile>> allMembersAsync,
    required Map<MemberStatus, int> counts,
  }) {
    final activeSort = ref.watch(adminMemberSortProvider);
    final pendingCount = counts[MemberStatus.pending] ?? 0;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return allMembersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBrown),
              SizedBox(height: AppStyles.space16),
              Text(
                'Loading member records from registry...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: AppCard(
            color: AppColors.errorRedLight,
            padding: const EdgeInsets.all(AppStyles.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 40),
                const SizedBox(height: AppStyles.space12),
                Text(
                  'Failed to load member records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppStyles.space8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppStyles.space16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ref.refresh(allMembersStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (allMembers) {
        // Calculate pagination slices
        final totalCount = filteredMembers.length;
        final totalPages = max(1, (totalCount / _pageSize).ceil());
        final currentPage = _memberPage.clamp(1, totalPages);
        final startIndex = totalCount == 0 ? 0 : (currentPage - 1) * _pageSize;
        final endIndex = min(startIndex + _pageSize, totalCount);
        final pageMembers = totalCount == 0
            ? <MemberProfile>[]
            : filteredMembers.sublist(startIndex, endIndex);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Church Members Header Banner
              _buildMembersHeaderBanner(),
              const SizedBox(height: AppStyles.space16),

              // 2. 5 KPI Statistics Cards (Total, Pending, Approved, Suspended, Rejected)
              _buildMembersStatisticsCards(
                counts: counts,
                allMembers: allMembers,
                activeStatusFilter: activeStatusFilter,
              ),
              const SizedBox(height: AppStyles.space16),

              // 3. Sub-Navigation Tabs: Member Registry (All) & Pending Verification (count)
              _buildMembersNavigationTabs(
                activeStatusFilter: activeStatusFilter,
                pendingCount: pendingCount,
              ),
              const SizedBox(height: AppStyles.space12),

              // 4. Search and Filter Controls Bar
              _buildSearchAndFilterControlsBar(
                activeStatusFilter: activeStatusFilter,
                activeSort: activeSort,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: AppStyles.space12),

              // 5. Member Table or Empty State
              if (filteredMembers.isEmpty)
                _buildEmptyState(activeStatusFilter)
              else
                _buildMembersList(pageMembers),

              // 6. Pagination Footer
              if (filteredMembers.isNotEmpty)
                _buildPaginationFooter(
                  totalCount: totalCount,
                  startIndex: startIndex,
                  endIndex: endIndex,
                  currentPage: currentPage,
                  totalPages: totalPages,
                ),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // E. Audit Trail View
  // ===============================================================
  Widget _buildAuditView({
    required BuildContext context,
    required AsyncValue<List<AuditLog>> auditLogsAsync,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppStyles.space16),
      child: _buildAuditLogsTab(auditLogsAsync),
    );
  }

  // ===============================================================
  // 1. Church Members Header Banner
  // ===============================================================
  Widget _buildMembersHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF4E8), Color(0xFFF5E6CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppStyles.roundedLarge,
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.0),
        boxShadow: AppStyles.elevation1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.space12),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mutedGold, width: 1.5),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.primaryBrown,
              size: 26,
            ),
          ),
          const SizedBox(width: AppStyles.space16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Church Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBrown,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage member registry, review new applications and verify membership',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: 0.15,
            child: const Icon(
              Icons.church_rounded,
              size: 56,
              color: AppColors.primaryBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 2. 5 KPI Statistics Cards
  // ===============================================================
  Widget _buildMembersStatisticsCards({
    required Map<MemberStatus, int> counts,
    required List<MemberProfile> allMembers,
    required MemberStatus? activeStatusFilter,
  }) {
    final total = counts.values.fold(0, (a, b) => a + b);
    final pending = counts[MemberStatus.pending] ?? 0;
    final approved = counts[MemberStatus.approved] ?? 0;
    final suspended = counts[MemberStatus.suspended] ?? 0;
    final rejected = counts[MemberStatus.rejected] ?? 0;

    // Calculate members registered in current month
    final now = DateTime.now();
    final thisMonthCount = allMembers.where((m) {
      if (m.createdAt == null) return false;
      return m.createdAt!.year == now.year && m.createdAt!.month == now.month;
    }).length;

    final statCards = [
      AppStatCard(
        title: 'Total Members',
        count: '$total',
        icon: Icons.group_rounded,
        color: const Color(0xFF2E7D32),
        subtitle: thisMonthCount > 0 ? '+$thisMonthCount this month' : 'All registered',
        isSelected: activeStatusFilter == null,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(null);
          setState(() => _memberPage = 1);
        },
      ),
      AppStatCard(
        title: 'Pending Review',
        count: '$pending',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFC5A059),
        subtitle: 'Awaiting verification',
        isSelected: activeStatusFilter == MemberStatus.pending,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
          setState(() => _memberPage = 1);
        },
      ),
      AppStatCard(
        title: 'Approved',
        count: '$approved',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF2E7D32),
        subtitle: 'Active members',
        isSelected: activeStatusFilter == MemberStatus.approved,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.approved);
          setState(() => _memberPage = 1);
        },
      ),
      AppStatCard(
        title: 'Suspended',
        count: '$suspended',
        icon: Icons.block_rounded,
        color: const Color(0xFFC62828),
        subtitle: 'Under review',
        isSelected: activeStatusFilter == MemberStatus.suspended,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.suspended);
          setState(() => _memberPage = 1);
        },
      ),
      AppStatCard(
        title: 'Rejected',
        count: '$rejected',
        icon: Icons.cancel_outlined,
        color: const Color(0xFF6E655F),
        subtitle: 'Declined requests',
        isSelected: activeStatusFilter == MemberStatus.rejected,
        onTap: () {
          ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.rejected);
          setState(() => _memberPage = 1);
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1080) {
          return Row(
            children: statCards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        } else if (constraints.maxWidth >= 600) {
          return GridView.count(
            crossAxisCount: constraints.maxWidth >= 850 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: statCards,
          );
        } else {
          return GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: statCards,
          );
        }
      },
    );
  }

  // ===============================================================
  // 3. Segmented Navigation Tabs
  // ===============================================================
  Widget _buildMembersNavigationTabs({
    required MemberStatus? activeStatusFilter,
    required int pendingCount,
  }) {
    final isPendingTab = activeStatusFilter == MemberStatus.pending;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tab 1: Member Registry (All)
          InkWell(
            onTap: () {
              if (activeStatusFilter == MemberStatus.pending) {
                ref.read(adminStatusFilterProvider.notifier).setFilter(null);
                setState(() => _memberPage = 1);
              }
            },
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: !isPendingTab ? const Color(0xFF271512) : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                border: Border.all(
                  color: !isPendingTab ? const Color(0xFF271512) : AppColors.borderDefault,
                  width: 1.2,
                ),
                boxShadow: !isPendingTab ? AppStyles.elevation1 : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 17,
                    color: !isPendingTab ? AppColors.mutedGold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppStyles.space8),
                  Text(
                    'Member Registry (All)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !isPendingTab ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppStyles.space10),

          // Tab 2: Pending Verification (with count badge)
          InkWell(
            onTap: () {
              ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
              setState(() => _memberPage = 1);
            },
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isPendingTab ? const Color(0xFF271512) : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                border: Border.all(
                  color: isPendingTab ? const Color(0xFF271512) : AppColors.borderDefault,
                  width: 1.2,
                ),
                boxShadow: isPendingTab ? AppStyles.elevation1 : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 17,
                    color: isPendingTab ? AppColors.mutedGold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppStyles.space8),
                  Text(
                    'Pending Verification',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPendingTab ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: AppStyles.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 4. Search and Filter Controls Bar
  // ===============================================================
  Widget _buildSearchAndFilterControlsBar({
    required MemberStatus? activeStatusFilter,
    required AdminMemberSort activeSort,
    required bool isDesktop,
  }) {
    final statusDropdown = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MemberStatus?>(
          value: activeStatusFilter,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          onChanged: (val) {
            ref.read(adminStatusFilterProvider.notifier).setFilter(val);
            setState(() => _memberPage = 1);
          },
          items: const [
            DropdownMenuItem(value: null, child: Text('Status: All')),
            DropdownMenuItem(value: MemberStatus.pending, child: Text('Status: Pending Review')),
            DropdownMenuItem(value: MemberStatus.approved, child: Text('Status: Approved')),
            DropdownMenuItem(value: MemberStatus.suspended, child: Text('Status: Suspended')),
            DropdownMenuItem(value: MemberStatus.rejected, child: Text('Status: Rejected')),
          ],
        ),
      ),
    );

    final sortDropdown = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AdminMemberSort>(
          value: activeSort,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          onChanged: (val) {
            if (val != null) {
              ref.read(adminMemberSortProvider.notifier).setSort(val);
              setState(() => _memberPage = 1);
            }
          },
          items: const [
            DropdownMenuItem(value: AdminMemberSort.latestRegistered, child: Text('Sort: Date Registered (Latest)')),
            DropdownMenuItem(value: AdminMemberSort.oldestRegistered, child: Text('Sort: Date Registered (Oldest)')),
            DropdownMenuItem(value: AdminMemberSort.nameAsc, child: Text('Sort: Name (A – Z)')),
            DropdownMenuItem(value: AdminMemberSort.nameDesc, child: Text('Sort: Name (Z – A)')),
            DropdownMenuItem(value: AdminMemberSort.familyNumberAsc, child: Text('Sort: Family No. (Ascending)')),
          ],
        ),
      ),
    );

    final searchField = SizedBox(
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(adminSearchQueryProvider.notifier).setQuery(val);
          setState(() => _memberPage = 1);
        },
        decoration: InputDecoration(
          hintText: 'Search by name, email, phone or Family No...',
          hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 19),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 17),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(adminSearchQueryProvider.notifier).setQuery('');
                    setState(() => _memberPage = 1);
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            borderSide: const BorderSide(color: AppColors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            borderSide: const BorderSide(color: AppColors.mutedGold, width: 1.5),
          ),
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: searchField),
          const SizedBox(width: AppStyles.space12),
          statusDropdown,
          const SizedBox(width: AppStyles.space12),
          sortDropdown,
        ],
      );
    } else {
      return Column(
        children: [
          searchField,
          const SizedBox(height: AppStyles.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                statusDropdown,
                const SizedBox(width: AppStyles.space8),
                sortDropdown,
              ],
            ),
          ),
        ],
      );
    }
  }

  // ===============================================================
  // 5. Members List (Desktop Table vs Mobile Cards)
  // ===============================================================
  Widget _buildMembersList(List<MemberProfile> members) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        if (isDesktop) {
          return _buildDesktopTable(members);
        } else {
          return _buildMobileCardsList(members);
        }
      },
    );
  }

  Widget _buildDesktopTable(List<MemberProfile> members) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppStyles.roundedLarge,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFBF8F4)),
            dataRowMaxHeight: 74,
            columnSpacing: 18,
            columns: const [
              DataColumn(
                label: Text(
                  'MEMBER',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
              DataColumn(
                label: Text(
                  'FAMILY NO.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
              DataColumn(
                label: Text(
                  'CONTACT INFORMATION',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
              DataColumn(
                label: Text(
                  'DATE REGISTERED',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTIONS',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
              ),
            ],
            rows: members.map((m) {
              final formattedDate = m.createdAt != null
                  ? DateFormat('EEE, d MMM y').format(m.createdAt!)
                  : '-';

              String memberSubtitle = 'Registered Member';
              if (m.status == MemberStatus.pending) {
                memberSubtitle = 'Applicant • New Registration';
              } else if (m.status == MemberStatus.suspended) {
                memberSubtitle = 'Suspended Member';
              } else if (m.status == MemberStatus.rejected) {
                memberSubtitle = 'Declined Applicant';
              }

              final isPending = m.status == MemberStatus.pending;

              return DataRow(
                cells: [
                  // 1. MEMBER (Avatar + Name + Subtitle)
                  DataCell(
                    Row(
                      children: [
                        MemberAvatar(
                          imageUrl: m.profileImageUrl,
                          radius: 19,
                          border: Border.all(color: AppColors.mutedGold, width: 1.5),
                        ),
                        const SizedBox(width: AppStyles.space12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              memberSubtitle,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. FAMILY NO.
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Text(
                        '#${m.familyNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryBrown),
                      ),
                    ),
                  ),

                  // 3. CONTACT INFORMATION (Email & Phone with icons)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              m.email,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              m.phone != null && m.phone!.isNotEmpty ? m.phone! : 'Not provided',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. DATE REGISTERED
                  DataCell(
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),

                  // 5. STATUS
                  DataCell(_buildStatusBadge(m.status)),

                  // 6. ACTIONS (Primary button + ⋮ overflow menu)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E2723),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text(
                              'Review Application',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _openVerificationDialog(context, m),
                          )
                        else
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryBrown,
                              side: const BorderSide(color: Color(0xFFC5A059), width: 1.0),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.badge_outlined, size: 14, color: AppColors.mutedGoldDark),
                            label: const Text(
                              'View Profile',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
                            ),
                            onPressed: () => _openVerificationDialog(context, m),
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                          tooltip: 'Actions',
                          shape: RoundedRectangleBorder(borderRadius: AppStyles.roundedMedium),
                          onSelected: (action) => _openVerificationDialog(context, m),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primaryBrown),
                                  SizedBox(width: 8),
                                  Text('View Full Profile', style: TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                            if (isPending) ...[
                              const PopupMenuItem(
                                value: 'approve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.successGreen),
                                    SizedBox(width: 8),
                                    Text('Approve Application', style: TextStyle(fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reject',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
                                    SizedBox(width: 8),
                                    Text('Reject Application', style: TextStyle(fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ] else if (m.status == MemberStatus.approved) ...[
                              const PopupMenuItem(
                                value: 'suspend',
                                child: Row(
                                  children: [
                                    Icon(Icons.block_rounded, size: 16, color: AppColors.warningAmber),
                                    SizedBox(width: 8),
                                    Text('Suspend Membership', style: TextStyle(fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ] else if (m.status == MemberStatus.suspended) ...[
                              const PopupMenuItem(
                                value: 'restore',
                                child: Row(
                                  children: [
                                    Icon(Icons.restore_rounded, size: 16, color: AppColors.successGreen),
                                    SizedBox(width: 8),
                                    Text('Restore Membership', style: TextStyle(fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardsList(List<MemberProfile> members) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        final formattedDate = m.createdAt != null
            ? DateFormat('EEE, d MMM y').format(m.createdAt!)
            : '-';

        final isPending = m.status == MemberStatus.pending;

        return AppCard(
          margin: const EdgeInsets.only(bottom: AppStyles.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(
                    imageUrl: m.profileImageUrl,
                    radius: 20,
                    border: Border.all(color: AppColors.mutedGold, width: 1.5),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryBrown),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPending ? 'Applicant • New Registration' : 'Registered Member',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(m.status),
                ],
              ),
              const Divider(height: AppStyles.space16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mutedGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.mutedGoldDark, width: 0.8),
                    ),
                    child: Text(
                      'Family #${m.familyNumber}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
                    ),
                  ),
                  const Spacer(),
                  Text(formattedDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      m.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space10),
              SizedBox(
                width: double.infinity,
                child: isPending
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E2723),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text(
                          'Review Application',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _openVerificationDialog(context, m),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBrown,
                          side: const BorderSide(color: Color(0xFFC5A059)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.badge_outlined, size: 15, color: AppColors.mutedGoldDark),
                        label: const Text(
                          'View Profile',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
                        ),
                        onPressed: () => _openVerificationDialog(context, m),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // 6. Pagination Footer Controls
  // ===============================================================
  Widget _buildPaginationFooter({
    required int totalCount,
    required int startIndex,
    required int endIndex,
    required int currentPage,
    required int totalPages,
  }) {
    if (totalCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.space12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${startIndex + 1} – $endIndex of $totalCount members',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                tooltip: 'Previous Page',
                onPressed: currentPage > 1
                    ? () => setState(() => _memberPage = currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 4),
              ..._buildPageNumbers(currentPage, totalPages),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                tooltip: 'Next Page',
                onPressed: currentPage < totalPages
                    ? () => setState(() => _memberPage = currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> buttons = [];
    Set<int> pagesToShow = {};
    pagesToShow.add(1);
    pagesToShow.add(totalPages);
    for (int i = max(1, currentPage - 1); i <= min(totalPages, currentPage + 1); i++) {
      pagesToShow.add(i);
    }
    final sortedPages = pagesToShow.toList()..sort();

    int? prevPage;
    for (final p in sortedPages) {
      if (prevPage != null && p > prevPage + 1) {
        buttons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: AppColors.textMuted)),
          ),
        );
      }
      final isCurrent = p == currentPage;
      buttons.add(
        InkWell(
          onTap: () => setState(() => _memberPage = p),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.mutedGold : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent ? AppColors.mutedGold : AppColors.borderDefault,
              ),
            ),
            child: Text(
              '$p',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
      prevPage = p;
    }

    return buttons;
  }

  Widget _buildStatusBadge(MemberStatus status) {
    AppStatusType type = AppStatusType.info;
    String label = status.name;

    switch (status) {
      case MemberStatus.pending:
        type = AppStatusType.pending;
        label = 'Pending Review';
        break;
      case MemberStatus.approved:
        type = AppStatusType.approved;
        label = 'Approved';
        break;
      case MemberStatus.suspended:
        type = AppStatusType.suspended;
        label = 'Suspended';
        break;
      case MemberStatus.rejected:
        type = AppStatusType.rejected;
        label = 'Rejected';
        break;
      case MemberStatus.none:
        type = AppStatusType.info;
        label = 'Unknown';
        break;
    }

    return AppStatusBadge(
      label: label,
      type: type,
      showDot: true,
      isCompact: true,
    );
  }

  Widget _buildAuditLogsTab(AsyncValue<List<AuditLog>> auditLogsAsync) {
    return auditLogsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primaryBrown),
        ),
      ),
      error: (err, stack) => Center(
        child: AppCard(
          color: AppColors.errorRedLight,
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 40),
              const SizedBox(height: AppStyles.space12),
              Text(
                'Failed to load audit trail',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppStyles.space8),
              Text(err.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'No Audit Records',
            message: 'Administrative verification actions will appear here in chronological order.',
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: AppStyles.roundedLarge,
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1, color: AppColors.borderDefault),
              itemBuilder: (context, index) {
                final log = logs[index];
                final formattedDate = log.timestamp != null
                    ? DateFormat('MMM d, y  •  h:mm:ss a').format(log.timestamp!)
                    : '-';

                Color actionColor = AppColors.primaryBrown;
                if (log.action.toLowerCase() == 'approved') {
                  actionColor = AppColors.successGreen;
                } else if (log.action.toLowerCase() == 'rejected') {
                  actionColor = AppColors.errorRed;
                } else if (log.action.toLowerCase() == 'suspended') {
                  actionColor = AppColors.warningAmber;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(AppStyles.space8),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security_rounded, color: actionColor, size: 20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: actionColor, width: 0.8),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: actionColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppStyles.space8),
                      Expanded(
                        child: Text(
                          'Target: ${log.targetFullName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role: ${log.performedByRole.toUpperCase()}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        if (log.reason.isNotEmpty)
                          Text(
                            'Reason: ${log.reason}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openVerificationDialog(BuildContext context, MemberProfile member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MemberVerificationDialog(member: member),
    );
  }

  Widget _buildEmptyState(MemberStatus? filter) {
    String title = 'No members found';
    String message = 'Try adjusting your search query or filter.';

    if (filter == MemberStatus.pending) {
      title = 'All Caught Up!';
      message = 'There are no pending member applications awaiting verification.';
    }

    return AppEmptyState(
      icon: Icons.people_outline_rounded,
      title: title,
      message: message,
    );
  }

  Widget _buildAccessDeniedView(BuildContext context, AuthState auth) {
    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: Center(
        child: ResponsiveContainer(
          maxWidth: 500,
          padding: const EdgeInsets.all(AppStyles.space24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.errorRed, size: 56),
                const SizedBox(height: AppStyles.space16),
                const Text(
                  'Access Denied: Staff Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBrown,
                  ),
                ),
                const SizedBox(height: AppStyles.space8),
                const Text(
                  'Access to this administrative console is strictly restricted to ordained Pastors, Committee Members, and Church Administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppStyles.space20),
                AppButton(
                  label: 'Sign Out',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () => showLogoutConfirmationDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // Dialogs & SnackBars
  // ===============================================================
  void _showComingSoonSnackBar(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$moduleName will be available in an upcoming phase rollout.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRestrictedAccessDialog(BuildContext context, String sectionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.roundedLarge),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.space8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.errorRed, size: 20),
            ),
            const SizedBox(width: AppStyles.space12),
            const Expanded(
              child: Text(
                'Restricted to Administrators',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
              ),
            ),
          ],
        ),
        content: Text(
          '$sectionName is strictly restricted to Church Administrators.\nYour current staff role does not have permission to modify these settings.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          AppButton(
            label: 'Understood',
            size: AppButtonSize.compact,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showRoleManagementInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.roundedLarge),
        title: const Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: AppColors.primaryBrown),
            SizedBox(width: AppStyles.space12),
            Text(
              'Staff & Role Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
            ),
          ],
        ),
        content: const Text(
          'Administrator Console:\nStaff permissions are assigned via Firebase Authentication and Firestore claims for Admin, Committee, and Pastor roles.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          AppButton(
            label: 'Close',
            size: AppButtonSize.compact,
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showSettingsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.roundedLarge),
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: AppColors.primaryBrown),
            SizedBox(width: AppStyles.space12),
            Text(
              'Church Application Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryBrown),
            ),
          ],
        ),
        content: const Text(
          'System Configuration:\nParish name, diocese affiliation, FCM notification keys, and registration policies are configured by the administrator.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          AppButton(
            label: 'Close',
            size: AppButtonSize.compact,
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showNotificationSummaryModal(BuildContext context, int pendingCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppStyles.radiusXLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppColors.primaryBrown),
                  SizedBox(width: 8),
                  Text(
                    'Administrative Notifications',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pendingCount > 0 ? AppColors.warningAmber.withValues(alpha: 0.15) : AppColors.surfaceCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_ind_rounded,
                    color: pendingCount > 0 ? AppColors.warningAmber : AppColors.textSecondary,
                  ),
                ),
                title: Text('$pendingCount Member Application(s) Awaiting Review'),
                subtitle: const Text('Tap to review and verify new membership submissions.'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(adminStatusFilterProvider.notifier).setFilter(MemberStatus.pending);
                  setState(() => _activeView = AdminNavView.members);
                },
              ),
              const SizedBox(height: AppStyles.space16),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.compact,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
