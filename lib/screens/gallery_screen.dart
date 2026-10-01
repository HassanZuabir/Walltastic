import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ads_controller.dart';
import '../controllers/gallery_controller.dart';
import '../data/wallpaper_categories.dart';
import '../models/wallpaper.dart';
import '../widgets/ad_banner.dart';
import '../widgets/gallery_widgets.dart';
import '../widgets/wallpaper_image.dart';
import 'wallpaper_detail_screen.dart';
import 'settings_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final controller = Get.find<GalleryController>();
  final searchController = TextEditingController();
  late final Worker queryWorker;

  @override
  void initState() {
    super.initState();
    queryWorker = ever(controller.query, (value) {
      if (searchController.text != value) searchController.text = value;
    });
  }

  @override
  void dispose() {
    queryWorker.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _Header(
                onSettings: () {
                  FocusScope.of(context).unfocus();
                  Get.to<void>(() => const SettingsScreen());
                },
              ),
              Obx(() {
                if (controller.storageError.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    controller.storageError.value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }),
              Expanded(
                child: Obx(() {
                  final tab = controller.selectedTab.value;
                  return RefreshIndicator(
                    onRefresh: tab == 0 ? controller.load : () async {},
                    color: Theme.of(context).colorScheme.primary,
                    child: CustomScrollView(
                      key: PageStorageKey('gallery-$tab'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          sliver: SliverToBoxAdapter(
                            child: tab == 0
                                ? _discoveryHeader(context)
                                : _sectionHeader(context, tab),
                          ),
                        ),
                        if (tab == 1)
                          const _CategoryGrid()
                        else
                          _PhotoGrid(saved: tab == 2),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Center(
                              child: TextButton(
                                onPressed: () => openExternalLink(
                                  context,
                                  'https://www.pexels.com',
                                ),
                                child: Text(
                                  'Photography by the Pexels community ↗',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.outlineVariant
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: controller.selectedTab.value,
              onDestinationSelected: (index) {
                FocusScope.of(context).unfocus();
                controller.selectedTab.value = index;
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              height: 76,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: Icon(
                    Icons.explore,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(
                    Icons.grid_view_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Categories',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(
                    Icons.favorite_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: 'Saved',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _discoveryHeader(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('A FRESH PERSPECTIVE'),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Your screen.\n'),
            TextSpan(
              text: 'A little more you.',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      Text(
        'Find a view you never get tired of.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 26),
      TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
          controller.search(value);
        },
        decoration: InputDecoration(
          hintText: 'Search mountains, oceans, moods...',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          suffixIcon: IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.close_rounded, size: 19),
            onPressed: () {
              searchController.clear();
              controller.search('');
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ),
      if (controller.query.value.isEmpty && controller.photos.isNotEmpty) ...[
        const SizedBox(height: 24),
        _FeaturedWallpaper(photo: controller.photos.first),
      ],
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              controller.query.value.isEmpty
                  ? 'Handpicked for you'
                  : 'Your next view',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (controller.query.value.isEmpty)
            const _Eyebrow('EXPLORE')
          else
            TextButton(
              onPressed: () => controller.search(''),
              child: const Text('Reset'),
            ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 28 + MediaQuery.textScalerOf(context).scale(16),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: wallpaperCategories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final name = index == 0
                ? 'All'
                : wallpaperCategories[index - 1].name;
            final selected = controller.selectedCategory.value == name;
            return ChoiceChip(
              label: Text(name),
              selected: selected,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
              onSelected: (_) => controller.selectCategory(name),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
    ],
  );

  Widget _sectionHeader(BuildContext context, int tab) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Eyebrow(tab == 1 ? 'FIND YOUR MOOD' : 'YOUR PERSONAL COLLECTION'),
      const SizedBox(height: 12),
      Text(
        tab == 1 ? 'A world of possibility.' : 'Worth coming back to.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      Text(
        tab == 1
            ? 'Little escapes, organized for you.'
            : '${controller.favorites.length} saved wallpapers. All your favorites, in one place.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 28),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset(
            'assets/logo/app_logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'walltastic',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
            ),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: onSettings,
        ),
      ],
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class _FeaturedWallpaper extends StatelessWidget {
  const _FeaturedWallpaper({required this.photo});

  final Wallpaper photo;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(25),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 238),
      child: Stack(
        children: [
          Positioned.fill(child: WallpaperImage(url: photo.imageUrl)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0x15151022), Color(0xE8151022)],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.find<AdsController>().onWallpaperOpened();
                Get.to<void>(() => WallpaperDetailScreen(photo: photo));
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'FEATURED WALLPAPER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      photo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.12,
                        letterSpacing: -0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            photo.photographer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 21,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CategoryGrid extends GetView<GalleryController> {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.crossAxisExtent > 700 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 225,
        ),
        itemCount: wallpaperCategories.length,
        itemBuilder: (context, index) {
          final category = wallpaperCategories[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(category.color), const Color(0xFF1C1B25)],
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  right: 18,
                  child: Icon(
                    category.icon,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.selectCategory(category.name),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _PhotoGrid extends GetView<GalleryController> {
  const _PhotoGrid({required this.saved});
  final bool saved;

  @override
  Widget build(BuildContext context) => Obx(() {
    final photos = saved
        ? controller.favorites.toList()
        : controller.photos.toList();
    if (!saved && controller.isLoading.value) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(64),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (!saved && controller.error.value.isNotEmpty && photos.isEmpty) {
      return SliverToBoxAdapter(
        child: GalleryMessage(
          icon: Icons.cloud_off_rounded,
          title: 'A little interruption',
          message: controller.error.value,
          action: 'Try again',
          onAction: controller.load,
        ),
      );
    }
    if (photos.isEmpty) {
      return SliverToBoxAdapter(
        child: GalleryMessage(
          icon: saved
              ? Icons.favorite_border_rounded
              : Icons.search_off_rounded,
          title: saved ? 'Keep what inspires you.' : 'No views found.',
          message: saved
              ? 'Tap the heart on any wallpaper to start your collection.'
              : 'Try a different word or explore a category.',
          action: saved ? 'Find your first favorite' : 'Explore all',
          onAction: () => controller.search(''),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent > 900
                  ? 4
                  : constraints.crossAxisExtent > 600
                  ? 3
                  : 2;
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.64,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) =>
                    WallpaperCard(photo: photos[index]),
              );
            },
          ),
        ),
        if (!saved && controller.hasMore.value)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  if (controller.error.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        controller.error.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: controller.isLoadingMore.value
                        ? null
                        : controller.loadMore,
                    icon: controller.isLoadingMore.value
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      controller.isLoadingMore.value
                          ? 'Finding more views...'
                          : controller.error.value.isNotEmpty
                          ? 'Try again'
                          : 'Discover more',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  });
}
