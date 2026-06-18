// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final typeId = 2;

  @override
  ExpenseCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExpenseCategory.food;
      case 1:
        return ExpenseCategory.transport;
      case 2:
        return ExpenseCategory.bills;
      case 3:
        return ExpenseCategory.entertainment;
      case 4:
        return ExpenseCategory.health;
      case 5:
        return ExpenseCategory.others;
      default:
        return ExpenseCategory.food;
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    switch (obj) {
      case ExpenseCategory.food:
        writer.writeByte(0);
      case ExpenseCategory.transport:
        writer.writeByte(1);
      case ExpenseCategory.bills:
        writer.writeByte(2);
      case ExpenseCategory.entertainment:
        writer.writeByte(3);
      case ExpenseCategory.health:
        writer.writeByte(4);
      case ExpenseCategory.others:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
