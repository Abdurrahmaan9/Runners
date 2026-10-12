import 'package:equatable/equatable.dart';

class HeatCell extends Equatable {
  const new({required this.row, required this.col, required this.count});

  factory fromJson(Map<String, dynamic> json) {
    return HeatCell(
      row: _count(json['row']),
      col: _count(json['col']),
      count: _count(json['count']),
    );
  }

  final int row;
  final int col;
  final int count;

  @override
  List<Object> get props => [row, col, count];
}

class ErrandHeatmap extends Equatable {
  const new({required this.rows, required this.cols, required this.cells});

  factory fromJson(Map<String, dynamic> json) {
    final raw = json['cells'];
    return ErrandHeatmap(
      rows: _count(json['rows']),
      cols: _count(json['cols']),
      cells: [
        for (final item in raw is List ? raw : const <Object?>[])
          if (item is Map) HeatCell.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  final int rows;
  final int cols;
  final List<HeatCell> cells;

  @override
  List<Object> get props => [rows, cols, cells];
}

int _count(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
