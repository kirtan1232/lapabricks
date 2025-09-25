class BrickRecord {
  final String labourId;
  final String date; // yyyy-MM-dd
  final int brickCount; // total bricks for that day

  BrickRecord({
    required this.labourId,
    required this.date,
    required this.brickCount,
  });

  Map<String, dynamic> toMap() => {
    'labourId': labourId,
    'date': date,
    'brickCount': brickCount,
  };

  static BrickRecord fromMap(Map<String, dynamic> map) => BrickRecord(
    labourId: map['labourId'],
    date: map['date'],
    brickCount: map['brickCount'],
  );
}