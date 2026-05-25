import 'package:hive/hive.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../../services/auth/auth_state.dart';

/// Hive Type Adapters for data models
/// 
/// Type IDs:
/// - UserModel: 0
/// - ServiceModel: 1
/// - BookingModel: 2
/// - UserRole: 3
/// - ServiceStatus: 4
/// - BookingStatus: 5

// ══════════════════════════════════════════════════════════════════════════════
// UserModel Adapter (Type ID: 0)
// ══════════════════════════════════════════════════════════════════════════════

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    return UserModel(
      id: reader.readString(),
      firebaseUid: reader.readString(),
      email: reader.readString(),
      name: reader.readString(),
      role: UserRole.values[reader.readInt()],
      phoneNumber: reader.readString(),
      profileImageUrl: reader.readString(),
      isActive: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastLoginAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.firebaseUid);
    writer.writeString(obj.email);
    writer.writeString(obj.name);
    writer.writeInt(obj.role.index);
    writer.writeString(obj.phoneNumber ?? '');
    writer.writeString(obj.profileImageUrl ?? '');
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.lastLoginAt != null);
    if (obj.lastLoginAt != null) {
      writer.writeInt(obj.lastLoginAt!.millisecondsSinceEpoch);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ServiceModel Adapter (Type ID: 1)
// ══════════════════════════════════════════════════════════════════════════════

class ServiceModelAdapter extends TypeAdapter<ServiceModel> {
  @override
  final int typeId = 1;

  @override
  ServiceModel read(BinaryReader reader) {
    return ServiceModel(
      id: reader.readString(),
      providerId: reader.readString(),
      name: reader.readString(),
      description: reader.readString(),
      category: reader.readString(),
      price: reader.readDouble(),
      currency: reader.readString(),
      durationMinutes: reader.readInt(),
      status: ServiceStatus.values[reader.readInt()],
      imageUrls: (reader.readList()).cast<String>(),
      tags: (reader.readList()).cast<String>(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ServiceModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.providerId);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.category);
    writer.writeDouble(obj.price);
    writer.writeString(obj.currency);
    writer.writeInt(obj.durationMinutes);
    writer.writeInt(obj.status.index);
    writer.writeList(obj.imageUrls);
    writer.writeList(obj.tags);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BookingModel Adapter (Type ID: 2)
// ══════════════════════════════════════════════════════════════════════════════

class BookingModelAdapter extends TypeAdapter<BookingModel> {
  @override
  final int typeId = 2;

  @override
  BookingModel read(BinaryReader reader) {
    return BookingModel(
      id: reader.readString(),
      customerId: reader.readString(),
      serviceId: reader.readString(),
      providerId: reader.readString(),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      status: BookingStatus.values[reader.readInt()],
      totalPrice: reader.readDouble(),
      currency: reader.readString(),
      cancellationReason: reader.readBool() ? reader.readString() : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, BookingModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.customerId);
    writer.writeString(obj.serviceId);
    writer.writeString(obj.providerId);
    writer.writeInt(obj.scheduledAt.millisecondsSinceEpoch);
    writer.writeInt(obj.status.index);
    writer.writeDouble(obj.totalPrice);
    writer.writeString(obj.currency);
    writer.writeBool(obj.cancellationReason != null);
    if (obj.cancellationReason != null) {
      writer.writeString(obj.cancellationReason!);
    }
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Register all adapters
// ══════════════════════════════════════════════════════════════════════════════

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ServiceModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(BookingModelAdapter());
  }
}
