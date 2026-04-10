import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../data/discover_model.dart';
import '../../providers/discover_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static const _avatarColors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
  ];

  Color _colorForId(String id) {
    final code = id.codeUnits.fold(0, (a, b) => a + b);
    return _avatarColors[code % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(candidatesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: TextButton(
          onPressed: () {},
          child: const Text('筛选',
              style: TextStyle(color: AppColors.primary, fontSize: 15)),
        ),
        title: const Text('发现搭伴'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                (currentUser?.username ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: candidatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('加载失败',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(candidatesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (candidates) {
          if (candidates.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('暂无匹配用户',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          final main = candidates.first;
          final rest = candidates.skip(1).toList();

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MainCard(
                  candidate: main,
                  avatarColor: _colorForId(main.id),
                  onSkip: () =>
                      ref.read(candidatesProvider.notifier).skip(main.id),
                  onLike: () =>
                      ref.read(candidatesProvider.notifier).like(main.id),
                ),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '其他候选',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3.0,
                    ),
                    itemCount: rest.length,
                    itemBuilder: (context, index) {
                      final c = rest[index];
                      return _SmallCandidateCard(
                        candidate: c,
                        color: _colorForId(c.id),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  const _MainCard({
    required this.candidate,
    required this.avatarColor,
    required this.onSkip,
    required this.onLike,
  });

  final MatchCandidate candidate;
  final Color avatarColor;
  final VoidCallback onSkip;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top half: avatar + match badge
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: avatarColor.withAlpha(30),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: avatarColor,
                      child: Text(
                        candidate.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Match score badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '匹配 ${candidate.matchScore}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom half: info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      candidate.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (candidate.age != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${candidate.age}岁',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    candidate.bio!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (candidate.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: candidate.tags
                        .take(5)
                        .map((tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: AppColors.primaryLight,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: onSkip,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            '跳过',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onLike,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            '心动',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCandidateCard extends StatelessWidget {
  const _SmallCandidateCard({
    required this.candidate,
    required this.color,
  });

  final MatchCandidate candidate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Text(
              candidate.username.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              candidate.username,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
