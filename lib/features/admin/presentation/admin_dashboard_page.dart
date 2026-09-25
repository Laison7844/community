import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../auth/models/auth_state.dart';
import '../../auth/models/member_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/audit_log.dart';
import '../providers/admin_provider.dart';
import 'widgets/member_verification_dialog.dart';
import 'widgets/manage_birthdays_dialog.dart';

/// Comprehensive responsive Committee / Admin Verification Dashboard for Flutter Web.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final activeStatusFilter = ref.watch(adminStatusFilterProvider);
    final filteredMembers = ref.watch(filteredMembersProvider);
    final allMembersAsync = ref.watch(allMembersStreamProvider);
    final auditLogsAsync = ref.watch(auditLogsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      appBar: _buildAppBar(context, auth),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 1200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppStyles.space16),

              // Overview Header & KPI Metric Cards
              _buildMetricCards(counts, activeStatusFilter),
              const SizedBox(height: AppStyles.space20),

              // Navigation Tabs (Members Directory vs Audit Trail)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.softBeige, width: 1.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryBrown,
                  indicatorWeight: 3,
                  labelColor: AppColors.primaryBrown,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.people_alt_outlined, size: 20),
                      text: 'Members & Applicants (${counts[MemberStatus.pending] ?? 0} Pending)',
                    ),
                    const Tab(
                      icon: Icon(Icons.history_rounded, size: 20),
                      text: 'Verification Audit Trail',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppStyles.space16),

              // Main Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Member List with Search, Filter & Verification Actions
                    _buildMembersTab(
                      context: context,
                      activeStatusFilter: activeStatusFilter,
                      filteredMembers: filteredMembers,
                      allMembersAsync: allMembersAsync,
                      counts: counts,
                    ),

                    // Tab 2: Append-only Audit Trail
                    _buildAuditLogsTab(auditLogsAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App bar with church identity and staff credentials
  PreferredSizeWidget _buildAppBar(BuildContext context, AuthState auth) {
    final staffRole = (auth.profile?.role ?? 'staff').toUpperCase();

    return AppBar(
      backgroundColor: AppColors.surfaceCream,
      elevation: 1,
      title: Row(
        children: [
          const AppLogo(size: 36),
          const SizedBox(width: AppStyles.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Committee Verification Portal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBrown,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                AppStrings.churchName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Staff Badge
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mutedGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mutedGoldDark, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    size: 16, color: AppColors.primaryBrown),
                const SizedBox(width: 6),
                Text(
                  staffRole,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppStyles.space8),
        IconButton(
          tooltip: 'Manage Birthdays & Anniversaries',
          icon: const Icon(Icons.cake_outlined, color: AppColors.primaryBrown),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const ManageBirthdaysDialog(),
            );
          },
        ),
        IconButton(
          tooltip: 'Manage Parish Announcements',
          icon: const Icon(Icons.campaign_outlined, color: AppColors.primaryBrown),
          onPressed: () => context.push('/announcements'),
        ),
        IconButton(
          tooltip: 'Return to Church Home',
          icon: const Icon(Icons.home_outlined, color: AppColors.primaryBrown),
          onPressed: () => context.go('/home'),
        ),
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          onPressed: () => showLogoutConfirmationDialog(context, ref),
        ),
        const SizedBox(width: AppStyles.space12),
      ],
    );
  }

  /// Metric Overview cards for fast status assessment
  Widget _buildMetricCards(
      Map<MemberStatus, int> counts, MemberStatus? activeFilter) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final cards = [
          _buildStatCard(
            title: 'Pending Review',
            count: counts[MemberStatus.pending] ?? 0,
            status: MemberStatus.pending,
            color: AppColors.warningAmber,
            icon: Icons.hourglass_top_rounded,
            isSelected: activeFilter == MemberStatus.pending,
          ),
          _buildStatCard(
            title: 'Approved',
            count: counts[MemberStatus.approved] ?? 0,
            status: MemberStatus.approved,
            color: AppColors.subtleOlive,
            icon: Icons.check_circle_outline_rounded,
            isSelected: activeFilter == MemberStatus.approved,
          ),
          _buildStatCard(
            title: 'Suspended',
            count: counts[MemberStatus.suspended] ?? 0,
            status: MemberStatus.suspended,
            color: AppColors.errorRed,
            icon: Icons.block_rounded,
            isSelected: activeFilter == MemberStatus.suspended,
          ),
          _buildStatCard(
            title: 'Rejected',
            count: counts[MemberStatus.rejected] ?? 0,
            status: MemberStatus.rejected,
            color: Colors.grey.shade700,
            icon: Icons.highlight_off_rounded,
            isSelected: activeFilter == MemberStatus.rejected,
          ),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 420 ? 1.85 : 2.2,
            children: cards,
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: c,
          ))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required MemberStatus status,
    required Color color,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        // Toggle filter or set to this status
        final current = ref.read(adminStatusFilterProvider);
        if (current == status) {
          ref.read(adminStatusFilterProvider.notifier).setFilter(null); // Show all
        } else {
          ref.read(adminStatusFilterProvider.notifier).setFilter(status);
        }
      },
      borderRadius: AppStyles.roundedLarge,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppStyles.space16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.cardSurface,
          borderRadius: AppStyles.roundedLarge,
          border: Border.all(
            color: isSelected ? color : AppColors.softBeige,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : AppStyles.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppStyles.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : AppColors.primaryBrown,
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

  /// Members Directory Tab View
  Widget _buildMembersTab({
    required BuildContext context,
    required MemberStatus? activeStatusFilter,
    required List<MemberProfile> filteredMembers,
    required AsyncValue<List<MemberProfile>> allMembersAsync,
    required Map<MemberStatus, int> counts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar & Filter Pills
        _buildSearchAndFilterControls(activeStatusFilter),
        const SizedBox(height: AppStyles.space12),

        // List Content with Async Handling
        Expanded(
          child: allMembersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryBrown),
                    SizedBox(height: AppStyles.space16),
                    Text(
                      'Loading member records from registry...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, stack) => Center(
              child: AppCard(
                color: AppColors.errorRedLight,
                padding: const EdgeInsets.all(AppStyles.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.errorRed, size: 40),
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
            data: (_) {
              if (filteredMembers.isEmpty) {
                return _buildEmptyState(activeStatusFilter);
              }
              return _buildMembersList(filteredMembers);
            },
          ),
        ),
      ],
    );
  }

  /// Search Bar with Family Number & Name inputs + Filter Pills
  Widget _buildSearchAndFilterControls(MemberStatus? activeStatusFilter) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(adminSearchQueryProvider.notifier).setQuery(val);
                },
                decoration: InputDecoration(
                  hintText:
                      'Search by shared Family No., official full name, or email...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primaryBrown, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(adminSearchQueryProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppStyles.roundedLarge,
                    borderSide: const BorderSide(color: AppColors.softBeige),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppStyles.roundedLarge,
                    borderSide: const BorderSide(color: AppColors.softBeige),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppStyles.roundedLarge,
                    borderSide: const BorderSide(
                        color: AppColors.primaryBrown, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.space12),

        // Quick filter pill chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Records',
                isSelected: activeStatusFilter == null,
                onTap: () =>
                    ref.read(adminStatusFilterProvider.notifier).setFilter(null),
              ),
              const SizedBox(width: AppStyles.space8),
              _buildFilterChip(
                label: 'Pending Review',
                isSelected: activeStatusFilter == MemberStatus.pending,
                badgeColor: AppColors.warningAmber,
                onTap: () => ref
                    .read(adminStatusFilterProvider.notifier)
                    .setFilter(MemberStatus.pending),
              ),
              const SizedBox(width: AppStyles.space8),
              _buildFilterChip(
                label: 'Approved',
                isSelected: activeStatusFilter == MemberStatus.approved,
                badgeColor: AppColors.subtleOlive,
                onTap: () => ref
                    .read(adminStatusFilterProvider.notifier)
                    .setFilter(MemberStatus.approved),
              ),
              const SizedBox(width: AppStyles.space8),
              _buildFilterChip(
                label: 'Suspended',
                isSelected: activeStatusFilter == MemberStatus.suspended,
                badgeColor: AppColors.errorRed,
                onTap: () => ref
                    .read(adminStatusFilterProvider.notifier)
                    .setFilter(MemberStatus.suspended),
              ),
              const SizedBox(width: AppStyles.space8),
              _buildFilterChip(
                label: 'Rejected',
                isSelected: activeStatusFilter == MemberStatus.rejected,
                badgeColor: Colors.grey.shade600,
                onTap: () => ref
                    .read(adminStatusFilterProvider.notifier)
                    .setFilter(MemberStatus.rejected),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBrown,
      backgroundColor: AppColors.cardSurface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBrown : AppColors.softBeige,
      ),
      avatar: badgeColor != null
          ? CircleAvatar(radius: 4, backgroundColor: badgeColor)
          : null,
    );
  }

  /// Responsive Members List / Table
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

  /// Desktop & Tablet Table with Full Columns and Actions
  Widget _buildDesktopTable(List<MemberProfile> members) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppStyles.roundedLarge,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceCream),
            dataRowMaxHeight: 70,
            columnSpacing: 24,
            columns: const [
              DataColumn(
                label: Text(
                  'APPLICANT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'FAMILY NO.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'CONTACT INFO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'DATE REGISTERED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'VERIFICATION ACTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            rows: members.map((m) {
              final formattedDate = m.createdAt != null
                  ? DateFormat('MMM d, y').format(m.createdAt!)
                  : '-';

              return DataRow(
                cells: [
                  // Applicant (Photo + Name + UID snippet)
                  DataCell(
                    Row(
                      children: [
                        MemberAvatar(
                          imageUrl: m.profileImageUrl,
                          radius: 20,
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
                                fontSize: 13,
                                color: AppColors.primaryBrown,
                              ),
                            ),
                            Text(
                              'UID: ${m.uid.length > 8 ? m.uid.substring(0, 8) : m.uid}...',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Family Number
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mutedGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.mutedGoldDark, width: 0.8),
                      ),
                      child: Text(
                        'Fam #${m.familyNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                    ),
                  ),

                  // Contact (Email + Phone)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.email,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                        if (m.phone?.isNotEmpty == true)
                          Text(
                            m.phone!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Date
                  DataCell(
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),

                  // Status Badge
                  DataCell(_buildStatusBadge(m.status)),

                  // Action Button
                  DataCell(
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: m.status == MemberStatus.pending
                            ? AppColors.primaryBrown
                            : AppColors.surfaceCream,
                        foregroundColor: m.status == MemberStatus.pending
                            ? Colors.white
                            : AppColors.primaryBrown,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.primaryBrown, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: Icon(
                        m.status == MemberStatus.pending
                            ? Icons.verified_user_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                      ),
                      label: Text(
                        m.status == MemberStatus.pending
                            ? 'Verify Applicant'
                            : 'Review Details',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _openVerificationDialog(context, m),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
  }

  /// Compact Tablet & Mobile Cards List
  Widget _buildMobileCardsList(List<MemberProfile> members) {
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppStyles.space12),
      itemBuilder: (context, index) {
        final m = members[index];
        final formattedDate = m.createdAt != null
            ? DateFormat('MMM d, y').format(m.createdAt!)
            : '-';

        return AppCard(
          padding: const EdgeInsets.all(AppStyles.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(
                    imageUrl: m.profileImageUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryBrown,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(m.status),
                ],
              ),
              const Divider(height: AppStyles.space20),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBrown,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Reg: $formattedDate',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.space12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m.status == MemberStatus.pending
                        ? AppColors.primaryBrown
                        : AppColors.surfaceCream,
                    foregroundColor: m.status == MemberStatus.pending
                        ? Colors.white
                        : AppColors.primaryBrown,
                    side: const BorderSide(color: AppColors.primaryBrown),
                  ),
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text(
                    m.status == MemberStatus.pending
                        ? 'Verify Applicant & Photo'
                        : 'Review Details / Adjust Status',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  /// Verification dialog opener
  void _openVerificationDialog(BuildContext context, MemberProfile member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MemberVerificationDialog(member: member),
    );
  }

  /// Empty state display
  Widget _buildEmptyState(MemberStatus? filter) {
    String title = 'No members found';
    String message = 'Try adjusting your search query or filter.';

    if (filter == MemberStatus.pending) {
      title = 'All Caught Up!';
      message = 'There are no pending member applications awaiting verification.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.subtleOlive,
                size: 48,
              ),
            ),
            const SizedBox(height: AppStyles.space16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBrown,
              ),
            ),
            const SizedBox(height: AppStyles.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Audit Logs Tab
  Widget _buildAuditLogsTab(AsyncValue<List<AuditLog>> logsAsync) {
    return logsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBrown),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load audit logs: $e'),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(
            child: Text(
              'No verification actions have been logged yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (_, index) => const SizedBox(height: AppStyles.space8),
          itemBuilder: (context, index) {
            final log = logs[index];
            final dateStr = log.timestamp != null
                ? DateFormat('MMM d, y · h:mm a').format(log.timestamp!)
                : 'Recent';

            Color actionColor = AppColors.subtleOlive;
            IconData actionIcon = Icons.check_circle_rounded;
            if (log.action == 'reject') {
              actionColor = AppColors.errorRed;
              actionIcon = Icons.cancel_rounded;
            } else if (log.action == 'suspend') {
              actionColor = AppColors.errorRed;
              actionIcon = Icons.block_rounded;
            }

            return AppCard(
              padding: const EdgeInsets.all(AppStyles.space12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 20),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: log.performedByRole.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBrown,
                                ),
                              ),
                              TextSpan(
                                text: ' performed ${log.action.toUpperCase()} on ',
                              ),
                              TextSpan(
                                text: log.targetFullName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: ' (Fam #${log.targetFamilyNumber})',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transition: ${log.previousStatus} ➔ ${log.newStatus} | Reason: "${log.reason}"',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Status badge widget
  Widget _buildStatusBadge(MemberStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case MemberStatus.approved:
        bg = AppColors.successGreenLight;
        fg = AppColors.successGreen;
        text = 'Approved';
        break;
      case MemberStatus.pending:
        bg = AppColors.warningAmberLight;
        fg = AppColors.warningAmber;
        text = 'Pending Review';
        break;
      case MemberStatus.suspended:
        bg = AppColors.errorRedLight;
        fg = AppColors.errorRed;
        text = 'Suspended';
        break;
      case MemberStatus.rejected:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = 'Rejected';
        break;
      case MemberStatus.none:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade600;
        text = 'None';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Access Denied view when a non-staff user lands on the admin page
  Widget _buildAccessDeniedView(BuildContext context, AuthState auth) {
    return Scaffold(
      backgroundColor: AppColors.backgroundIvory,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppCard(
            padding: const EdgeInsets.all(AppStyles.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRedLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.errorRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppStyles.space20),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorRed,
                      ),
                ),
                const SizedBox(height: AppStyles.space12),
                const Text(
                  'This verification dashboard is restricted exclusively to authorized Church Committee, Pastor, and Administrator staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: AppStyles.space8),
                Text(
                  'Your current account role is: ${auth.profile?.role.toUpperCase() ?? "UNKNOWN"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppStyles.space24),
                AppButton(
                  label: 'Return to Church Home',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
