import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 套餐特性数据模型
class PlanFeature {
  final String feature;
  final bool support;

  const PlanFeature({
    required this.feature,
    required this.support,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      feature: json['feature'] as String,
      support: json['support'] as bool,
    );
  }
}

class PlanDescriptionWidget extends StatelessWidget {
  final String content;
  const PlanDescriptionWidget({
    super.key,
    required this.content,
  });

  /// 尝试解析 JSON 格式的特性列表
  List<PlanFeature>? _parseFeatures() {
    try {
      final trimmed = content.trim();
      if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
        return null; // 不是 JSON 数组格式
      }
      
      final decoded = json.decode(trimmed) as List;
      return decoded
          .map((item) => PlanFeature.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null; // 解析失败，回退到 Markdown
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final features = _parseFeatures();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: features != null
          ? _buildFeatureList(features, colorScheme)
          : _buildMarkdown(colorScheme),
    );
  }

  /// 构建特性列表视图（JSON 格式）
  Widget _buildFeatureList(List<PlanFeature> features, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        final isLast = index == features.length - 1;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标
              Icon(
                feature.support ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: feature.support
                    ? Colors.green.shade600
                    : Colors.red.shade400,
              ),
              const SizedBox(width: 12),
              // 特性文本
              Expanded(
                child: Text(
                  feature.feature,
                  style: TextStyle(
                    color: feature.support
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建 Markdown 视图（传统文本格式）
  Widget _buildMarkdown(ColorScheme colorScheme) {
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.5,
        ),
        textAlign: WrapAlignment.center,
      ),
    );
  }
}