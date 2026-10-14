import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../models/expert_workshop.dart';

class WorkshopCard extends StatelessWidget {
  final ExpertWorkshop workshop;
  final VoidCallback onTap;
  const WorkshopCard({super.key, required this.workshop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C5CFC);
    return Card(
      color: context.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: .18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.category.toUpperCase(),
                      style: const TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workshop.title,
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: context.textSecColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${workshop.startTime} – ${workshop.endTime}',
                          style: TextStyle(
                            color: context.textSecColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: context.textSecColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            workshop.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textSecColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textSecColor),
            ],
          ),
        ),
      ),
    );
  }
}
