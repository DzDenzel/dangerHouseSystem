abstract class BaseModel<T> {
  const BaseModel();

  Map<String, dynamic> toJson();

  T copyWith();

  @override
  String toString();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

mixin Copyable<T> {
  T copyWith();
}

mixin JsonSerializable {
  Map<String, dynamic> toJson();
}

mixin Validatable {
  bool validate();
  String? validationError();
}

abstract class Dto<T> implements BaseModel<T> {
  const Dto();

  factory Dto.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by subclass');
  }
}

abstract class Entity<T> implements BaseModel<T> {
  const Entity();
}
