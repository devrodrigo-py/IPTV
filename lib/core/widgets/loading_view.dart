import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

/// Static skeletons avoid perpetual shader/animation work on low-end TVs.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Carregando conteúdo',
      child: ExcludeFocus(child: LayoutBuilder(builder: (context, constraints) {
        return Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  height: 16, width: 180, color: AppColors.surfaceElevated),
              const SizedBox(height: 20),
              Expanded(
                  child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 8,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: .68,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 18),
                      itemBuilder: (_, index) => DecoratedBox(
                          decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8))))),
            ]));
      })));
}
