// Progress data model for verb learning state.

// Copyright (C) 2024 Dmitry Dronov
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

class ProgressModel {
  const ProgressModel({
    required this.verbId,
    required this.status,
    required this.repetitions,
    required this.lastReviewed,
    this.markedForRepeat = false,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      verbId: json['verb_id'] as int,
      status: json['status'] as String,
      repetitions: json['repetitions'] as int? ?? 0,
      lastReviewed: json['last_reviewed'] as String,
      markedForRepeat: json['marked_for_repeat'] == 1,
    );
  }

  final int verbId;
  final String status;
  final int repetitions;
  final String lastReviewed;
  final bool markedForRepeat;

  Map<String, dynamic> toJson() {
    return {
      'verb_id': verbId,
      'status': status,
      'repetitions': repetitions,
      'last_reviewed': lastReviewed,
      'marked_for_repeat': markedForRepeat ? 1 : 0,
    };
  }
}
